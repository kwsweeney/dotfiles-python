# dotfiles-python

Python-focused dotfiles for GitHub Codespaces.

## What this config does

When this repository is used as your Codespaces dotfiles repo, the `install.sh` script:

- Installs `pipx` for user-scoped Python CLI tooling when it is missing
- Installs/updates `poetry` with `pipx`
- Sets Poetry defaults for project-local virtual environments via shell environment variables
- Adds Python/Poetry helper aliases to your active shell RC file (`~/.bashrc` or `~/.zshrc`)

## Included shell aliases

- `py` → `python3`
- `p` → `poetry`
- `pi` → `poetry install`
- `pa` → `poetry add`
- `pr` → `poetry run`
- `pt` → `poetry run pytest`
