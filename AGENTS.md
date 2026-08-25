# AGENTS.md

## プロジェクト概要
Rails 8.1 + PostgreSQL の在庫管理・レビューアプリ。認証は Devise、CSS は Tailwind CSS。Docker Compose で開発する。

## コマンド
- 起動: `docker compose up`
- 停止: `docker compose down`
- DBマイグレーション: `docker compose exec web bin/rails db:migrate`
- テスト: `docker compose exec web bin/rails test`
- テスト（単一）: `docker compose exec web bin/rails test test/models/item_test.rb`
- Railsコンソール: `docker compose exec web bin/rails console`
- Rubocop（コードスタイルチェック）: `docker compose exec web bundle exec rubocop`
- Rubocop（自動修正）: `docker compose exec web bundle exec rubocop -a`

## コードスタイル
- Rails の標準的な MVC 構成に従う
- 変数名・メソッド名・モデル名・カラム名は英語、画面文言とコメントは日本語
- controller は薄くし、在庫や使用履歴の判定ロジックは model に寄せる

## アーキテクチャ
- モデルは `app/models/`
- コントローラは `app/controllers/`
- ビューは `app/views/`
- マイグレーションは `db/migrate/`
- テストは `test/`
- 主キーは UUID を使う（`id: :uuid, default: -> { "gen_random_uuid()" }`）。新規テーブルもこの形式に合わせる

## アイテムの状態管理方針
- `items` が状態を直接持つ（評価・レビューの履歴テーブルは持たない）
- `favorite`: よく使うもの、`low_stock_flagged`: なくなりそう、`archived`: 手放した
- `rating`/`review` は常に上書き。過去の使用サイクルごとの履歴は持たない
- 「手放す」は削除ではなくアーカイブ（`archived: true`）。手放す際は `favorite`/`low_stock_flagged` を自動でオフにする

## 権限
コマンドの自動実行可否は `.claude/settings.json` の `allow`/`ask`/`deny` で管理する。目安は以下の通り。
- 自動実行OK: テスト、Lint、読み取り系コマンド、開発DBへの `db:migrate`
- 確認が必要: パッケージ追加、`git push`、`git checkout`/`restore`/`reset`/`clean`、PR/issueのマージ・作成・クローズ、本番DBへの書き込み
- 拒否（確認なしでブロック）: `git push --force`、`git reset --hard`、`git clean -f`、`docker compose down -v` など、一度実行すると取り返しがつかない破壊的コマンド。git管理外のファイルは消すと戻せない

## 調査するときの原則
- 原因が分かるまで、削除・上書き・再実行を「試して」はいけない。まず読んで、比較して、事実を確定させる
- 症状が出た直前の操作をまず疑う（自分の操作も含めて）

## 困ったら
要件が曖昧な場合は推測で大きな変更をせず、質問すること。

## AI Response Rules

- ユーザーが明示的に実装を依頼するまで、コード変更を行わない
- 初学者向けに説明する
- 現在地を毎回説明する
- 実装に入る前にこれから触るファイル（DB/model/controller/view/config等）を明示する
- コード提示前に目的を説明する
- 説明はなるべく「現在地 → 目的 → 触るファイル → 変更内容 → 確認結果 → 次にやること」の順で行う
- 実装後は、変更したファイルごとに「何を変えたか」「なぜ必要か」を説明する
- 設定確認やテストを行った場合は、実行したコマンドと確認できた内容を説明する
- 複数ファイルにまたがる変更は、一気に実装せず、小さなステップに分ける
- issue対応では、最初に issue の内容を要約し、作業ステップに分解して提示する
- エラーが発生した場合は、原因を明確にし、必要に応じてエラー文の解説をする
- 途中で方針が変わった場合は、変更前後の違いと理由を説明する
- 推測で大規模な変更をしない
- 修正後は「何ができるようになったか」と「次にやること」を説明する
