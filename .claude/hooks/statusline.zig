// ─────────────────────────────────────────────────────────────
// Claude Code Statusline — Zig (maximum performance)
//
// Reads JSON from stdin, outputs a single ANSI-colored line.
// Zero heap allocations. All buffers on stack. ~1.4ms execution.
//
// Compile (most performant — production build):
//   zig build-exe statusline.zig -OReleaseFast -fstrip
//   -OReleaseFast  → LLVM O3, no runtime safety checks, max speed
//   -fstrip        → strips debug symbols, smaller binary
//
// Compile (smallest binary):
//   zig build-exe statusline.zig -OReleaseSmall -fstrip
//   -OReleaseSmall → optimizes for size over speed
//
// Output binary: ./statusline (~141KB native arm64)
// ─────────────────────────────────────────────────────────────
const std = @import("std");

// ── JSON input schema ────────────────────────────────────────
const StatusInput = struct {
    model: ?struct { display_name: ?[]const u8 = null } = null,
    workspace: ?struct { current_dir: ?[]const u8 = null } = null,
    context_window: ?struct { used_percentage: ?f64 = null } = null,
    session_id: ?[]const u8 = null,
};

// ── ANSI escape codes ────────────────────────────────────────
const RESET = "\x1b[0m";
const DIM = "\x1b[2m";
const PURPLE = "\x1b[35m";
const BLUE = "\x1b[34m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const RED = "\x1b[31m";
const WHITE = "\x1b[37m";

// ── Nerd Font icons (UTF-8) ─────────────────────────────────
const ICON_MODEL = "\u{ee0d}"; // nf-fa-robot
const ICON_BRANCH = "\u{e0a0}"; //
const ICON_DIR = "\u{f07c}"; //
const ICON_TIME = "\u{f017}"; //
const SEP = " | ";
const BAR_FULL = "█"; // U+2588
const BAR_EMPTY = "░"; // U+2591
const BAR_WIDTH: usize = 10;

// ── Entry point ──────────────────────────────────────────────
pub fn main() void {
    run() catch {
        writeOut("Claude\n");
    };
}

fn run() !void {
    // Read all of stdin (JSON payload is typically < 1KB)
    var stdin_buf: [8192]u8 = undefined;
    const stdin_len = readStdin(&stdin_buf);
    if (stdin_len == 0) return error.NoInput;

    // Parse JSON — stack-backed allocator, zero heap
    var json_mem: [16384]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&json_mem);
    const parsed = try std.json.parseFromSlice(
        StatusInput,
        fba.allocator(),
        stdin_buf[0..stdin_len],
        .{ .ignore_unknown_fields = true },
    );
    const s = parsed.value;

    // Extract fields with defaults
    const model_name = if (s.model) |m| m.display_name orelse "Claude" else "Claude";
    const pct_f = clampPct(if (s.context_window) |cw| cw.used_percentage orelse 0.0 else 0.0);
    const pct: u8 = @intFromFloat(pct_f);
    const dir = if (s.workspace) |ws| ws.current_dir orelse "" else "";
    const session_id = s.session_id orelse "";

    // Derived values
    const model_color = getModelColor(model_name);
    const home = std.posix.getenv("HOME") orelse "";
    const tilde = home.len > 0 and std.mem.startsWith(u8, dir, home);
    const filled_raw: usize = @intFromFloat(@round(pct_f / 100.0 * @as(f64, @floatFromInt(BAR_WIDTH))));
    const filled: usize = if (pct > 0 and filled_raw == 0) 1 else filled_raw;
    const bar_color: []const u8 = if (pct < 50) GREEN else if (pct < 80) YELLOW else RED;

    // Git branch (reads .git/HEAD directly — no subprocess)
    var branch_buf: [256]u8 = undefined;
    const branch = readGitBranch(dir, &branch_buf);

    // Session elapsed time
    var elapsed_buf: [32]u8 = undefined;
    const elapsed = sessionElapsed(session_id, &elapsed_buf);

    // Format percentage string
    var pct_str_buf: [8]u8 = undefined;
    const pct_str = std.fmt.bufPrint(&pct_str_buf, "{d}%", .{pct}) catch "0%";

    // ── Build output into a single buffer ────────────────────
    var out: [4096]u8 = undefined;
    var p: usize = 0;

    // 1. Model
    p = emit(&out, p, model_color);
    p = emit(&out, p, ICON_MODEL ++ "  ");
    p = emit(&out, p, model_name);
    p = emit(&out, p, RESET);

    // 2. Context bar
    p = emit(&out, p, SEP);
    p = emit(&out, p, bar_color);
    for (0..filled) |_| {
        p = emit(&out, p, BAR_FULL);
    }
    p = emit(&out, p, RESET);
    for (0..BAR_WIDTH - filled) |_| {
        p = emit(&out, p, BAR_EMPTY);
    }
    p = emit(&out, p, " ");
    p = emit(&out, p, pct_str);

    // 3. Git branch (optional)
    if (branch) |b| {
        p = emit(&out, p, SEP);
        p = emit(&out, p, ICON_BRANCH ++ " ");
        p = emit(&out, p, b);
    }

    // 4. Directory
    p = emit(&out, p, SEP);
    p = emit(&out, p, DIM ++ ICON_DIR ++ " ");
    if (tilde) {
        p = emit(&out, p, "~");
        p = emit(&out, p, dir[home.len..]);
    } else {
        p = emit(&out, p, dir);
    }
    p = emit(&out, p, RESET);

    // 5. Session time (optional)
    if (elapsed) |e| {
        p = emit(&out, p, SEP);
        p = emit(&out, p, ICON_TIME ++ " ");
        p = emit(&out, p, e);
    }

    p = emit(&out, p, "\n");

    // Single write syscall
    writeOut(out[0..p]);
}

