# Repository guidance

- このリポジトリはマシン単位のdotfilesを管理する。変更前にdirty/staged/untracked状態を確認し、既存作業を保護する。
- install/uninstallスクリプト、README、`.githooks/pre-commit`、グローバル`core.hooksPath`の挙動を同期する。
- `.codex/hooks.json`と`.codex/config.toml`は外観ではなく動作変更として扱い、READMEへ利用者向けの影響を記載する。
- 大量入力はcontext-modeで処理し、distillは明示依頼または最終要約だけに使う。
- 実装後は関連する構文検査・テストとdiff確認を行い、外部CIや未実行項目を区別する。
