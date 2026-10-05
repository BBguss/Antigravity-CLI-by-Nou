#!/bin/sh
# agy usage statusline — visual 5h/weekly quota gauges + session context.
# DIRECT MODE (v5): the runner pipes session JSON into stdin on every render
# (quota fractions, email, cwd, model, terminal width) — so there is no
# fetch, no cache writer, no lock, no background job, zero spawned processes
# in the render path. Sync path = ONE python3 call reading stdin + cache.
# Fallback order: stdin payload -> last-good /tmp cache file -> "usage: ?".
# Runner env is stripped (no HOME, minimal PATH) -> pinned explicitly below.
# Managed outside KolabPanel workspace — intentionally NOT in plan-agent.md.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/bin${PATH:+:$PATH}"
if [ -z "$HOME" ]; then
    _u="$(id -un 2>/dev/null || whoami 2>/dev/null || echo "$USER")"
    [ -n "$_u" ] && HOME="$(getent passwd "$_u" 2>/dev/null | cut -d: -f6)"
    [ -z "$HOME" ] && [ -n "$_u" ] && HOME="$(eval echo "~$_u" 2>/dev/null)"
    [ -z "$HOME" ] && HOME=~
    export HOME
fi

CACHE_FILE="/tmp/agy-usage-statusline.json"
export CACHE_FILE

python3 /dev/fd/3 3<<'PYEOF'
import json, os, sys, time, datetime, select

CACHE = os.environ.get("CACHE_FILE", "")
COLOR = not os.environ.get("NO_COLOR")

def c(code):
    return ("\033[%sm" % code) if COLOR else ""

def pct(f):
    # Half-up to match Go-formatted /usage (Python round is banker's).
    try:
        return int(float(f) * 100 + 0.5)
    except Exception:
        return None

def bar(p, width=6):
    if p is None:
        return "?" * width
    f = max(0, min(width, int(round(p * width / 100.0))))
    col = "32" if p >= 70 else ("33" if p >= 30 else "31")
    return "%s%s%s%s" % (c(col), "█" * f, "░" * (width - f), c("0"))

