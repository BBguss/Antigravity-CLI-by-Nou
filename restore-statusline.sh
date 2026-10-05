#!/bin/sh
# Re-apply the custom usage statusline to settings.json (idempotent).
# Use when: agy update / `/statusline reset|delete` wiped the custom block,
# or settings.json was replaced. Safe to run anytime (no-op if already set).
# Managed outside KolabPanel workspace — intentionally NOT in plan-agent.md.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/bin${PATH:+:$PATH}"
if [ -z "$HOME" ]; then
    _u="$(id -un 2>/dev/null || whoami 2>/dev/null || echo "$USER")"
    [ -n "$_u" ] && HOME="$(getent passwd "$_u" 2>/dev/null | cut -d: -f6)"
    [ -z "$HOME" ] && [ -n "$_u" ] && HOME="$(eval echo "~$_u" 2>/dev/null)"
    [ -z "$HOME" ] && HOME=~
    export HOME
fi
G="$HOME/.gemini/antigravity-cli"
mkdir -p "$G" 2>/dev/null
python3 - "$G/settings.json" "$G/statusline-config.json" <<'PYEOF'
import json, sys, shutil, datetime, os
sj, cj = sys.argv[1], sys.argv[2]
G = os.path.dirname(os.path.abspath(sj))

cur = {}
if os.path.exists(sj):
    try:
        cur = json.load(open(sj))
    except Exception:
        cur = {}

want = {
    "type": "command",
    "command": os.path.join(G, "statusline-usage.sh"),
    "enabled": True,
    "stack_with_default": True
}
if os.path.exists(cj):
    try:
        loaded = json.load(open(cj))
        if isinstance(loaded, dict):
            want.update(loaded)
    except Exception:
        pass
want["command"] = os.path.join(G, "statusline-usage.sh")

if cur.get("statusLine") == want:
    print("statusline already set — no change")
    sys.exit(0)

if os.path.exists(sj):
    shutil.copy2(sj, sj + ".bak-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))
cur["statusLine"] = want
json.dump(cur, open(sj, "w"), indent=2)
print("statusline restored")
PYEOF
chmod +x "$G/statusline-usage.sh"
