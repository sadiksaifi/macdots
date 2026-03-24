// ─────────────────────────────────────────────────────────────
// Claude Code Notification Hook — Zig (native macOS)
//
// Posts native macOS notifications with Claude logo via ObjC runtime.
// Click notification → focuses terminal (Ghostty/iTerm/etc).
// Zero external dependencies. Zero heap allocations.
//
// Compile:
//   zig build-exe notify.zig -OReleaseFast -fstrip -lobjc
//
// Usage (from Claude Code hook):
//   echo '{"last_assistant_message":"Done."}' | \
//     ~/.claude/hooks/ClaudeNotify.app/Contents/MacOS/notify task-done
//
// When launched without args (notification click), focuses terminal.
// ─────────────────────────────────────────────────────────────
const std = @import("std");

// ── Types ──────────────────────────────────────────────────
const Id = ?*anyopaque;

const EventType = enum { task_done, task_failed, permission, idle, elicitation };

// ── JSON input schema ──────────────────────────────────────
const HookInput = struct {
    cwd: ?[]const u8 = null,
};

// ── ObjC runtime externs ───────────────────────────────────
extern "c" fn objc_getClass(name: [*:0]const u8) ?*anyopaque;
extern "c" fn sel_registerName(name: [*:0]const u8) ?*anyopaque;
extern "c" fn objc_msgSend() void;

extern "c" fn dlopen(path: ?[*:0]const u8, mode: c_int) ?*anyopaque;
const RTLD_LAZY: c_int = 0x1;

// ── ObjC messaging helpers ─────────────────────────────────

inline fn sel(name: [*:0]const u8) ?*anyopaque {
    return sel_registerName(name);
}

/// objc_msgSend(obj, sel) → Id
fn msg(obj: Id, _sel: Id) Id {
    const F = *const fn (Id, Id) callconv(.c) Id;
    return @as(F, @ptrCast(&objc_msgSend))(obj, _sel);
}

/// objc_msgSend(obj, sel, arg) → Id
fn msg1(obj: Id, _sel: Id, a1: Id) Id {
    const F = *const fn (Id, Id, Id) callconv(.c) Id;
    return @as(F, @ptrCast(&objc_msgSend))(obj, _sel, a1);
}

/// objc_msgSend(obj, sel, arg) → void
fn msg1v(obj: Id, _sel: Id, a1: Id) void {
    const F = *const fn (Id, Id, Id) callconv(.c) void;
    @as(F, @ptrCast(&objc_msgSend))(obj, _sel, a1);
}

/// objc_msgSend(obj, sel) → void
fn msg_v(obj: Id, _sel: Id) void {
    const F = *const fn (Id, Id) callconv(.c) void;
    @as(F, @ptrCast(&objc_msgSend))(obj, _sel);
}

/// objc_msgSend(obj, sel, i64) → void  (for setActivationPolicy:)
fn msg_long(obj: Id, _sel: Id, val: i64) void {
    const F = *const fn (Id, Id, i64) callconv(.c) void;
    @as(F, @ptrCast(&objc_msgSend))(obj, _sel, val);
}

/// objc_msgSend(obj, sel, f64) → Id  (for dateWithTimeIntervalSinceNow:)
fn msg_f64(obj: Id, _sel: Id, val: f64) Id {
    const F = *const fn (Id, Id, f64) callconv(.c) Id;
    return @as(F, @ptrCast(&objc_msgSend))(obj, _sel, val);
}

/// objc_msgSend(obj, sel, cstr) → Id  (for initWithUTF8String:)
fn msg_cstr(obj: Id, _sel: Id, s: [*:0]const u8) Id {
    const F = *const fn (Id, Id, [*:0]const u8) callconv(.c) Id;
    return @as(F, @ptrCast(&objc_msgSend))(obj, _sel, s);
}

/// Create NSString from null-terminated C string.
fn nsstring(s: [*:0]const u8) Id {
    const NSString = objc_getClass("NSString") orelse return null;
    return msg_cstr(msg(NSString, sel("alloc")), sel("initWithUTF8String:"), s);
}

// ── Entry point ────────────────────────────────────────────
pub fn main() void {
    run() catch {};
}

