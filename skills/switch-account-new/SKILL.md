---
name: switch-account-new
description: "Create a new agy account profile and guide browser-link login. Triggers on /switch-account-new."
---

# /switch-account-new

Add a new account profile: `/switch-account-new <nama>`.

## Steps

1. Take the profile name from the user's text after the command. If empty,
   ask for it (short, no spaces) and wait.
2. Run: `sh ~/.gemini/antigravity-cli/profile-switch.sh new <nama>` (or `agy-switch new <nama>`)
3. Then explain the login mechanism: switch to it
   (`/switch-account-switch <nama>`), start agy, complete the one-time
   Google OAuth browser-link login. Never print tokens.

Relay the script output verbatim; do not reformat it into your own tables or reinterpret addresses.
