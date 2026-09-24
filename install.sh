#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then
    return
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

  touch "${rc_file}"

  managed_block="$(cat <<'EOF'
# >>> dotfiles-python >>>
export POETRY_VIRTUALENVS_IN_PROJECT=true
export POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON=true
export PATH="${HOME}/.local/bin:${PATH}"

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
contents = rc_path.read_text(encoding="utf-8")

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
  cd "${REPO_ROOT}"
  ensure_pipx
  ensure_poetry
  configure_shell_rc "${HOME}/.bashrc"
  configure_shell_rc "${HOME}/.zshrc"
}

main "$@"