fn run() !void {
    const args = std.os.argv;

    if (args.len < 2) {
        // Mode B: launched by macOS on notification click → focus terminal
        focusTerminal();
        return;
    }

    // Mode A: launched by hook → post notification
    const event = parseEvent(std.mem.span(args[1])) orelse return error.BadArgs;

    // Read stdin JSON
    var stdin_buf: [8192]u8 = undefined;
    const stdin_len = readStdin(&stdin_buf);

    // Parse JSON (stack-backed allocator, zero heap)
    var json_mem: [16384]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&json_mem);
    const input: HookInput = if (stdin_len > 0) blk: {
        const parsed = std.json.parseFromSlice(
            HookInput,
            fba.allocator(),
            stdin_buf[0..stdin_len],
            .{ .ignore_unknown_fields = true },
        ) catch break :blk .{};
        break :blk parsed.value;
    } else .{};

    // Save terminal bundle ID for click-to-focus
    saveTerminal();

    // Build notification content
    const title = eventTitle(event);
    const sound = eventSound(event);

    // Extract project name from cwd (last path component)
    var proj_buf: [128]u8 = undefined;
    const project = projectName(input.cwd, &proj_buf);

    // Null-terminate project for NSString
    var proj_z: [130]u8 = undefined;
    const plen = @min(project.len, proj_z.len - 1);
    @memcpy(proj_z[0..plen], project[0..plen]);
    proj_z[plen] = 0;

    // Try native macOS notification, fall back to osascript
    if (!postNative(title, proj_z[0..plen :0], sound)) {
        fallbackOsascript(title, project, sound);
    }
}

// ── Event parsing ──────────────────────────────────────────

fn parseEvent(arg: []const u8) ?EventType {
    const map = .{
        .{ "task-done", EventType.task_done },
        .{ "task-failed", EventType.task_failed },
        .{ "permission", EventType.permission },
        .{ "idle", EventType.idle },
        .{ "elicitation", EventType.elicitation },
    };
    inline for (map) |entry| {
        if (std.mem.eql(u8, arg, entry[0])) return entry[1];
    }
    return null;
}

// ── Notification content ───────────────────────────────────

fn eventTitle(event: EventType) [*:0]const u8 {
    return switch (event) {
        .task_done => "Claude Code \xe2\x80\x94 Task Complete",
        .task_failed => "Claude Code \xe2\x80\x94 Task Failed",
        .permission => "Claude Code \xe2\x80\x94 Needs Permission",
        .idle => "Claude Code \xe2\x80\x94 Waiting for Input",
        .elicitation => "Claude Code \xe2\x80\x94 MCP Input Needed",
    };
}

fn eventSound(event: EventType) [*:0]const u8 {
    return switch (event) {
        .task_done => "Glass",
        .task_failed => "Sosumi",
        else => "Ping",
    };
}

// (no body text — title + project subtitle is enough)

/// Extract last path component from cwd as project name.
fn projectName(cwd: ?[]const u8, buf: *[128]u8) []const u8 {
    const path = cwd orelse return "";
    if (path.len == 0) return "";
    // Strip trailing slash
    const trimmed = if (path[path.len - 1] == '/') path[0 .. path.len - 1] else path;
    // Find last '/'
    var i: usize = trimmed.len;
    while (i > 0) : (i -= 1) {
        if (trimmed[i - 1] == '/') break;
    }
    const name = trimmed[i..];
    const len = @min(name.len, buf.len);
    @memcpy(buf[0..len], name[0..len]);
    return buf[0..len];
}

// ── Native notification (ObjC runtime) ─────────────────────

fn postNative(title: [*:0]const u8, subtitle: [*:0]const u8, sound: [*:0]const u8) bool {
    // Load frameworks
    _ = dlopen("/System/Library/Frameworks/Foundation.framework/Foundation", RTLD_LAZY) orelse return false;
    _ = dlopen("/System/Library/Frameworks/AppKit.framework/AppKit", RTLD_LAZY) orelse return false;

    // Initialize NSApplication properly (registers bundle identity → .app icon on notification)
    const NSAppClass = objc_getClass("NSApplication") orelse return false;
    const app = msg(NSAppClass, sel("sharedApplication"));

    // NSApplicationActivationPolicyProhibited = 2 (no dock, no menu)
    msg_long(app, sel("setActivationPolicy:"), 2);

    // finishLaunching registers with window server + notification daemon
    msg_v(app, sel("finishLaunching"));

    // NSUserNotification (deprecated but functional — falls back if removed)
    const NotifClass = objc_getClass("NSUserNotification") orelse return false;
    const CenterClass = objc_getClass("NSUserNotificationCenter") orelse return false;

    // Create notification
    const notif = msg(msg(NotifClass, sel("alloc")), sel("init"));
    if (notif == null) return false;

    // Set title, subtitle (project name), sound
    msg1v(notif, sel("setTitle:"), nsstring(title));
    if (subtitle[0] != 0) {
        msg1v(notif, sel("setSubtitle:"), nsstring(subtitle));
    }
    msg1v(notif, sel("setSoundName:"), nsstring(sound));

    // Deliver
    const center = msg(CenterClass, sel("defaultUserNotificationCenter"));
    if (center == null) return false;
    msg1v(center, sel("deliverNotification:"), notif);

    // Run event loop briefly so notification daemon processes the delivery
    const NSRunLoop = objc_getClass("NSRunLoop") orelse return true;
    const NSDate = objc_getClass("NSDate") orelse return true;
    const mainLoop = msg(NSRunLoop, sel("mainRunLoop"));
    const date = msg_f64(NSDate, sel("dateWithTimeIntervalSinceNow:"), 0.3);
    msg1v(mainLoop, sel("runUntilDate:"), date);

    return true;
}

