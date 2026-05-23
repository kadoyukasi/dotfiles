# dotfiles

This repository manages home directory configuration files by creating symbolic links from this repository into `$HOME`.

## Platform support

Use shell scripts by platform:

- macOS: run `./install.sh` and `./uninstall.sh`
- Windows (PowerShell): run `./install.ps1` and `./uninstall.ps1`

Package manager by platform:

- macOS: Homebrew (`Brewfile`)
- Windows: Scoop (`Scoopfile`)

## Windows prerequisites

### 1. Install PowerShell 7

```powershell
winget install --id Microsoft.PowerShell --source winget
```

### 2. Install Scoop

If Scoop is not installed, `install.ps1` will install it automatically. To install manually:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
```

### 3. Run the install script

Symbolic link creation requires elevated privileges. Open PowerShell **as Administrator** and run:

```powershell
cd F:\work\dotfiles
pwsh -File .\install.ps1
```

> Note: Do not use `sudo` — Scoop's `sudo` uses `Start-Process -Verb RunAs`, which spawns a separate elevated window and swallows all output. Running directly from an Administrator session is the reliable approach.

## Codex settings

Codex user settings are managed in `.codex/` in this repository.

Platform install scripts link `.codex` to `$HOME/.codex` when it does not already exist.

If `$HOME/.codex` already exists and you want to migrate this machine to dotfiles-managed mode, back it up first and then relink:

```bash
mv ~/.codex ~/.codex.backup.$(date +%Y%m%d-%H%M%S)
./install.sh
```

`.codex/.gitignore` is configured to track only managed files (`AGENTS.md`, `config.toml`) and ignore runtime/generated files.

## GitHub Copilot global instructions

Global Copilot user instructions are managed in `.copilot/instructions/global.instructions.md`.

Running the platform install script will link that directory to `$HOME/.copilot/instructions/`, which is the VS Code-supported user-level location for instructions that can apply across workspaces.

## Updating instructions

Edit `.copilot/instructions/global.instructions.md` in this repository, then rerun the platform install script on any machine where you want the symlink refreshed.

Repository-specific instructions should still live in each repository under `.github/copilot-instructions.md` when needed.

## Secret leak prevention

This repository includes a pre-commit hook at `.githooks/pre-commit` to reduce accidental commits of sensitive data.

It checks staged files for:

- Sensitive filenames/path patterns (e.g. `auth.json`, `.env*`, private key files, sqlite/db artifacts)
- High-signal secret patterns in content (private keys, common API token formats, password/token-like assignments)

Run the platform install script (`./install.sh` on macOS, `./install.ps1` on Windows PowerShell) to configure **global** `core.hooksPath` to this repository's `.githooks` directory.

That means the hook is applied to all git repositories on this machine, unless a repository overrides `core.hooksPath` locally.

## Package list management

- macOS package definitions: `Brewfile`
- Windows package definitions: `Scoopfile`

Edit the platform-specific file and rerun the platform install script to apply changes.
