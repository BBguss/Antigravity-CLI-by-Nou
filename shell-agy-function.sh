# agy-by-nou shell integration: makes `agy switch ...` work natively.
# Sourced from ~/.bashrc, ~/.zshrc, or ~/.profile (POSIX-compatible: ash, dash, bash, zsh).
# `agy switch <args>` -> instant profile switcher (no agent turn, no quota).
# Any other `agy ...` invocation passes through untouched to the real binary.
agy() {
  if [ "${1:-}" = "switch" ]; then
    shift
    if [ -x "${HOME}/.local/bin/agy-switch" ]; then
      "${HOME}/.local/bin/agy-switch" "$@"
    elif [ -f "${HOME}/.gemini/antigravity-cli/profile-switch.sh" ]; then
      sh "${HOME}/.gemini/antigravity-cli/profile-switch.sh" "$@"
    else
      echo "agy switch: profile-switch.sh not found. Run install.sh in agy-by-nou first." >&2
      return 1
    fi
  else
    if command -v agy >/dev/null 2>&1; then
      command agy "$@"
    elif [ -x "${HOME}/.local/bin/agy" ]; then
      "${HOME}/.local/bin/agy" "$@"
    elif [ -x "/usr/local/bin/agy" ]; then
      "/usr/local/bin/agy" "$@"
    else
      echo "agy: command not found" >&2
      return 127
    fi
  fi
}
