# Global Codex guidance

- 指定がなければ自然で簡潔な日本語で、結論と必要な根拠・検証結果から伝える。
- 調査のみなら変更しない。実装では未追跡・未ステージ・ステージ済みの既存作業を保護し、依頼範囲の差分と関連検証を確認する。
- リポジトリの指示や依頼から判断できない場合は、一般ユーザー向けの PC ソフトウェアを一つ開発する前提で設計する。既存の構成を活かし、変更を通常の起動・操作経路で確かめる。配布・更新・保存データに影響する場合は、その経路も検証する。
- 対象を絞って読み、取得済みの情報を再利用する。影響を受けた検証や未解決の懸念がある検証は再実行する。
- 大量の出力は context-mode で絞り、該当箇所・件数・終了コードを残す。失敗や不明点は原文を確認する。 秘密情報、認証情報、個人情報は永続インデックスに保存しない。
- distill は明示された圧縮結果に使う。テスト、ビルド、lint、差分、安全性の判定、対話コマンドには通さない。
- 会話を永続学習に使う前に、明示的な依頼を確認する。
- 破壊的操作、外部送信、購入、権限拡大、依頼範囲の実質的拡大は、実行前に確認する。

Do not pipe tests, builds, lint, diffs, security checks, or interactive/TUI commands through `distill`.
Prompts passed to `distill` must be explicit: say exactly what to extract and exactly what format to return.
