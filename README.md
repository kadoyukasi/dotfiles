# dotfiles

Windows と macOS で設定を共有します。共有ファイルのリンク先と初期コピーの対象は `install_targets.txt` で管理します。認証情報やアプリが書き換える状態は、各端末の設定ディレクトリで管理します。

## Platform support

Use shell scripts by platform:

- macOS: run `./install.sh` and `./uninstall.sh`
- Windows (PowerShell): run `./install.ps1` and `./uninstall.ps1`

設定だけを導入する場合は、macOS で `./install.sh --no-packages`、Windows で `pwsh -File .\install.ps1 -NoPackages` を実行します。既存ファイルはそのまま使い、アンインストール時はこのクローンを指すファイルリンクを解除します。初期コピー、認証情報、個別設定、親ディレクトリはアンインストール後も利用できます。

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

## 旧インストールからの移行

旧版で作られたディレクトリリンクを検出すると、配下のファイルをスキップします。移行する場合はアプリを閉じ、`~/.codex`、`~/.config`、`~/.ssh`、`~/.copilot`、`~/.zsh` のうち、クローンを指すリンクを確認します。リンク先に保存されたローカルファイルをリポジトリの外にバックアップしてから、リンクを別名に退避し、実ディレクトリを作成してください。そこへ必要な認証情報、SSH 鍵、`known_hosts`、アプリ設定を戻します。`~/.gitconfig` も旧版のリンクなら退避してからインストーラーを再実行します。既存の設定ファイルには必要な共有設定を手動で反映します。

## Codex settings

インストーラーは `$CODEX_HOME`（未指定時は `~/.codex`）に共有の指示、ルール、スキル、プロファイルをファイル単位でリンクし、`config.toml` がない場合だけ初期コピーを作ります。共有側の更新は端末の `config.toml` に必要な項目を反映してください。プロジェクトの信頼設定、フックの承認、デスクトップのランタイムやプラグインのパス、遠隔操作の設定は各端末で管理します。

The managed Codex configuration balances implementation quality with token use:

- `gpt-6.2-sol` with `model_reasoning_effort = "medium"` for implementation and debugging
- `service_tier = "default"` for standard speed and `model_verbosity = "low"` for models that apply the verbosity override
- 大量入力には `context-mode` を有効化。新しい端末ではプラグインを端末側にもインストールしてください。
- 承認は `on-request` と `auto_review`、サンドボックスは `workspace-write` を初期値にします。Windows では `[windows].sandbox = "unelevated"` も適用します。

Codex 0.134 and later loads CLI profiles from separate files in `~/.codex/`. The managed profiles layer the following integration settings over the base configuration:

| Profile | Enables |
| --- | --- |
| `code` | GitHub プラグインと Serena |
| `artifacts` | documents, spreadsheets, and presentations plugins |
| `browser` | in-app browser plugin |
| `full` | 上記すべて |

For example, run `codex --profile code` for repository work or `codex --profile full` when all integrations are needed. Profiles are CLI configuration layers; the desktop app continues to use the base configuration unless integrations are enabled in its settings.

`code` と `full` プロファイルは、各端末の `PATH` にある `uvx` から Python 3.13 で Serena を起動します。パッケージ一覧には `uv` が含まれます。初回は Python や依存関係を取得する場合があり、MCP の起動タイムアウトは60秒です。接続状態は Codex の `/mcp` で確認できます。 プロファイルが有効化するプラグインは各端末でインストールします。

Global communication and safety defaults live in `.codex/AGENTS.md`. Repository-specific invariants live in the root `AGENTS.md`, avoiding repeated or conflicting instructions.

The user-level defaults are loaded from `~/.codex/config.toml` and `~/.codex/AGENTS.md` (or `CODEX_HOME` when set). Trusted project configuration can override the user defaults, and repository guidance can specify the product and verification steps.

特定プロジェクトのルート検出に追加マーカーが必要な場合は、端末側の `config.toml` の `project_root_markers` に設定します。プロジェクト固有のモデルやエージェントは、そのプロジェクトの `.codex/` で管理します。

### 精度を保つトークン節約

- 検索範囲を絞り、未変更の資料・取得済み結果を再利用する。
- 大量出力はcontext-modeで処理し、件数・該当箇所・終了コードを返す。失敗・不確実性があれば原文と周辺を確認する。
- 成功済み検証は変更・失敗・未解決の懸念がある場合に再実行する。必要な検証を省略しない。
- 実装・原因調査は既定の `medium` を使う。軽い整形や機械的な変更は `low`、難しい設計や再現しにくい不具合は必要に応じて `high` にする。CLI では `codex -c 'model_reasoning_effort="low"'` のように指定できる。デスクトップではチャットの推論量を選ぶ。
- 案件固有の指定がなければ、一般ユーザー向けの PC ソフトウェア一製品を想定し、通常の起動・操作経路で変更を検証する。
- デスクトップのコミット指示は Conventional Commits の書式と対象差分の確認に絞る。

