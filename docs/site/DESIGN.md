# 誠実QRリーダー 公開サイト 設計書（Step 1）

> ステータス: **確定・実装済み（2026-10-24）**。§9 は 1〜3 を推奨案で確定（提供者 seventhwell、URL は workers.dev）。問い合わせ先メールアドレスのみ未確定（§10）。
> 公開中: https://seijitsuqr.kajisho5.workers.dev
> デザイン: `docs/site/01_mobile.svg`（スマートフォン幅 390pt：トップ・プライバシーポリシー・サポート・ダークモード）と `docs/site/02_desktop.svg`（1280px：トップ・プライバシーポリシー）。生成元は `docs/site/src/pages.js`（`node docs/site/src/pages.js`）。

## 1. 目的と要件

App Store Connect に登録する URL のうち、今は仮の `example.com` になっているものを、本物の公開ページにする。

| URL | App Store Connect での扱い | 一次情報 |
|---|---|---|
| プライバシーポリシー | **iOS アプリでは必須** | [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)「Required for iOS and macOS apps」 |
| サポート URL | **必須**。連絡先（法律で求められる場合は住所・メール・電話）にたどり着けること | [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information)「This property is required」 |
| マーケティング URL | 任意 | 同上（required の記載なし） |
| 利用規約（EULA） | 任意。Apple の標準 EULA が全地域に適用される | [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)「Apple provides a standard EULA」 |

アプリは設定画面からプライバシーポリシーと利用規約を開く（`AppConstants.privacyPolicyURL` / `termsOfUseURL`）。そのため利用規約も公開する。

**非機能要件**
- アプリと同じ方針にする：広告なし、アクセス解析なし、Cookie なし、外部フォントや CDN を読み込まない。
- JavaScript が無効でも全文が読める（静的 HTML を事前生成する）。審査担当者や古いブラウザでも確実に表示される。
- 日本語のみ（アプリが日本語のみのため）。ダークモードに対応する。WCAG 2.1 AA のコントラストを満たす。
- スマートフォン幅（360px〜）とデスクトップ幅（〜1280px）。横スクロールを出さない。

## 2. ページ構成

| パス | ページ | 役割 |
|---|---|---|
| `/` | トップ | アプリの紹介（3 つの約束、機能、価格）。マーケティング URL として使う |
| `/privacy/` | プライバシーポリシー | §6.1 の本文 |
| `/terms/` | 利用規約 | §6.2 の本文 |
| `/support/` | サポート | よくある質問と問い合わせ先。サポート URL として使う |
| `/404.html` | 見つからない | トップへの導線 |

全ページで共通のヘッダー（アプリ名とナビゲーション）とフッター（各ページへのリンク、提供者名、著作権表示）を使う。

## 3. 技術スタック

| 項目 | 採用 | 理由 |
|---|---|---|
| フレームワーク | Next.js 16（App Router）+ React 19 + TypeScript | 指定の React ベース。`output: "export"` で全ページを静的 HTML として事前生成する |
| スタイル | Tailwind CSS 4 | 色と余白をデザイントークン（CSS 変数）で管理し、ダークモードを `prefers-color-scheme` で切り替える |
| フォント | 端末のシステムフォント（`-apple-system`, `Hiragino Sans`, `Noto Sans JP`, `sans-serif`） | 外部フォントを読み込まない |
| ホスティング | Cloudflare Workers の静的アセット（`wrangler deploy`） | アカウントに Workers の利用実績がある。Pages プロジェクトは 0 件 |
| バージョン | 実装時に npm の最新安定版を固定する（確認時点: next 16.4.3 / react 19.3.1 / tailwindcss 4.3.3 / wrangler 4.152.0） | TypeScript 7.0 は Next.js の対応状況を実装時に確認し、未対応なら 6.x を使う |

アプリ本体のリポジトリ `kajisho5/iOS_QR_reader` の `site/` に置く。アプリのビルドには含めない。

## 4. ディレクトリ構成

```
site/
├── package.json / package-lock.json
├── next.config.ts          # output: "export", trailingSlash: true, images.unoptimized
├── tsconfig.json
├── postcss.config.mjs
├── wrangler.jsonc          # name, assets.directory: "./out", not_found_handling: "404-page"
├── public/
│   ├── icon.png            # docs/design/icon/preview.png から書き出した 512px
│   └── apple-touch-icon.png
└── src/
    ├── app/
    │   ├── layout.tsx       # <html lang="ja">、共通メタデータ、SiteHeader / SiteFooter
    │   ├── globals.css      # Tailwind とデザイントークン
    │   ├── page.tsx         # トップ
    │   ├── privacy/page.tsx
    │   ├── terms/page.tsx
    │   ├── support/page.tsx
    │   └── not-found.tsx
    ├── components/
    │   ├── SiteHeader.tsx
    │   ├── SiteFooter.tsx
    │   ├── Hero.tsx
    │   ├── PromiseCards.tsx
    │   ├── FeatureList.tsx
    │   ├── PriceCard.tsx
    │   ├── LegalDocument.tsx  # 見出し・目次・本文ブロックを描画
    │   ├── TableOfContents.tsx
    │   ├── FaqList.tsx        # <details> で開閉する（JS 不要）
    │   └── ContactCard.tsx
    └── content/
        ├── site.ts            # アプリ名、提供者名、問い合わせ先、価格、各 URL
        ├── privacy.ts         # LegalDoc
        ├── terms.ts           # LegalDoc
        └── faq.ts             # FaqItem[]
```