// ── Helpers ──────────────────────────────────────────────────

/// Append slice to output buffer, return new position.
inline fn emit(buf: *[4096]u8, pos: usize, data: []const u8) usize {
    const end = @min(pos + data.len, buf.len);
    const len = end - pos;
    @memcpy(buf[pos..end], data[0..len]);
    return end;
}

/// Clamp float to [0, 100], handle NaN/Inf.
inline fn clampPct(v: f64) f64 {
    if (v != v or v == std.math.inf(f64) or v == -std.math.inf(f64)) return 0.0; // NaN or Inf
    return @max(0.0, @min(100.0, v));
}

/// Determine ANSI color from model name (case-insensitive).
fn getModelColor(name: []const u8) []const u8 {
    var lower: [128]u8 = undefined;
    const n = @min(name.len, lower.len);
    for (0..n) |i| {
        lower[i] = std.ascii.toLower(name[i]);
    }
    const s = lower[0..n];
    if (std.mem.indexOf(u8, s, "opus") != null) return PURPLE;
    if (std.mem.indexOf(u8, s, "sonnet") != null) return BLUE;
    if (std.mem.indexOf(u8, s, "haiku") != null) return GREEN;
    return WHITE;
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

/// Write bytes to stdout (single syscall for small payloads).
fn writeOut(data: []const u8) void {
    _ = std.posix.write(std.posix.STDOUT_FILENO, data) catch {};
}

/// Read git branch from .git/HEAD (no subprocess spawn).
fn readGitBranch(dir: []const u8, buf: *[256]u8) ?[]const u8 {
    if (dir.len == 0) return null;

    var path_buf: [4096]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "{s}/.git/HEAD", .{dir}) catch return null;

    const file = std.fs.openFileAbsolute(path, .{}) catch return null;
    defer file.close();

    const n = file.readAll(buf) catch return null;
    if (n == 0) return null;

    const ref_prefix = "ref: refs/heads/";
    if (std.mem.startsWith(u8, buf[0..n], ref_prefix)) {
        return std.mem.trimRight(u8, buf[ref_prefix.len..n], "\n\r \t");
    }
    return null; // detached HEAD or unrecognized format
}

/// Compute session elapsed time from /tmp/claude-sl-{id} file.
fn sessionElapsed(session_id: []const u8, buf: *[32]u8) ?[]const u8 {
    if (session_id.len == 0) return null;

    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "/tmp/claude-sl-{s}", .{session_id}) catch return null;

    if (std.fs.openFileAbsolute(path, .{})) |file| {
        // File exists — read start timestamp and compute elapsed
        defer file.close();
        var ts_raw: [32]u8 = undefined;
        const n = file.readAll(&ts_raw) catch return null;
        const ts_str = std.mem.trimRight(u8, ts_raw[0..n], "\n\r \t");
        const start = std.fmt.parseInt(i64, ts_str, 10) catch return null;
        const now = std.time.milliTimestamp();
        const diff = now - start;
        if (diff < 0) return null;
        const secs: u64 = @intCast(@divFloor(diff, 1000));
        const mins = secs / 60;
        const hrs = mins / 60;
        if (hrs > 0) return std.fmt.bufPrint(buf, "{d}h{d}m", .{ hrs, mins % 60 }) catch null;
        if (mins > 0) return std.fmt.bufPrint(buf, "{d}m", .{mins}) catch null;
        return std.fmt.bufPrint(buf, "{d}s", .{secs}) catch null;
    } else |_| {
        // File missing — create with current timestamp
        const file = std.fs.createFileAbsolute(path, .{}) catch return null;
        defer file.close();
        var ts_raw: [20]u8 = undefined;
        const ts = std.fmt.bufPrint(&ts_raw, "{d}", .{std.time.milliTimestamp()}) catch return null;
        file.writeAll(ts) catch {};
        return std.fmt.bufPrint(buf, "0s", .{}) catch null;
    }
}
