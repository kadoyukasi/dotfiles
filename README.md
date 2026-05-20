# dotfiles

This repository manages home directory configuration files by creating symbolic links from this repository into `$HOME`.

## Codex settings

Codex user settings are managed in `.codex/` in this repository.

`./install.sh` links `.codex` to `$HOME/.codex` when it does not already exist.

If `$HOME/.codex` already exists and you want to migrate this machine to dotfiles-managed mode, back it up first and then relink:

```bash
mv ~/.codex ~/.codex.backup.$(date +%Y%m%d-%H%M%S)
./install.sh
```

`.codex/.gitignore` is configured to track only managed files (`AGENTS.md`, `config.toml`) and ignore runtime/generated files.

## GitHub Copilot global instructions

Global Copilot user instructions are managed in `.copilot/instructions/global.instructions.md`.

Running `./install.sh` will link that directory to `$HOME/.copilot/instructions/`, which is the VS Code-supported user-level location for instructions that can apply across workspaces.

## Updating instructions

Edit `.copilot/instructions/global.instructions.md` in this repository, then rerun `./install.sh` on any machine where you want the symlink refreshed.

Repository-specific instructions should still live in each repository under `.github/copilot-instructions.md` when needed.

## Secret leak prevention

This repository includes a pre-commit hook at `.githooks/pre-commit` to reduce accidental commits of sensitive data.

It checks staged files for:

- Sensitive filenames/path patterns (e.g. `auth.json`, `.env*`, private key files, sqlite/db artifacts)
- High-signal secret patterns in content (private keys, common API token formats, password/token-like assignments)

Run `./install.sh` to configure **global** `core.hooksPath` to this repository's `.githooks` directory.

That means the hook is applied to all git repositories on this machine, unless a repository overrides `core.hooksPath` locally.
