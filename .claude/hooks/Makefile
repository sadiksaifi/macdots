.PHONY: all clean statusline notify

all: statusline notify

# ── Statusline ──────────────────────────────────────────────
statusline: statusline.zig
	zig build-exe statusline.zig -OReleaseFast -fstrip

# ── Notify ──────────────────────────────────────────────────
notify: ClaudeNotify.app/Contents/MacOS/notify

ClaudeNotify.app/Contents/MacOS/notify: notify.zig
	zig build-exe notify.zig -OReleaseFast -fstrip -lobjc
	mkdir -p ClaudeNotify.app/Contents/{MacOS,Resources}
	mv notify ClaudeNotify.app/Contents/MacOS/
	cp /Applications/Claude.app/Contents/Resources/electron.icns \
		ClaudeNotify.app/Contents/Resources/AppIcon.icns

# ── Clean ───────────────────────────────────────────────────
clean:
	rm -f statusline
	rm -rf ClaudeNotify.app/Contents/MacOS/notify \
		ClaudeNotify.app/Contents/Resources/AppIcon.icns
