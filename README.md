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

With Windows Developer Mode enabled, run from a normal PowerShell session. Otherwise, open PowerShell **as Administrator** so it can create symbolic links:

```powershell
Set-Location "<path-to-your-dotfiles-clone>"
pwsh -File .\install.ps1
```

> Note: If elevation is required, open an Administrator session directly. Do not use `sudo` here because its separate elevated process can hide the installer's output.

## Codex settings

Codex user settings are managed in `.codex/` in this repository.

Platform install scripts link `.codex` to `$HOME/.codex` when it does not already exist.

If `$HOME/.codex` already exists and you want to migrate this machine to dotfiles-managed mode, back it up first and then relink:

```bash
mv ~/.codex ~/.codex.backup.$(date +%Y%m%d-%H%M%S)
./install.sh
```

`.codex/.gitignore` tracks the managed configuration, hooks, rules, and custom skills while ignoring runtime/generated files.

Codex writes machine-generated sections such as `[projects."<absolute-path>"]`, `[hooks.state]`, and marketplace revision metadata into the user config after project or hook approval. They contain host-specific paths or local approval/cache state.

The install scripts configure a repository-local Git clean filter for `.codex/config.toml`. Machine-local sections remain available to Codex in the working tree, but `git diff`, staging, and commits see only the portable settings. The pre-commit hook rejects these sections if the filter is missing or bypassed. The uninstall scripts remove the repository-local filter configuration.

This repository also includes project-scoped Codex hooks in `.codex/hooks.json`. Because `.codex` is linked into the user configuration directory, Codex discovers the hook definitions from every working directory. The hook dispatcher resolves the managed dotfiles clone and exits successfully unless Codex is running inside that clone, so unrelated repositories never execute dotfiles-specific hook code.

The hooks are repo-local and currently do four things:

- add startup context for dotfiles-specific conventions
- warn when editing install scripts, hook files, or Codex config
- deny obviously destructive shell commands through Codex hooks
- block prompts that appear to contain raw secrets or private keys

They complement, not replace, the git pre-commit secret scan in `.githooks/pre-commit`.

### Context-mode workflow

This repository is tuned to use `context-mode` as the first compression layer for large inputs, and `distill` as the final user-visible summary layer.

Preferred routing:

- large logs, test output, snapshots, CSV, or long command output: `ctx_execute_file` or `ctx_execute`
- large references or docs you may query again: `ctx_index` then `ctx_search`
- multiple related shell/data gathering steps: `ctx_batch_execute`
- final concise answer to the user: `distill` style output

In short: keep raw bytes out of the conversation when `ctx_*` tools can process or index them first.

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

Run the platform install script (`./install.sh` on macOS, `./install.ps1` on Windows PowerShell) to configure **global** `core.hooksPath` to this clone's `.githooks` directory.

The tracked `.gitconfig` includes `~/.gitconfig.local`. The install scripts write the machine-specific hooks path to that untracked local file, so moving or cloning this repository on another machine does not modify the tracked dotfiles. The uninstall scripts remove the value only when it still points to the current clone.

The uninstall scripts also remove only symbolic links that still point into the current clone. Links repointed to another dotfiles clone or user-managed target are preserved.

That means the hook is applied to all Git repositories on this machine, unless a repository overrides `core.hooksPath` locally. Git for Windows runs `.githooks/pre-commit` through its bundled Bash; macOS uses the script's Bash shebang.

`.gitattributes` forces LF endings for shell scripts and Git hooks so a Windows checkout remains executable by Git Bash and macOS Bash.

## Package list management

- macOS package definitions: `Brewfile`
- Windows package definitions: `Scoopfile`

Edit the platform-specific file and rerun the platform install script to apply changes.
