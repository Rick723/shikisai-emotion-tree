# ISSUE 10 変更ファイルのコピーガイド

実装コミット: `d61c206` / 基準main: `3af1613`

コピー先のShikisaiリポジトリで作業してください。パスはリポジトリのルートからの相対パスです。新規ファイルは親ディレクトリを作成し、コードブロックの内容を全文保存してください。

## 1. config/routes.rb（1行追加）

既存の `Rails.application.routes.draw do ... end` の内側で、`get "privacy" ...` の次に以下を追加します。既存Routeは残してください。

```ruby
  get "tree" => "trees#show", as: :tree
```

## 2. app/controllers/trees_controller.rb（新規作成）

```ruby
class TreesController < ApplicationController
  def show
  end
end
```

## 3. app/views/trees/show.html.erb（新規作成）

```erb
<% content_for :title, "木を見る | Shikisai 〜感情の木〜" %>

<div class="tree-page">
  <main class="container tree-page__main">
    <header class="tree-page__heading">
      <h1 class="tree-page__title">木を見る</h1>
      <p class="tree-page__date"><time datetime="2026-07-26">2026年7月26日（日）</time></p>
      <p class="tree-page__notice">表示サンプル</p>
    </header>

    <div class="tree-page__content">
      <figure class="tree-visual">
        <div class="tree-visual__layers" role="img" aria-label="淡い緑の木に、うれしい・たのしい・感謝・悲しい・不安の5色を重ねた表示サンプル">
          <%= image_tag "tree_base.png", alt: "", class: "tree-visual__base", width: 1254, height: 1254 %>
          <%# ISSUE 10の固定色。実データではなく、ISSUE 26で実記録の描画へ差し替える。 %>
          <div class="tree-visual__sample-colors" aria-hidden="true"></div>
        </div>
      </figure>

      <section class="tree-legend" aria-labelledby="tree-legend-title">
        <h2 id="tree-legend-title" class="tree-legend__title">感情の色</h2>
        <%# 静的な凡例。Emotion / EmotionRecord / DBには接続しない。 %>
        <ul class="tree-legend__list">
          <% [
            ["うれしい", "#E6A6B6"],
            ["たのしい", "#FFD89A"],
            ["安心した", "#E9A76F"],
            ["感謝", "#BDE7C5"],
            ["悲しい", "#61749B"],
            ["イライラ", "#F28C6B"],
            ["不安", "#8585C7"],
            ["その他", "#D6D3CF"]
          ].each do |label, color| %>
            <li class="tree-legend__item">
              <span class="tree-legend__swatch" style="background-color: <%= color %>" aria-hidden="true"></span>
              <span><%= label %></span>
            </li>
          <% end %>
        </ul>
      </section>
    </div>
  </main>

  <%= render "shared/bottom_nav" %>
</div>
```

## 4. app/views/shared/_bottom_nav.html.erb（新規作成）

```erb
<nav class="bottom-nav" aria-label="メインナビゲーション">
  <ul class="container bottom-nav__list">
    <li>
      <span class="bottom-nav__item bottom-nav__item--pending">
        <svg class="bottom-nav__icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <path d="m14 5 5 5M4 20l5-1L21 7l-4-4L5 15Z" />
        </svg>
        <span>今日を彩る</span>
        <span class="status-label">準備中</span>
      </span>
    </li>
    <li>
      <span class="bottom-nav__item bottom-nav__item--pending">
        <svg class="bottom-nav__icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <rect x="3" y="5" width="18" height="16" rx="2" />
          <path d="M7 3v4m10-4v4M3 11h18m-14 4h2m6 0h2" />
        </svg>
        <span>カレンダー</span>
        <span class="status-label">準備中</span>
      </span>
    </li>
    <li>
      <%= link_to tree_path, class: "bottom-nav__item", aria: { current: ("page" if current_page?(tree_path)) } do %>
        <svg class="bottom-nav__icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <path d="M12 16v5m-4 0h8M7 17a4 4 0 0 1-3-7 4 4 0 0 1 4-5 4 4 0 0 1 8 0 4 4 0 0 1 4 5 4 4 0 0 1-3 7Z" />
        </svg>
        <span>木を見る</span>
      <% end %>
    </li>
    <li>
      <span class="bottom-nav__item bottom-nav__item--pending">
        <svg class="bottom-nav__icon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
          <circle cx="12" cy="7" r="4" />
          <path d="M4 21v-2a8 8 0 0 1 16 0v2" />
        </svg>
        <span>マイページ</span>
        <span class="status-label">準備中</span>
      </span>
    </li>
  </ul>
</nav>
```

## 5. app/assets/stylesheets/tree.css（新規作成）