## 5. データ構造と状態

本文はコンポーネントと分け、`content/` に型付きのデータとして置く。改定のときは `content/` だけを直す。

```ts
type Block =
  | { kind: "p"; text: string }
  | { kind: "list"; items: string[] }
  | { kind: "note"; text: string };       // 補足の囲み

type LegalSection = { id: string; heading: string; blocks: Block[] };

type LegalDoc = {
  title: string;
  enactedOn: string;   // 制定日 "2026-11-01"
  updatedOn: string;   // 最終改定日
  lead: string;        // 冒頭の要約（1〜2 文）
  sections: LegalSection[];
};

type FaqItem = { id: string; question: string; answer: Block[] };

type SiteInfo = {
  appName: "誠実QRリーダー";
  provider: string;        // §9-1 で確定
  contactEmail: string;    // §9-2 で確定
  priceLabel: "¥800（買い切り）";
  minimumOS: "iOS 17 / iPadOS 17 以降";
  appStoreURL?: string;    // 公開後に設定。未設定ならバッジを出さない
};
```

**状態管理**: 持たない。すべてサーバーで描画した静的な内容で、ブラウザで動く処理はない。FAQ の開閉は `<details>` と `<summary>` で行う。

## 6. 本文の下書き

アプリの実装（`docs/DESIGN.md` §0、`project.yml` の Info.plist、ソースコード）で確認した事実だけを書く。

### 6.1 プライバシーポリシー

- **要約**: 本アプリは利用者の情報を収集しません。開発者のサーバーへ情報を送る仕組みもありません。
1. **基本方針**: 読み取り・作成・履歴の保存は、すべて端末の中だけで行います。アプリ自身はネットワーク通信を行いません。
2. **端末の中だけで扱う情報**
   - カメラの映像：コードを読み取るためだけに使い、保存も送信もしません。
   - 写真から読み取るときに選んだ画像：端末内で解析するだけで、保存も送信もしません。写真ライブラリ全体へのアクセス権限は求めません。
   - 読み取り・作成の履歴と設定：端末内に保存します。アプリから個別または全件を削除でき、アプリを削除するとすべて消えます。
   - 端末のバックアップ（iCloud バックアップなど）を有効にしている場合、OS の機能によって履歴がバックアップに含まれることがあります。
3. **アクセス権限**（いずれも、その機能を使うときにだけ OS の確認画面が出ます）
   - カメラ：コードの読み取り
   - 写真ライブラリへの追加：作成した QR コードの画像の保存
   - 連絡先：読み取った連絡先を「連絡先」アプリに追加するとき
   - Wi-Fi の設定：読み取った Wi-Fi に接続するとき。ネットワーク名とパスワードを OS に渡します
4. **アクセス解析・広告・トラッキング**: 使っていません。トラッキングの許可も求めません。
5. **Apple が提供する機能**: App 内課金とレビューの依頼は Apple の仕組みで処理されます。開発者は支払い情報を受け取りません。Apple による情報の扱いは Apple のプライバシーポリシーに従います（リンクを掲載）。
6. **外部のサイトやアプリ**: 読み取った URL や電話番号は、利用者が「開く」などを押したときだけ、ブラウザや電話アプリに渡します。渡した先での情報の扱いは、そのサイトやアプリの方針に従います。
7. **第三者への提供**: 収集していないため、提供もしません。
8. **お問い合わせで受け取る情報**: メールで受け取った内容とメールアドレスは、回答のためだけに使います。
9. **改定**: 内容を変えるときは、このページで改定日とともに告知します。

### 6.2 利用規約

