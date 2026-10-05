---
name: switch-account
description: "Use when the user wants to list, check, or switch the agy login account profile (multi-account). Triggers on /switch-account and any request about ganti akun, pindah akun, or cek akun aktif."
---

# /switch-account

Manage agy login account profiles (multi-account switcher).

## Usage

```text
/switch-account list             # daftar profil + akun aktif
/switch-account current          # pointer vs file live
/switch-account switch <nama>    # ganti akun (berlaku start berikutnya)
/switch-account new <nama>       # profil baru, login link sekali
/switch-account del <nama>       # hapus profil (selain yang aktif)
```

## Steps

1. Run the switcher script with the user's arguments exactly as given:
   `sh ~/.gemini/antigravity-cli/profile-switch.sh <args>` (or `agy-switch <args>`)
   If the user gave no arguments, default to `list`.
2. Report the script output briefly.
3. Always remind: switching takes effect on the NEXT agy start (token loads
   once at startup); a fresh profile needs one browser-link login.
4. Never print tokens or full credentials — account email local-part is fine.

Relay the script output verbatim; do not reformat it into your own tables or reinterpret addresses.