```css
/* Tree page: fixed sample only; no record data or interactive drawing. */

.tree-page {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
  min-height: 100svh;
}

.tree-page__main {
  flex: 1;
  padding-block: 48px 56px;
}

.tree-page__heading {
  text-align: center;
}

.tree-page__title {
  margin: 0;
  font-family: var(--font-serif);
  font-size: 2rem;
  font-weight: 500;
  letter-spacing: 0.06em;
  line-height: 1.45;
}

.tree-page__date {
  margin: 16px 0 0;
}

.tree-page__notice {
  margin: 6px 0 0;
  color: var(--color-text-muted);
  font-size: 0.8125rem;
}

.tree-page__content {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 280px;
  align-items: center;
  gap: 48px;
  margin-top: 24px;
}

.tree-visual {
  width: min(100%, 640px);
  margin: 0 auto;
}

.tree-visual__layers {
  position: relative;
}

.tree-visual__base {
  width: 100%;
}

/* Five fixed washes, clipped to the base silhouette. Remove in ISSUE 26. */
.tree-visual__sample-colors {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background:
    radial-gradient(ellipse 24% 23% at 32% 32%, #E6A6B6e6 15%, #E6A6B600 100%),
    radial-gradient(ellipse 21% 19% at 60% 24%, #FFD89Ab3 15%, #FFD89A00 100%),
    radial-gradient(ellipse 20% 17% at 70% 48%, #BDE7C5b3 15%, #BDE7C500 100%),
    radial-gradient(ellipse 12% 11% at 27% 57%, #61749B80 10%, #61749B00 100%),
    radial-gradient(ellipse 11% 12% at 70% 62%, #8585C766 10%, #8585C700 100%);
  mask: url("tree_base.png") center / 100% 100% no-repeat;
}

.tree-legend {
  padding: 28px 24px;
  border: 1px solid var(--color-border);
  border-radius: calc(var(--border-radius) + 10px);
  background-color: var(--color-surface);
}

.tree-legend__title {
  margin: 0 0 24px;
  font-family: var(--font-serif);
  font-size: 1.25rem;
  font-weight: 500;
}

.tree-legend__list {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 24px 16px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.tree-legend__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  font-size: 0.875rem;
  text-align: center;
  overflow-wrap: anywhere;
}

.tree-legend__swatch {
  width: 24px;
  height: 24px;
  border: 1px solid rgb(52 57 52 / 15%);
  border-radius: 50%;
}

@media (max-width: 1060px) {
  .tree-page__content {
    grid-template-columns: minmax(0, 1fr) 240px;
    gap: 24px;
  }
}

@media (max-width: 720px) {
  .tree-page__main {
    padding-block: 32px;
  }

  .tree-page__title {
    font-size: 1.75rem;
  }

  .tree-page__content {
    grid-template-columns: minmax(0, 1fr);
    gap: 24px;
  }

  .tree-visual {
    max-width: 440px;
  }

  .tree-legend {
    padding: 24px 12px;
  }

  .tree-legend__title {
    text-align: center;
  }

  .tree-legend__list {
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 20px 8px;
  }

  .tree-legend__item {
    font-size: 0.8125rem;
  }
}
```

## 6. app/assets/stylesheets/bottom_nav.css（新規作成）

```css
/* Shared navigation; kept in normal flow so wrapped text cannot hide content. */

.bottom-nav {
  border-top: 1px solid var(--color-border);
  background-color: var(--color-surface);
  padding-block: 12px calc(12px + env(safe-area-inset-bottom, 0px));
}

.bottom-nav__list {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  max-width: 800px;
  padding: 0;
  margin-block: 0;
  list-style: none;
}

.bottom-nav__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 96px;
  height: 100%;
  padding: 8px;
  border-radius: var(--border-radius);
  font-size: 0.9375rem;
  text-align: center;
  text-decoration: none;
  overflow-wrap: anywhere;
}

.bottom-nav__item[aria-current="page"] {
  background-color: #eef1e9;
  color: var(--color-primary);
  font-weight: 700;
  text-decoration: underline;
  text-underline-offset: 4px;
}

.bottom-nav__item--pending {
  color: var(--color-text-muted);
}

.bottom-nav__icon {
  width: 24px;
  height: 24px;
  flex-shrink: 0;
  fill: none;
  stroke: currentcolor;
  stroke-width: 1.5;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.bottom-nav__item[aria-current="page"] .bottom-nav__icon {
  stroke-width: 2;
}

@media (max-width: 720px) {
  .bottom-nav__item {
    padding-inline: 4px;
    font-size: 0.75rem;
  }
}
```

## 7. app/assets/images/tree_base.png（画像をコピー）

[基礎木PNGを開く](app/assets/images/tree_base.png)

PNGはバイナリファイルのため、コードブロックの貼り付けでは作成できません。以下のコピー元から、普段の開発リポジトリの `app/assets/images/tree_base.png` へファイルをコピーしてください。画像は1254×1254pxの透過PNGです。

コピー元:
```text
C:\Users\rikut\Documents\Codex\2026-09-06\issue-10-shikisai-issue-10-issue\app\assets\images\tree_base.png
```

Windows PowerShellを使う場合は、`$targetRepo` をコピー先リポジトリの実際の絶対パスに置き換えて実行します。

```powershell
$targetRepo = 'C:\実際のパス\shikisai-emotion-tree'
Copy-Item -LiteralPath 'C:\Users\rikut\Documents\Codex\2026-09-06\issue-10-shikisai-issue-10-issue\app\assets\images\tree_base.png' -Destination (Join-Path $targetRepo 'app/assets/images/tree_base.png')
```

## コピー後の確認

既存のapplication layoutが `stylesheet_link_tag :app` でCSSを読み込む構成なので、layoutの変更やCSSの追加読み込み設定は不要です。Gemfile・DB・JavaScriptも変更しません。

```sh
git status --short
git diff --check
docker compose exec web bin/rails routes -g tree
docker compose exec web bin/rails zeitwerk:check
```

Rails起動後に `/tree` を開き、1440px・1024px・390px付近で木、5色のサンプルレイヤー、8感情の凡例、ボトムナビを確認してください。未実装の3項目は「準備中」の非リンクです。

固定日付・固定色は表示確認用です。Emotion / EmotionRecord / DBへの接続、日付切替、認証制御、記録保存、モーダル、後続画面の実装は含みません。
