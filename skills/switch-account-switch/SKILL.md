---
name: switch-account-switch
description: "Switch agy account profile by name. Triggers on /switch-account-switch."
---

# /switch-account-switch

Switch account profile: `/switch-account-switch <nama>`.

## Steps

1. Take the profile name from the user's text after the command. If empty,
   run the `list` action first and ask which one.
2. Run: `sh ~/.gemini/antigravity-cli/profile-switch.sh switch <nama>` (or `agy-switch switch <nama>`)
3. Report briefly and always remind: the switch takes effect on the NEXT agy
   start (token loads once at startup). Never print tokens.

Relay the script output verbatim; do not reformat it into your own tables or reinterpret addresses.
