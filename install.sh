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

ensure_poetry() {
  if ! pipx upgrade poetry; then
    pipx install poetry
  fi
}

configure_poetry_defaults() {
  poetry config virtualenvs.in-project true
  poetry config virtualenvs.prefer-active-python true
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
  configure_poetry_defaults
  configure_bashrc
}

main "$@"
