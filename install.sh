#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="${HOME}/.bashrc"

ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then
    return
  fi

  python3 -m pip install --user --upgrade pip pipx
  python3 -m pipx ensurepath
  export PATH="${HOME}/.local/bin:${PATH}"
}

is_poetry_installed() {
  pipx list --json 2>/dev/null | python3 -c '
import json
import sys

data = json.load(sys.stdin)
sys.exit(0 if "poetry" in data.get("venvs", {}) else 1)
'
}

ensure_poetry() {
  if is_poetry_installed; then
    pipx upgrade poetry
  else
    pipx install poetry
  fi
}

configure_bashrc() {
  local start_marker="# >>> dotfiles-python >>>"
  local end_marker="# <<< dotfiles-python <<<"

  touch "${BASHRC}"

  if grep -qF "${start_marker}" "${BASHRC}" && grep -qF "${end_marker}" "${BASHRC}"; then
    awk -v start="${start_marker}" -v end="${end_marker}" '
      $0 == start { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "${BASHRC}" >"${BASHRC}.tmp"
    mv "${BASHRC}.tmp" "${BASHRC}"
  elif grep -qF "${start_marker}" "${BASHRC}"; then
    awk -v start="${start_marker}" '$0 != start { print }' "${BASHRC}" >"${BASHRC}.tmp"
    mv "${BASHRC}.tmp" "${BASHRC}"
  elif grep -qF "${end_marker}" "${BASHRC}"; then
    awk -v end="${end_marker}" '$0 != end { print }' "${BASHRC}" >"${BASHRC}.tmp"
    mv "${BASHRC}.tmp" "${BASHRC}"
  fi

  cat >>"${BASHRC}" <<'EOF'
# >>> dotfiles-python >>>
export POETRY_VIRTUALENVS_IN_PROJECT=true
export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true
export PATH="${HOME}/.local/bin:${PATH}"

alias py='python3'
alias p='poetry'
alias pi='poetry install'
alias pa='poetry add'
alias pr='poetry run'
alias pt='poetry run pytest'
# <<< dotfiles-python <<<
EOF
}

main() {
  cd "${REPO_ROOT}"
  ensure_pipx
  ensure_poetry
  configure_bashrc
}

main "$@"
