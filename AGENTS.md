# Repository guidance

- 変更前に Git の作業ツリーとステージを確認し、既存の作業を保護する。
- install/uninstall、README、`.githooks/pre-commit`、グローバル `core.hooksPath` の挙動を同期する。
- Codex の設定・フックを変えるときは README に利用者への影響を記載する。
- 大量出力は context-mode で絞り、実装後は関連する構文検査・テストと差分を確認する。未実行項目は区別する。