def countdown_secs(s):
    try:
        s = int(s)
    except Exception:
        return ""
    if s < 60:
        return "now"
    if s < 3600:
        return "%dm" % (s // 60)
    if s < 86400:
        return "%dh" % (s // 3600)
    return "%dd" % (s // 86400)

def countdown_iso(iso):
    try:
        d = datetime.datetime.strptime(iso, "%Y-%m-%dT%H:%M:%SZ") - datetime.datetime.utcnow()
        return countdown_secs(d.total_seconds())
    except Exception:
        return ""

def wdate(iso):
    try:
        return datetime.datetime.strptime(iso, "%Y-%m-%dT%H:%M:%SZ").strftime("%d%b")
    except Exception:
        return ""

def gauge(label, p, reset):
    if p is None:
        return "%s ?" % label
    ptxt = "%d%%" % p
    if p < 30:
        ptxt = "%s%s%s" % (c("1;31"), ptxt, c("0"))
    return "%s %s %s %s%s%s" % (label, bar(p), ptxt, c("2"), reset, c("0"))

def read_stdin_json(timeout=0.5):
    # Bounded pipe read: never blocks past timeout, never reads past 64K.
    try:
        fd = sys.stdin.fileno()
    except Exception:
        return None
    chunks = []
    total = 0
    end = time.time() + timeout
    try:
        while True:
            r, _, _ = select.select([fd], [], [], max(0, end - time.time()))
            if not r:
                break
            data = os.read(fd, 65536)
            if not data:
                break
            chunks.append(data)
            total += len(data)
            if total > 65536:
                break
    except Exception:
        pass
    if not chunks:
        return None
    try:
        raw = b"".join(chunks).decode("utf-8", "replace")
        return json.loads(raw) if raw.strip() else None
    except Exception:
        return None

payload = read_stdin_json()

groups = []
resets = {}
if isinstance(payload, dict):
    q = payload.get("quota") or {}
    gm5 = q.get("gemini-5h") or {}
    gmw = q.get("gemini-weekly") or {}
    if gm5 or gmw:
        cd5 = countdown_secs(gm5.get("reset_in_seconds")) if gm5.get("reset_in_seconds") is not None else countdown_iso(gm5.get("reset_time") or "")
        wd = wdate(gmw.get("reset_time") or "")
        groups = [{"name": "Gemini Models", "buckets": [
            {"window": "5h", "remaining_fraction": gm5.get("remaining_fraction"),
             "reset": ("↺%s " % cd5) if cd5 else ""},
            {"window": "weekly", "remaining_fraction": gmw.get("remaining_fraction"),
             "reset": (" %s" % wd) if wd else ""}]}]
if not groups:
    try:
        raw = json.load(open(CACHE))
        data = (raw.get("command") or {}).get("data") or {}
        allg = data.get("groups") or []
        gem = [g for g in allg if "Gemini" in (g.get("name") or "")]
        allg = gem or allg[:1]
        for g in allg:
            buckets = []
            for b in (g.get("buckets") or []):
                w = b.get("window")
                if w == "5h":
                    cd = countdown_iso(b.get("reset_time") or "")
                    buckets.append({"window": w, "remaining_fraction": b.get("remaining_fraction"),
                                    "reset": ("↺%s " % cd) if cd else ""})
                elif w == "weekly":
                    wd = wdate(b.get("reset_time") or "")
                    buckets.append({"window": w, "remaining_fraction": b.get("remaining_fraction"),
                                    "reset": (" %s" % wd) if wd else ""})
            if buckets:
                groups.append({"name": g.get("name"), "buckets": buckets})
    except Exception:
        groups = []

segs = []
for g in groups:
    name = g.get("name") or "?"
    short = "Gemini" if "Gemini" in name else name[:6]
    buckets = {b.get("window"): b for b in (g.get("buckets") or [])}
    w = buckets.get("weekly") or {}
    h = buckets.get("5h") or {}
    wp, hp = pct(w.get("remaining_fraction")), pct(h.get("remaining_fraction"))
    worst = min([v for v in (wp, hp) if v is not None] or [100])
    dot = "%s●%s" % (c("32" if worst >= 70 else ("33" if worst >= 30 else "31")), c("0"))
    hreset, wreset = h.get("reset", ""), w.get("reset", "")
    segs.append("%s %s %s  %s" % (dot, short, gauge("5h", hp, hreset).rstrip(), gauge("W", wp, wreset).rstrip()))

try:
    cwd = os.getcwd()
except Exception:
    cwd = ""
try:
    home = os.path.expanduser("~")
except Exception:
    home = ""
if home and cwd == home:
    disp = "~"
elif home and cwd.startswith(home + os.sep):
    disp = "~" + cwd[len(home):]
else:
    disp = os.path.basename(cwd) or cwd

ctx = []
mail = (payload or {}).get("email", "") if isinstance(payload, dict) else ""
if mail and "@" in mail:
    ctx.append("@%s" % mail.split("@")[0])
try:
    # Instant local profile roster (no fetch, no quota): shown only when
    # more than one profile exists; active one carries the star.
    profdir = os.path.join(home, ".gemini", "antigravity-profiles") if home else ""
    names = sorted(d for d in os.listdir(profdir)
                   if not d.startswith(".") and os.path.isfile(os.path.join(profdir, d, "settings.json"))) if profdir else []
    if len(names) > 1:
        try:
            active = open(os.path.join(profdir, ".active")).read().strip()
        except Exception:
            active = ""
        ctx.append("acc:%s" % " ".join(n + ("*" if n == active else "") for n in names))
except Exception:
    pass
clock = datetime.datetime.now().strftime("%H:%M")
if clock or disp:
    ctx.append(("%s %s" % (clock, disp)).strip())
def git_branch():
    # Live and cheap (~15ms): branch name + dirty star, no background needed.
    import subprocess
    try:
        br = subprocess.run(["git", "branch", "--show-current"],
                            capture_output=True, text=True, timeout=2).stdout.strip()
        if not br:
            return ""
        st = subprocess.run(["git", "status", "--porcelain", "--untracked-files=no"],
                            capture_output=True, text=True, timeout=2).stdout.strip()
        return br + ("*" if st else "")
    except Exception:
        return ""

gitval = git_branch()
if gitval:
    branch, dirty = (gitval[:-1], True) if gitval.endswith("*") else (gitval, False)
    star = ("%s*%s" % (c("1;33"), c("0"))) if dirty else ""
    ctx.append("%s⎇ %s%s%s" % (c("36"), branch, star, c("0")))

sep = " %s│%s " % (c("2"), c("0"))
out = sep.join(segs) if segs else "usage: ?"
if ctx:
    out += sep + ("%s%s%s" % (c("2"), "  ".join(ctx), c("0")))
print(out[:1200])
PYEOF
exit 0
