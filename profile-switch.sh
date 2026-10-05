#!/bin/sh
# agy profile switcher — multiple accounts, one TUI session at a time.
# Profiles (settings.json + oauth token + installation_id) live PRIVATE under
# ~/.gemini/antigravity-profiles/ with 0600 perms. NEVER store tokens in shared
# repositories or public directories — profile DATA must stay private.
# Switch swaps the 3 identity files in the live config dir (with backup) and
# takes effect on the NEXT agy start (token is read once at startup; the
# running session keeps its in-memory identity — safe to switch anytime).
# Login baru tetap via link seperti biasa, sekali per profil.
# Usage: profile-switch.sh list | current | switch <name> | new <name> | del <name>
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/bin${PATH:+:$PATH}"
if [ -z "$HOME" ]; then
    _u="$(id -un 2>/dev/null || whoami 2>/dev/null || echo "$USER")"
    [ -n "$_u" ] && HOME="$(getent passwd "$_u" 2>/dev/null | cut -d: -f6)"
    [ -z "$HOME" ] && [ -n "$_u" ] && HOME="$(eval echo "~$_u" 2>/dev/null)"
    [ -z "$HOME" ] && HOME=~
    export HOME
fi
G="$HOME/.gemini/antigravity-cli"
P="$HOME/.gemini/antigravity-profiles"
FILES="settings.json antigravity-oauth-token installation_id"
mkdir -p "$P" 2>/dev/null
chmod 700 "$P" 2>/dev/null

mail_of() {
  python3 -c 'import json,base64,sys
try:
    d=json.load(open(sys.argv[1]))
    p=d.get("id_token","").split(".")[1]; p+="="*(-len(p)%4)
    print(json.loads(base64.urlsafe_b64decode(p)).get("email","?"))
except Exception:
    print("?")' "$1/antigravity-oauth-token" 2>/dev/null
}

show_current() {
  cur=$(cat "$P/.active" 2>/dev/null || echo "?")
  echo "pointer: $cur"
  echo "live files: $(mail_of "$G")  (restart agy bila beda)"
  if ps | grep -q 'bin/agy$' 2>/dev/null; then
    echo "note: sesi agy sedang berjalan — switch berlaku mulai start berikutnya"
  fi
}

cmd="$1"; name="$2"
case "$cmd" in
  list)
    cur=$(cat "$P/.active" 2>/dev/null || echo "?")
    live=$(mail_of "$G")
    for d in "$P"/*/; do
      [ -d "$d" ] || continue
      n=$(basename "$d")
      m=$(mail_of "$d")
      if [ "$n" = "$cur" ]; then
        mark="*"
        if [ "$m" = "?" ] && [ "$live" != "?" ]; then m="$live (live)"; fi
      else
        mark=" "
      fi
      printf '%s %-12s %s\n' "$mark" "$n" "$m"
    done
    show_current
    ;;
  current)
    show_current
    ;;
  new)
    [ -n "$name" ] || { echo "usage: $0 new <name>"; exit 1; }
    [ -e "$P/$name" ] && { echo "profile '$name' sudah ada"; exit 1; }
    mkdir -p "$P/$name" && chmod 700 "$P/$name"
    cp "$G/settings.json" "$P/$name/settings.json"
    cp "$G/installation_id" "$P/$name/installation_id" 2>/dev/null || true
    echo "profile '$name' dibuat dari settings aktif TANPA token."
    echo "switch ke '$name' lalu start agy dan login via link sekali."
    ;;
  switch)
    [ -n "$name" ] || { echo "usage: $0 switch <name>"; exit 1; }
    [ -d "$P/$name" ] || { echo "profile '$name' tidak ada"; exit 1; }
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$P/$name/settings.json" 2>/dev/null \
      || { echo "settings profile '$name' korup"; exit 1; }
    cur=$(cat "$P/.active" 2>/dev/null || echo "default")
    if [ "$cur" = "$name" ]; then echo "sudah di profile '$name'"; exit 0; fi
    ts=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$P/.lastbackup" && chmod 700 "$P/.lastbackup"
    for f in $FILES; do cp "$G/$f" "$P/.lastbackup/$f" 2>/dev/null || true; done
    if [ -d "$P/$cur" ]; then
      for f in $FILES; do cp "$G/$f" "$P/$cur/$f" 2>/dev/null || true; done
      echo "state '$cur' disimpan kembali (sync-back $ts)"
    fi
    cp "$P/$name/settings.json" "$G/settings.json" \
      || { echo "GAGAL salin settings, dibatalkan"; exit 1; }
    cp "$P/$name/installation_id" "$G/installation_id" 2>/dev/null || true
    if [ -f "$P/$name/antigravity-oauth-token" ]; then
      cp "$P/$name/antigravity-oauth-token" "$G/antigravity-oauth-token" \
        || { echo "GAGAL salin token, rollback settings"; cp "$P/.lastbackup/settings.json" "$G/settings.json"; exit 1; }
    else
      rm -f "$G/antigravity-oauth-token"
    fi
    python3 -c 'import json; json.load(open("'$G'/settings.json"))' || {
      echo "settings.json hasil switch korup — rollback dari .lastbackup"
      for f in $FILES; do cp "$P/.lastbackup/$f" "$G/$f" 2>/dev/null || true; done
      exit 1
    }
    echo "$name" > "$P/.active"
    live=$(mail_of "$G")
    if [ "$live" = "?" ]; then
      echo "switch -> '$name'. Belum login — start agy dan login via link sekali."
    else
      echo "switch -> '$name' ($live). Restart agy untuk memakai."
    fi
    ;;
  del)
    [ -n "$name" ] || { echo "usage: $0 del <name>"; exit 1; }
    cur=$(cat "$P/.active" 2>/dev/null || echo "?")
    [ "$name" = "$cur" ] && { echo "profile aktif tak bisa dihapus"; exit 1; }
    [ -d "$P/$name" ] || { echo "profile '$name' tidak ada"; exit 1; }
    rm -rf "$P/$name" && echo "profile '$name' dihapus"
    ;;
  *) echo "usage: $0 list | current | switch <name> | new <name> | del <name>"; exit 1;;
esac
