# Shikisai 〜感情の木〜 dbdiagram.io用DBMLシート 最終版

- 作成日：2026-08-11 JST
- 対象：Shikisai 〜感情の木〜 MVP
- ステータス：最終版
- 対応仕様書：`Shikisai_ER図・データベース設計仕様書_最終版.md`

---

## 1. dbdiagram.ioでの使い方

1. dbdiagram.ioで新しいDiagramを作成する。
2. エディター内の初期コードを削除する。
3. 次章の`dbml`コードブロック全体をコピーして貼り付ける。
4. `users`、`emotions`、`emotion_records`の3テーブルが表示されることを確認する。
5. `emotion_records.user_id → users.id`と`emotion_records.emotion_id → emotions.id`の2本のリレーションが生成されることを確認する。

本DBMLはRails 7.2、MySQL 8.4.11、InnoDBを前提としたMVP最終版である。

---

## 2. 貼り付け用の完全なDBML

```dbml
Project shikisai {
  database_type: 'MySQL'
  Note: 'Shikisai 〜感情の木〜 MVP最終版。Rails 7.2、MySQL 8.4.11、InnoDB、mysql2を前提とする3テーブル構成。'
}

Table users {
  id bigint [pk, increment, not null, note: '主キー。自動採番。']
  name varchar(20) [not null, note: 'ユーザー名。最大20文字。']
  email varchar(255) [not null, note: 'ログイン用メールアドレス。小文字へ正規化して保存する。']
  password_digest varchar(255) [not null, note: 'has_secure_password / bcryptのダイジェスト。平文パスワードは保存しない。']
  password_reset_token_digest varchar(255) [note: 'パスワード再設定用トークンのダイジェスト。生トークンは保存しない。未発行時はNULL。']
  password_reset_expires_at datetime(6) [note: 'パスワード再設定URLの有効期限。発行から30分。未発行時はNULL。']
  created_at datetime(6) [not null, note: 'Railsが管理する作成日時。']
  updated_at datetime(6) [not null, note: 'Railsが管理する更新日時。']

  indexes {
    email [unique, name: 'index_users_on_email']
    password_reset_token_digest [unique, name: 'index_users_on_password_reset_token_digest']
  }

  Note: 'ユーザーのアカウント・認証・パスワード再設定情報を保存する。'
}

Table emotions {
  id bigint [pk, increment, not null, note: '主キー。自動採番。']
  name varchar(30) [not null, note: '感情の英語コード。小文字英字と単語間アンダースコアのみ。']
  color_code varchar(7) [not null, note: '感情の表示色。#＋6桁16進数。色の重複は許可する。']
  display_order integer [not null, note: 'UI上の表示順。1以上。']
  created_at datetime(6) [not null, note: 'Railsが管理する作成日時。']
  updated_at datetime(6) [not null, note: 'Railsが管理する更新日時。']

  indexes {
    name [unique, name: 'index_emotions_on_name']
    display_order [unique, name: 'index_emotions_on_display_order']
  }

  checks {
    `display_order >= 1` [name: 'chk_emotions_display_order_positive']
  }

  Note: 'MVPで使用する固定8種類の感情マスター。日本語表示名はI18nで管理し、categoryは持たない。'
}

Table emotion_records {
  id bigint [pk, increment, not null, note: '主キー。自動採番。']
  user_id bigint [not null, note: '記録の所有ユーザー。users.idを参照する。']
  emotion_id bigint [not null, note: '感情の種類。emotions.idを参照する。']
  strength integer [not null, note: '感情の強さ＝色の広がり。0〜100。']
  afterglow integer [not null, note: '感情の余韻＝色の濃さ・透明度。0〜100。']
  position_x decimal(5,2) [not null, note: '木の葉領域内のX座標。0.00〜100.00%。']
  position_y decimal(5,2) [not null, note: '木の葉領域内のY座標。0.00〜100.00%。']
  felt_on date [not null, note: 'ユーザーが感情を感じた日付。']
  felt_at time [note: 'ユーザーが感情を感じた時間。任意。未設定時はNULLで、現在時刻を自動補完しない。']
  memo text [note: '任意メモ。Railsモデル・フォーム側で最大200文字を検証する。']
  created_at datetime(6) [not null, note: 'DBへ登録した日時。']
  updated_at datetime(6) [not null, note: '最終更新日時。']

  indexes {
    emotion_id [name: 'index_emotion_records_on_emotion_id']
    (user_id, felt_on) [name: 'index_emotion_records_on_user_id_and_felt_on']
  }

  checks {
    `strength BETWEEN 0 AND 100` [name: 'chk_emotion_records_strength_range']
    `afterglow BETWEEN 0 AND 100` [name: 'chk_emotion_records_afterglow_range']
    `position_x BETWEEN 0.00 AND 100.00` [name: 'chk_emotion_records_position_x_range']
    `position_y BETWEEN 0.00 AND 100.00` [name: 'chk_emotion_records_position_y_range']
  }

  Note: 'ユーザーが感じた感情を一件単位で保存する。同じユーザー・同じ日付に複数行を保存できる。'
}

Ref fk_emotion_records_user: emotion_records.user_id > users.id [delete: cascade, update: no action]
Ref fk_emotion_records_emotion: emotion_records.emotion_id > emotions.id [delete: restrict, update: no action]

records emotions(name, color_code, display_order) {
  'happy', '#E6A6B6', 1
  'fun', '#FFD89A', 2
  'relieved', '#E9A76F', 3
  'grateful', '#BDE7C5', 4
  'sad', '#61749B', 5
  'irritated', '#F28C6B', 6
  'anxious', '#8585C7', 7
  'other', '#D6D3CF', 8
}
```

