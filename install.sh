#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then
    return
  fi

  if ! python3 -m pip --version >/dev/null 2>&1; then
    if ! python3 -m ensurepip --upgrade >/dev/null 2>&1; then
      echo "python3 pip is unavailable and could not be bootstrapped with ensurepip." >&2
      exit 1
    fi
  fi

  python3 -m pip install --user --upgrade pipx
  python3 -m pipx ensurepath
  export PATH="${HOME}/.local/bin:${PATH}"
}

is_poetry_installed() {
  local pipx_json
  pipx_json="$(pipx list --json 2>/dev/null || true)"

  if [[ -z "${pipx_json}" ]]; then
    return 1
  fi

  printf '%s' "${pipx_json}" | python3 -c '
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

configure_shell_rc() {
  local rc_file="$1"
  local managed_block

  managed_block="$(cat <<'EOF'
# >>> dotfiles-python >>>
export POETRY_VIRTUALENVS_IN_PROJECT=true
export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true
case ":${PATH}:" in
  *":${HOME}/.local/bin:"*) ;;
  *) export PATH="${HOME}/.local/bin:${PATH}" ;;
esac

case $- in
  *i*)
    alias py='python3'
    alias p='poetry'
    alias pi='poetry install'
    alias pa='poetry add'
    alias pr='poetry run'
    alias pt='poetry run pytest'
    ;;
esac
# <<< dotfiles-python <<<
EOF
)"

  DOTFILES_PYTHON_BLOCK="${managed_block}" python3 - "${rc_file}" <<'PY'
from pathlib import Path
import os
import sys

rc_path = Path(sys.argv[1])
managed_block = os.environ["DOTFILES_PYTHON_BLOCK"]
contents = rc_path.read_text(encoding="utf-8") if rc_path.exists() else ""

contents = contents.replace(f"{managed_block}\n", "")
contents = contents.replace(f"\n{managed_block}", "")
contents = contents.replace(managed_block, "")
contents = contents.rstrip("\n")

if contents:
    contents = f"{contents}\n\n{managed_block}\n"
else:
    contents = f"{managed_block}\n"

rc_path.write_text(contents, encoding="utf-8")
PY
}

main() {
  local configured_rc=0
  local rc_file

  cd "${REPO_ROOT}"
  ensure_pipx
  ensure_poetry

  for rc_file in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [[ -f "${rc_file}" ]]; then
      configure_shell_rc "${rc_file}"
      configured_rc=1
    fi
  done

  if [[ "${configured_rc}" -eq 0 ]]; then
    configure_shell_rc "${HOME}/.bashrc"
  fi
}

main "$@"
