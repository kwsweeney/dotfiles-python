# dotfiles-python

<<<<<<< HEAD
Common dotfiles for a Python project.

## Included files

- `.editorconfig` for consistent formatting defaults
- `.gitignore` for Python, virtualenv, and build artifacts
- `.pre-commit-config.yaml` with basic file hygiene and a Ruff hook
- `pyproject.toml` with baseline `ruff` and `coverage` settings
- `install.sh` for Codespaces bootstrap of Python + Poetry defaults

## Codespaces bootstrap behavior

When this repository is used as your Codespaces dotfiles repo, the `install.sh` script:

- Installs `pipx` for user-scoped Python CLI tooling when it is missing
- Installs/updates `poetry` with `pipx`
- Sets Poetry defaults for project-local virtual environments via shell environment variables
- Adds Python/Poetry helper aliases to existing `~/.bashrc`/`~/.zshrc` files (or creates `~/.bashrc` if neither exists)

## Included shell aliases

- `py` → `python3`
- `p` → `poetry`
- `pi` → `poetry install`
- `pa` → `poetry add`
- `pr` → `poetry run`
- `pt` → `poetry run pytest`