---

## 3. 3テーブルの関係と多重度の読み方

```text
users    1 ─── 0..* emotion_records
emotions 1 ─── 0..* emotion_records
```

- 一人のユーザーは0件以上の感情記録を持てる。
- 一件の感情記録は必ず一人のユーザーに属する。
- 一種類の感情は0件以上の感情記録から参照される。
- 一件の感情記録は必ず一種類の感情を参照する。

外部キー：

```text
emotion_records.user_id    > users.id
emotion_records.emotion_id > emotions.id
```

削除規則：

- `users`削除：関連`emotion_records`を`CASCADE`で削除
- `emotions`削除：参照中なら`RESTRICT`で拒否

---

## 4. 初期感情マスター8件

| display_order | name | 日本語表示名（I18n） | color_code |
|---:|---|---|---|
| 1 | `happy` | うれしい | `#E6A6B6` |
| 2 | `fun` | たのしい | `#FFD89A` |
| 3 | `relieved` | 安心した | `#E9A76F` |
| 4 | `grateful` | 感謝 | `#BDE7C5` |
| 5 | `sad` | 悲しい | `#61749B` |
| 6 | `irritated` | イライラ | `#F28C6B` |
| 7 | `anxious` | 不安 | `#8585C7` |
| 8 | `other` | その他 | `#D6D3CF` |

DBMLの`records emotions(name, color_code, display_order)`にも同じ8件を記載している。日本語表示名はI18n管理のためDBカラムには含めない。

---

## 5. DBMLに反映した制約・インデックス一覧

### 5.1 UNIQUEインデックス

| テーブル | インデックス | カラム |
|---|---|---|
| `users` | `index_users_on_email` | `email` |
| `users` | `index_users_on_password_reset_token_digest` | `password_reset_token_digest` |
| `emotions` | `index_emotions_on_name` | `name` |
| `emotions` | `index_emotions_on_display_order` | `display_order` |

### 5.2 非UNIQUEインデックス

| テーブル | インデックス | カラム |
|---|---|---|
| `emotion_records` | `index_emotion_records_on_emotion_id` | `emotion_id` |
| `emotion_records` | `index_emotion_records_on_user_id_and_felt_on` | `(user_id, felt_on)` |

`emotion_records.user_id`だけの単独インデックスと、`(user_id, felt_on, emotion_id)`の3列複合インデックスは作成しない。

`(user_id, felt_on)`は同一日に複数の感情記録を許可するため、UNIQUEではない。

### 5.3 CHECK制約

| テーブル | 制約名 | 条件 |
|---|---|---|
| `emotions` | `chk_emotions_display_order_positive` | `display_order >= 1` |
| `emotion_records` | `chk_emotion_records_strength_range` | `strength BETWEEN 0 AND 100` |
| `emotion_records` | `chk_emotion_records_afterglow_range` | `afterglow BETWEEN 0 AND 100` |
| `emotion_records` | `chk_emotion_records_position_x_range` | `position_x BETWEEN 0.00 AND 100.00` |
| `emotion_records` | `chk_emotion_records_position_y_range` | `position_y BETWEEN 0.00 AND 100.00` |

### 5.4 外部キー

| Ref名 | 外部キー | 参照先 | DELETE | UPDATE |
|---|---|---|---|---|
| `fk_emotion_records_user` | `emotion_records.user_id` | `users.id` | cascade | no action |
| `fk_emotion_records_emotion` | `emotion_records.emotion_id` | `emotions.id` | restrict | no action |

---

## 6. DBMLではなくRails側で保証するバリデーション