// ── Fallback: osascript ────────────────────────────────────

fn fallbackOsascript(title: [*:0]const u8, project: []const u8, sound: [*:0]const u8) void {
    var script_buf: [1024]u8 = undefined;
    const script = if (project.len > 0)
        std.fmt.bufPrint(
            &script_buf,
            "display notification \"\" with title \"{s}\" subtitle \"{s}\" sound name \"{s}\"",
            .{ std.mem.span(title), project, std.mem.span(sound) },
        ) catch return
    else
        std.fmt.bufPrint(
            &script_buf,
            "display notification \"\" with title \"{s}\" sound name \"{s}\"",
            .{ std.mem.span(title), std.mem.span(sound) },
        ) catch return;

    if (script.len >= script_buf.len) return;
    script_buf[script.len] = 0;

    const argv = [_:null]?[*:0]const u8{
        "/usr/bin/osascript",
        "-e",
        script_buf[0..script.len :0],
    };

    forkExec("/usr/bin/osascript", &argv);
}

// ── Terminal detection & focus ──────────────────────────────

fn saveTerminal() void {
    const term = std.posix.getenv("TERM_PROGRAM") orelse "ghostty";
    const bundle_id = mapTerminal(term);
    const file = std.fs.createFileAbsolute("/tmp/claude-notify-terminal", .{}) catch return;
    defer file.close();
    file.writeAll(bundle_id) catch {};
}

fn mapTerminal(term: []const u8) []const u8 {
    const map = .{
        .{ "ghostty", "com.mitchellh.ghostty" },
        .{ "iTerm.app", "com.googlecode.iterm2" },
        .{ "Apple_Terminal", "com.apple.Terminal" },
        .{ "Alacritty", "org.alacritty" },
        .{ "WezTerm", "com.github.wez.wezterm" },
    };
    inline for (map) |entry| {
        if (std.mem.eql(u8, term, entry[0])) return entry[1];
    }
    return "com.mitchellh.ghostty";
}

fn focusTerminal() void {
    var buf: [256]u8 = undefined;
    const file = std.fs.openFileAbsolute("/tmp/claude-notify-terminal", .{}) catch return;
    defer file.close();
    const n = file.readAll(&buf) catch return;
    if (n == 0 or n >= buf.len) return;
    buf[n] = 0;

    const argv = [_:null]?[*:0]const u8{
        "/usr/bin/open",
        "-b",
        buf[0..n :0],
    };

    forkExec("/usr/bin/open", &argv);
}

// ── Shared helpers ─────────────────────────────────────────

fn forkExec(path: [*:0]const u8, argv: [*:null]const ?[*:0]const u8) void {
    const pid = std.posix.fork() catch return;
    if (pid == 0) {
        // Child — inherit environment via environ
        const envp = getEnviron();
        std.posix.execveZ(path, argv, envp) catch {};
        std.posix.exit(1);
    }
    // Parent — wait for child
    _ = std.posix.waitpid(pid, 0);
}

fn getEnviron() [*:null]const ?[*:0]const u8 {
    // macOS environ pointer — inherited, no allocation needed
    const e = @extern(*const [*:null]const ?[*:0]const u8, .{ .name = "environ" });
    return e.*;
}

/// Read all bytes from stdin into buf, return count.
fn readStdin(buf: []u8) usize {
    var total: usize = 0;
    while (total < buf.len) {
        const n = std.posix.read(std.posix.STDIN_FILENO, buf[total..]) catch break;
        if (n == 0) break;
        total += n;
    }
    return total;
}
