#!/bin/sh
# agy-by-nou installer — installs the custom usage statusline, multi-account switcher,
# slash commands, and skills into standard Antigravity CLI directories (~/.gemini/).
# Idempotent, safe to re-run anytime.
# Usage: sh install.sh

set -e

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/bin${PATH:+:$PATH}"
if [ -z "$HOME" ]; then
    _u="$(id -un 2>/dev/null || whoami 2>/dev/null || echo "$USER")"
    [ -n "$_u" ] && HOME="$(getent passwd "$_u" 2>/dev/null | cut -d: -f6)"
    [ -z "$HOME" ] && [ -n "$_u" ] && HOME="$(eval echo "~$_u" 2>/dev/null)"
    [ -z "$HOME" ] && HOME=~
    export HOME
fi

SRC_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
G="$HOME/.gemini/antigravity-cli"
C="$HOME/.gemini/commands"
S="$HOME/.gemini/config/skills"
B="$HOME/.local/bin"
P="$HOME/.gemini/antigravity-profiles"

echo "==> Installing agy-by-nou to user environment ($HOME)..."

# 1. Create target directories
mkdir -p "$G" "$C" "$S" "$B" "$P" 2>/dev/null
chmod 700 "$P" 2>/dev/null

# 2. Copy core statusline & profile switcher scripts
cp "$SRC_DIR/statusline-usage.sh" "$SRC_DIR/restore-statusline.sh" "$SRC_DIR/statusline-config.json" "$SRC_DIR/profile-switch.sh" "$SRC_DIR/shell-agy-function.sh" "$G/"
chmod +x "$G/statusline-usage.sh" "$G/restore-statusline.sh" "$G/profile-switch.sh"

# 3. Install CLI binary agy-switch
cp "$SRC_DIR/bin/agy-switch" "$B/agy-switch"
chmod +x "$B/agy-switch"

# 4. Install slash commands
if [ -d "$SRC_DIR/commands" ]; then
    cp "$SRC_DIR/commands/"*.toml "$C/" 2>/dev/null || true
fi

# 5. Install skills
if [ -d "$SRC_DIR/skills" ]; then
    for sdir in "$SRC_DIR/skills"/*; do
        [ -d "$sdir" ] || continue
        sname=$(basename "$sdir")
        mkdir -p "$S/$sname" 2>/dev/null
        cp -r "$sdir/"* "$S/$sname/" 2>/dev/null || true
    done
fi

# 6. Apply statusline config into settings.json
sh "$G/restore-statusline.sh"

echo "==> Installation complete!"
echo "    - Statusline & Switcher : $G"
echo "    - CLI Binary           : $B/agy-switch"
echo "    - Slash Commands       : $C"
echo "    - Skills               : $S"
echo ""
echo "Optional shell integration for 'agy switch':"
echo "Add this line to your ~/.bashrc, ~/.zshrc, or ~/.profile:"
echo "  [ -f \"\$HOME/.gemini/antigravity-cli/shell-agy-function.sh\" ] && . \"\$HOME/.gemini/antigravity-cli/shell-agy-function.sh\""
