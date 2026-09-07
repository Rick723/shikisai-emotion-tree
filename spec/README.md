# RSpec / FactoryBot

既存のDocker環境（Ruby 3.4.10 / Rails 8.1.3.1 / MySQL 8.4.11）を使用します。
`.env`の準備など、開発環境の初期設定はルートのREADMEを参照してください。

```sh
docker compose build web
docker compose run --rm -e RAILS_ENV=test web bin/rails db:create
docker compose run --rm web bundle exec rspec
```

ISSUE 14ではModel Spec / Request Specを追加しないため、通常の実行結果は
`0 examples, 0 failures`です。RailsとFactoryBotの読み込みは別途確認できます。

```sh
docker compose run --rm web bundle exec rspec --require rails_helper
docker compose run --rm web bin/rails runner -e test 'puts FactoryBot.factories.map(&:name)'
```

Factory一覧には`user`、`emotion`、`emotion_record`が表示されます。

## 設定

- `.rspec`は`spec_helper`を読み込みます。Railsに依存するSpecには`require "rails_helper"`を記述してください。
- Specの種別は`RSpec.describe User, type: :model`のように明示します。
- `rails_helper`はテスト環境の起動、production実行の拒否、テストスキーマの同期、トランザクションを設定します。
- Factory定義は`factory_bot_rails`が自動で読み込みます。`FactoryBot.find_definitions`の追加呼び出しは不要です。
- `rails_helper`を読み込んだRSpec内では`build(:user)`、`create(:user)`などの短縮記法が使えます。

## Factoryの準備範囲と未検証項目

属性名は既存のER図・DB設計仕様書に合わせています。

- `user`：名前、一意なメールアドレス、パスワードと確認値。
- `emotion`：小文字英字とアンダースコアの連番名（`emotion_a`等）、色、連番の表示順。固定8感情のSeedとは独立したテストデータです。
- `emotion_record`：User / EmotionのFactory参照、強さ・余韻、座標、日付。任意の時間・メモは必要なSpecで指定します。

現時点では3モデルと対応するテーブルが未実装のため、これらのFactoryの
`build` / `create` / `build_stubbed`によるモデル生成・保存や`FactoryBot.lint`の成功は検証できません。
Factory定義の読み込み成功は、モデルを生成・保存できたことを意味しません。

ISSUE 15〜17以降でModel・Migration・Association・Validation・`has_secure_password`を
実装した際に、Factoryの属性と整合させて生成・保存を検証してください。
本ISSUEでは、モデル本体・DBスキーマ・認証処理・固定8感情Seedを追加していません。
