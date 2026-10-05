---
name: switch-account-del
description: "Delete an inactive agy account profile. Triggers on /switch-account-del."
---

# /switch-account-del

Delete a profile: `/switch-account-del <nama>`.

## Steps

1. Take the profile name from the user's text after the command. If empty,
   ask (never default to the active profile).
2. Run: `sh ~/.gemini/antigravity-cli/profile-switch.sh del <nama>` (or `agy-switch del <nama>`)
3. Report briefly. Never print tokens.

Relay the script output verbatim; do not reformat it into your own tables or reinterpret addresses.