設定項目は[OpenAI公式設定リファレンス](https://learn.chatgpt.com/docs/config-file/config-reference)を参照。削減率と精度の維持は未計測。同種タスクの使用量と受入条件の達成を比較して評価する。

設定と共通指示は新しいチャットで確認する。既存の端末設定に反映する際は、モデル、推論量、速度、コミット指示の対象項目と、`AGENTS.md`、`skills/distill/SKILL.md` の差分を確認する。

インストーラーは、このクローンの `.codex/config.toml` 用にリポジトリローカルの Git clean フィルターも登録します。フィルターは、プロジェクトの信頼設定、フックの承認状態、マーケットプレイス情報と一部の端末固有パスをステージ時に除きます。pre-commit フックでもステージ済みの設定を検査します。アンインストール時に、このフィルターの登録を解除します。

This repository includes project-scoped Codex hooks in `.codex/hooks.json`. The dispatcher runs them only inside the dotfiles checkout.


The hooks are repo-local and currently do four things:

- add startup context for dotfiles-specific conventions
- warn when editing install scripts, hook files, or Codex config
- deny obviously destructive shell commands through Codex hooks
- block prompts that appear to contain raw secrets or private keys

They complement, not replace, the git pre-commit secret scan in `.githooks/pre-commit`.

### Context-mode workflow

Use `context-mode` to filter large inputs. Use the `distill` skill when the user explicitly requests a compressed result or S/C/D/R/O/P formatting.

Preferred routing:

- large logs, test output, snapshots, or CSV: `ctx_execute` with a command or file
- large references or docs you may query again: `ctx_index` then `ctx_search`
- multiple related commands: `ctx_batch`
- explicitly requested compressed result: `distill` style output

Do not pipe tests, builds, lint, diffs, security checks, or infrastructure plans through `distill` for PASS/FAIL or safety decisions. Keep their original exit codes and required raw evidence. In short: keep raw bytes out of the conversation with `ctx_*`, and avoid a second summarization step unless it improves the final user-facing result.

## GitHub Copilot global instructions

Global Copilot user instructions are managed in `.copilot/instructions/global.instructions.md`.

Running the platform install script will link this file into `$HOME/.copilot/instructions/`, which is the VS Code-supported user-level location for instructions that can apply across workspaces.

## Updating instructions

Edit `.copilot/instructions/global.instructions.md` in the local clone. An installed link picks up changes to its target.

Repository-specific instructions should still live in each repository under `.github/copilot-instructions.md` when needed.

## Secret leak prevention

Git の `~/.gitconfig` は初回だけコピーします。ユーザー名、メール、署名鍵は各端末の `~/.gitconfig.local` に設定します。

```sh
git config --file "$HOME/.gitconfig.local" user.name "Your Name"
git config --file "$HOME/.gitconfig.local" user.email "you@example.com"
```

SSH 署名を使う場合は、同じファイルに `gpg.format = ssh` と `user.signingkey` を設定します。SSH 接続に標準名以外の鍵を使う場合は、`~/.ssh/config.local` の対象ホストに `IdentityFile` と必要に応じて `IdentitiesOnly yes` を設定します。SSH 鍵と `known_hosts` は `~/.ssh/` で管理します。

GitHub CLI の `config.yml` は `GH_CONFIG_DIR`、`XDG_CONFIG_HOME/gh`、Windows の `APPDATA/GitHub CLI`、`~/.config/gh` の順に保存先を選び、初回だけコピーします。ログインは各端末で `gh auth login` を実行します。その他の `.config/` 配下の管理ファイルは `XDG_CONFIG_HOME`（未指定時は `~/.config`）を使います。PowerShell のプロンプト設定は既存の `STARSHIP_CONFIG` を優先します。

This repository includes a pre-commit hook at `.githooks/pre-commit` to reduce accidental commits of sensitive data.

It checks staged files for:

- Sensitive filenames/path patterns (e.g. `auth.json`, `.env*`, private key files, sqlite/db artifacts)
- High-signal secret patterns in content (private keys, common API token formats, password/token-like assignments). Diagnostics report the path.
- Machine-local home paths for macOS, Linux, and Windows in staged content, including Windows paths escaped in configuration files

インストーラーは、このクローンの `.githooks` を `~/.gitconfig.local` の `core.hooksPath` に登録します。既存の別のフック設定があれば維持します。共有の `.gitconfig` はローカル設定を読み込みます。独自のグローバル設定を使っていてインストーラーがフックの未適用を報告した場合は、その設定に次の読み込みを追加してください。

```sh
git config --global --add include.path '~/.gitconfig.local'
git config --global --includes --get core.hooksPath
```

フックは端末の全 Git リポジトリに適用されます。リポジトリ単位の `core.hooksPath` がある場合はそちらが優先されます。Windows では Git for Windows の Bash、macOS ではスクリプトの shebang を使います。アンインストーラーは、`~/.gitconfig.local` の値がこのクローンを指す場合に解除します。

`.gitattributes` forces LF endings for shell scripts and Git hooks so a Windows checkout remains executable by Git Bash and macOS Bash.

## Package list management

- macOS package definitions: `Brewfile`
- Windows package definitions: `Scoopfile`

Edit the platform-specific file and rerun the platform install script to apply changes.