| 対象 | Rails側の保証 |
|---|---|
| `users.name` | presence、最大20文字 |
| `users.email` | presence、メール形式、小文字正規化、uniqueness |
| パスワード | `has_secure_password`による認証・確認 |
| `emotions.name` | `/\A[a-z]+(?:_[a-z]+)*\z/`、uniqueness |
| `emotions.color_code` | `/\A#[0-9A-Fa-f]{6}\z/` |
| `emotion_records.memo` | 最大200文字 |
| `felt_at` | 任意入力。未設定時は`nil`のまま保存 |

`memo`の200文字上限はDB CHECKではなくRailsモデル・フォーム側で検証する。

---

## 7. Railsアソシエーション対応表

| DBの関係 | Railsモデル側 |
|---|---|
| `users` 1 : N `emotion_records` | `User has_many :emotion_records, dependent: :destroy` |
| `emotions` 1 : N `emotion_records` | `Emotion has_many :emotion_records, dependent: :restrict_with_error` |
| `emotion_records.user_id → users.id` | `EmotionRecord belongs_to :user` |
| `emotion_records.emotion_id → emotions.id` | `EmotionRecord belongs_to :emotion` |

```ruby
class User < ApplicationRecord
  has_many :emotion_records, dependent: :destroy
end

class Emotion < ApplicationRecord
  has_many :emotion_records, dependent: :restrict_with_error
end

class EmotionRecord < ApplicationRecord
  belongs_to :user
  belongs_to :emotion
end
```

---

## 8. MVPで図に含めないテーブル・カラム

### 8.1 含めないテーブル

- 日付テーブル
- カレンダーテーブル
- 木テーブル
- 日別記録・日別集計テーブル
- 利用規約テーブル
- プライバシーポリシーテーブル
- セッション専用テーブル
- パスワード再設定専用テーブル

### 8.2 含めないカラム

- `emotion_records.emotion_type`
- `emotions.category`
- 感情マスターの日本語表示名
- `emotion_records.deleted_at`
- `users.password_updated_at`
- `users.bio`
- `users.introduction`
- `users.profile`
- `intensity`
- `pos_x`
- `pos_y`
- `recorded_on`

---

## 9. 旧DBMLからの主な変更点

| 旧DBML | 最終版DBML |
|---|---|
| 2テーブル | 3テーブル |
| PostgreSQL | MySQL |
| `emotion_type` | `emotion_id` FK |
| 感情マスターなし | `emotions`固定マスター追加 |
| 強さ・余韻1〜5 | 0〜100 |
| 座標0〜1 | 0.00〜100.00 |
| `decimal(6,5)` | `decimal(5,2)` |
| `timestamp` | `datetime(6)` |
| `users.name varchar(50)` | `varchar(20)` |
| `user_id`単独インデックスあり | なし |
| 感情種類の3列複合インデックス候補 | なし |
| ユーザーFKのみ | ユーザーFK＋感情FK |
| 感情削除規則なし | `delete: restrict` |
| 初期感情データなし | `records emotions(...)`で8件記載 |

---

## 10. 最終整合性チェック結果

| チェック項目 | 結果 |
|---|---|
| `users`・`emotions`・`emotion_records`の3テーブル | OK |
| `emotion_type`が残っていない | OK |
| `emotion_id`が`emotions.id`を参照 | OK |
| `emotions`削除規則がRESTRICT | OK |
| `users`削除規則がCASCADE | OK |
| `strength`・`afterglow`が0〜100 | OK |
| `position_x`・`position_y`が0.00〜100.00 | OK |
| `felt_at`がNULL可 | OK |
| `emotion_id`単独インデックス | OK |
| `(user_id, felt_on)`が非UNIQUE | OK |
| 初期感情8件のコード・色・表示順 | OK |
| 日本語表示名をI18n管理 | OK |
| PostgreSQL・1〜5・0〜1等の旧案が現行定義に残っていない | OK |
| 重複Refなし | OK |
| 重複Indexなし | OK |
| 未定義カラム参照なし | OK |

### DBML構文について

DBML公式構文で、`Project`、`Table`、`indexes`、`checks`、名前付き`Ref`の削除・更新規則、および`records`によるサンプルデータ定義が現行構文として提供されていることを確認したうえで記述している。

---

## 11. 根拠資料

- `Shikisai_ER図・データベース設計仕様書_最終版.md`
- `Shikisai_MVP_画面構成・画面遷移仕様書(1).md`
- `08-Shikisai_ER-.md`（旧案。構成・説明方法のみ参照）
- `09-Shikisai_dbdiagram.io-_DBML-.md`（旧案。構成・説明方法のみ参照）
- DBML公式Syntax Documentation（Project / Table / Check / Index / Ref / Records構文）
