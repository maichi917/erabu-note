# 共有機能 実装計画（シェア：公開・フォロー・さがす・保存）

> **ステータス: 計画**（2026-11-03）
> ステップ1から順に実装し、ステップごとに本番へ出す。

## 目的

感想を公開し、好みが近い人の感想も「えらぶ」ときの材料にできるようにする。
フォローすることで、「この人が気に入っているもの」を参考に選べるようにする。

アプリを **「マイノート」**（自分だけの記録。今のアプリ）と **「シェア」**（公開の場所）の2つに分ける。
参考にしたアプリは、ブクログ（自分の本棚と、みんなの感想）と Strava（自分の記録と、フォローした人のフィード）。

アイテムは共有しない。共有するのは感想だけで、アイテムの名前・ブランド・画像は一緒に出す。

## 画面イメージ

<table width="100%">
<tr><th width="50%">① ホーム</th><th width="50%">② 感想を書く</th></tr>
<tr><td align="center"><img src="images/sharing-01-home.png" width="300" alt="① ホーム"></td><td align="center"><img src="images/sharing-02-review.png" width="300" alt="② 感想を書く"></td></tr>
<tr><td>現在のホーム画面のタブの右端に、線で区切って「シェア」を追加。フォロー中の人の新しい感想があると赤い点を表示。</td><td>「シェアする」スイッチを追加。シェア画面に関するもののテーマカラーはローズに統一。星評価がないと公開はできない。ゲストには出さない。</td></tr>
<tr><th width="50%">③ ニックネームの確認</th><th width="50%">④ フォロー中</th></tr>
<tr><td align="center"><img src="images/sharing-03-confirm.png" width="300" alt="③ ニックネームの確認"></td><td align="center"><img src="images/sharing-04-following.png" width="300" alt="④ フォロー中"></td></tr>
<tr><td>シェア中の感想が0件の人が、②でシェアして保存した時に出す。ニックネームを確認してもらう（既に名前を登録済みのユーザーがいるため）。</td><td>ヘッダーにロゴ＋「シェア」の印。下のタブもシェア用に変わる。フォローしている人がシェアした感想が、新しい順に並ぶ。ここを開くと赤い点が消える。ブックマークもできる</td></tr>
<tr><th width="50%">⑤ さがす</th><th width="50%">⑥ 他の人のプロフィール</th></tr>
<tr><td align="center"><img src="images/sharing-05-search.png" width="300" alt="⑤ さがす"></td><td align="center"><img src="images/sharing-06-profile.png" width="300" alt="⑥ 他の人のプロフィール"></td></tr>
<tr><td>シェアされている全員の感想から、商品名で検索できる。</td><td>名前を押すとユーザーのプロフィールが開ける。フォローするボタンはローズ。ログインしている人だけが見られる（ゲストは見本のユーザーを出す）。</td></tr>
<tr><th width="50%">⑦ マイページ</th><th width="50%">⑧ 保存した感想</th></tr>
<tr><td align="center"><img src="images/sharing-07-mypage.png" width="300" alt="⑦ マイページ"></td><td align="center"><img src="images/sharing-08-saved.png" width="300" alt="⑧ 保存した感想"></td></tr>
<tr><td>シェア画面の中の自分のページ。名前の横の「✎ 編集」で、ニックネームを変更。数を押すとフォロー／フォロワー一覧。</td><td>ブックマークした感想を確認できる。自分だけが見られる。書いた人がシェアをやめたら、一覧に表示させない。</td></tr>
</table>

シェアの画面は、ロゴの横に「シェア」の札を出し、テーマカラーをローズにする。下のタブは フォロー中／さがす／マイページ ｜ ノートへ。

## 動線

![共有機能の動線](images/sharing-flow.png)

## 決定事項

| 論点 | 決定内容 |
|---|---|
| 公開 | 感想ごとにスイッチ。**初期値は非公開**。星評価がないと公開できない |
| 画面の言葉 | 「シェアする」「シェア中」を使い、「公開」は使わない（「シェアに公開」だと意味が重なるため） |
| ニックネーム | 今の `name` を使う（本名で登録している人もいるため、初めて公開するときに確認） |
| 見られる人 | **ログインしている人だけ** |
| ゲスト | **見本のユーザーの感想だけ**を見せる（ゲストは誰でも入れるため）。公開はできない |
| 公開する情報 | 商品名・ブランド名・画像・星評価・感想・手放したかどうか |
| フォロー | 相手の許可は不要 |
| 並び順 | 公開した日時、または公開中に感想を更新した日時の新しい順 |
| 赤い点 | シェアを最後に開いた時刻より後に、フォロー中の人の感想が出ていれば付ける |
| 保存 | 自分だけが見られる。書いた人が非公開にしたら一覧に出さない |

## 実装の順番

| ステップ | 中身 | issue |
|---|---|---|
| 1 | 利用規約の更新、公開スイッチ、ニックネームの確認、シェアの部屋（ヘッダー・下のタブ）、プロフィール／マイページ | #375、#376 |
| 2 | フォロー、フォロー／フォロワー一覧、フォロー中、赤い点 | #377 |
| 3 | さがす、ゲスト用の見本ユーザー | #378 |
| 4 | 保存（ブックマーク） | #400 |

利用規約（#375）は、公開できるようになる前に必要なので、ステップ1の最初にやる。

## データベースの変更

カラム・テーブルを足すだけ。公開スイッチの初期値は非公開なので、既存ユーザーのデータは勝手に公開されない。

| テーブル | 追加するもの | ステップ |
|---|---|---|
| items | `public`（boolean、default: false）、`published_at`（datetime） | 1 |
| follows（新規） | `follower_id`、`followed_id`（どちらも users） | 2 |
| users | `share_seen_at`（datetime。赤い点用） | 2 |
| bookmarks（新規） | `user_id`、`item_id` | 4 |

- 見本のユーザーは、ゲストと同じくメールアドレスのドメインで見分ける（カラムは足さない）
- ユーザーやアイテムを消したら、`follows`・`bookmarks` も一緒に消す

```mermaid
erDiagram
    users ||--o{ items : ""
    users ||--o{ categories : ""
    categories |o--o{ items : ""
    users ||--o{ follows : "follower_id"
    users ||--o{ follows : "followed_id"
    users ||--o{ bookmarks : ""
    items ||--o{ bookmarks : ""

    users {
        uuid id PK
        string name "ニックネーム"
        datetime share_seen_at "追加"
    }
    categories {
        uuid id PK
        uuid user_id FK
        string name
    }
    items {
        uuid id PK
        uuid user_id FK
        uuid category_id FK
        string name
        integer rating
        text review
        boolean public "追加"
        datetime published_at "追加"
    }
    follows {
        uuid id PK
        uuid follower_id FK
        uuid followed_id FK
    }
    bookmarks {
        uuid id PK
        uuid user_id FK
        uuid item_id FK
    }
```

`follows`（users と users をつなぐ）と `bookmarks`（users と items をつなぐ）は、新しく追加する中間テーブル。items の価格・容量・メモなど、今回変えないカラムは省略。

## 実装で気をつけること

- 公開のルール（星評価がないものは公開できない、星評価を消したら非公開に戻す、`published_at` の更新）は model にまとめる
- シェアに出す感想の条件は model の1か所にまとめ、3つの画面で使い回す（ゲストには見本だけを表示、本物のユーザーには本物の感想だけを表示）
- 公開する項目は1つの partial にまとめ、メモなど不要な情報を出さない