1. 適用：本アプリの利用に適用します。Apple の標準使用許諾契約（EULA）とあわせて適用されます。
2. Pro（買い切り）：一度の購入で、同じ Apple ID の端末で使えます。定期的な課金はありません。購入の復元は設定画面から行えます。返金は Apple の手続きに従います。
3. 読み取った内容について：コードの内容が安全かどうかは保証しません。URL などを開く前に、表示された内容を確認してください。
4. 禁止事項：法令に違反する目的での利用、本アプリの改変や再配布。
5. 免責：開発者は、故意または重大な過失がある場合を除き、本アプリの利用によって生じた損害について責任を負いません（消費者契約法により、全部免責の条項は無効になるため、この書き方にする）。
6. 変更：規約を変えるときは、このページで告知します。
7. 準拠法：日本法。

### 6.3 サポート（よくある質問）

- 購入した Pro が反映されない → 設定 →「購入を復元」
- 返金したい → Apple の「問題を報告する」（reportaproblem.apple.com）
- カメラが真っ暗・使えない → iPhone の「設定」→ 誠実QRリーダー → カメラをオン
- Wi-Fi に接続できない → 暗号化方式やパスワードの誤りの可能性。パスワードのコピーで手入力もできる
- 履歴が 30 件で消える → 無料版は最新 30 件を保存。Pro で無制限
- 対応端末 → iOS 17 / iPadOS 17 以降の iPhone と iPad
- 問い合わせ先 → §9-2 のメールアドレス

## 7. デザイン

`docs/site/01_mobile.svg` と `02_desktop.svg` を参照。要点：

| 項目 | 値 |
|---|---|
| 主色 | アプリアイコンと同じ系統の緑。`--brand: #0F7F68`（白地との文字コントラスト 4.93:1、AA 合格）。ヒーローの背景は `#0F7F68 → #0A5F4E`（白文字 4.93:1 以上）。アイコンの `#16A386` は白文字だと 3.17:1 で不足するため、文字の背景には使わない |
| 背景・文字（ライト） | `#F7F8F7` / `#1C1F1E`、補助文字 `#5B6361`（5.8:1） |
| 背景・文字（ダーク） | `#0E1211` / `#ECEFEE`（16.3:1）、補助文字 `#A3ACAA`（8.1:1）、主色 `#3CC7A6`（8.9:1） |
| 本文 | 16px / 行間 1.85。法務ページの本文幅は最大 680px |
| 見出し | h1 30px（スマートフォン 26px）/ h2 20px、太字 |
| 余白 | 左右 16px（スマートフォン）。セクション間 48px |
| 角丸 | カード 16px、ボタン 12px |

## 8. デプロイと URL

- `site/` で `npm run build` を実行すると `site/out/` に静的ファイルができる。それを `wrangler deploy` で Cloudflare Workers に上げる。
- このセッションの環境変数にある Cloudflare API トークンでデプロイする。値は表示もコミットもしない。
- CI（GitHub Actions）では、PR ごとに `npm ci && npm run build` が通ることだけを確かめる。CI からのデプロイには、リポジトリに Cloudflare のシークレットを登録する必要があるため、今回は行わない。
- アプリ側の `AppConstants.privacyPolicyURL` と `termsOfUseURL` を公開 URL に差し替え、README の公開前チェックリストを更新する。

## 9. 未決事項（確認したいこと）

1. **提供者の表示名**: フッターと各ページに出す名前。案：「seventhwell」（Bundle ID の組織名）
2. **問い合わせ先メールアドレス**: サポートページで公開する。Apple はサポート URL から連絡先にたどり着けることを求めている。問い合わせ専用のアドレスを推奨。
3. **URL（ドメイン）**:
   - A. `https://seijitsuqr.kajisho5.workers.dev`（追加設定なし。推奨）
   - B. アカウントにある `sw-ars.com` のサブドメイン（例 `seijitsuqr.sw-ars.com`）
   - C. 別のドメイン
4. **制定日**: 案「2026 年 11 月 1 日」（公開日に合わせてもよい）

## 10. 実装での決定と設計からの差分

| 項目 | 内容 |
|---|---|
| 制定日 | 案の 2026-11-01 ではなく、公開日の 2026-10-24 にした（公開前の日付を制定日として掲げないため） |
| 目次の現在位置 | デスクトップの目次で、読んでいる節を強調する処理だけクライアント側の JS（`TocHighlighter`、IntersectionObserver）で行う。JS が無効でも目次はリンクとして動き、本文はすべて読める |
| 問い合わせ先 | `site.ts` の `contactEmail` が空の間は、サポートページにアドレスを出さない。決まりしだい入れてデプロイする |
| アイコン | `public/app-icon.png`（520px、角丸済み）。ファビコンは `src/app/icon.png`（Next.js が `/icon.png` として出力） |
| Pro の説明文 | デスクトップで 1 文字だけ改行されないよう「すべての種類の作成」を「全種類の作成」に短縮 |
| CI | `.github/workflows/site.yml` で、`site/` を変更した PR ごとに型チェックとビルドを行う。デプロイは手動（`npx wrangler deploy`） |
