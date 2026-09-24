#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ensure_pipx() {
  if command -v pipx >/dev/null 2>&1; then
    return
  fi

  python3 -m pip install --user --upgrade pip pipx
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
  local start_marker="# >>> dotfiles-python >>>"
  local end_marker="# <<< dotfiles-python <<<"

  touch "${rc_file}"

  python3 - "${rc_file}" "${start_marker}" "${end_marker}" <<'PY'
from pathlib import Path
import sys

rc_path = Path(sys.argv[1])
start_marker = sys.argv[2]
end_marker = sys.argv[3]

lines = rc_path.read_text().splitlines(keepends=True)

start_index = next((idx for idx, line in enumerate(lines) if line.rstrip("\n") == start_marker), None)
if start_index is not None:
    end_index = next(
        (idx for idx in range(start_index + 1, len(lines)) if lines[idx].rstrip("\n") == end_marker),
        None,
    )
    if end_index is not None:
        lines = lines[:start_index] + lines[end_index + 1 :]
    else:
        lines = [line for line in lines if line.rstrip("\n") != start_marker]
else:
    lines = [line for line in lines if line.rstrip("\n") != end_marker]

rc_path.write_text("".join(lines))
PY

  cat >>"${rc_file}" <<'EOF'
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
  configure_shell_rc "${HOME}/.bashrc"
  configure_shell_rc "${HOME}/.zshrc"
}

main "$@"
