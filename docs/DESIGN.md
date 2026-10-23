# 誠実QRリーダー 設計書（Step 1）

> ステータス: **レビュー待ち**。本書と `docs/design/*.svg` の承認後に実装（①スキャン）へ進む。

## 0. 前提と3原則の実装上の担保

| 原則 | 設計上の担保 |
|---|---|
| 広告なし | 広告SDK・サードパーティライブラリを一切リンクしない（SPM依存ゼロ。`project.yml` に `packages:` を書かない） |
| サブスクなし | StoreKit 2 の **非消耗型1点のみ**。`Product.SubscriptionInfo` を参照するコードを持たない。課金画面はユーザー操作でのみ開く（起動時・スキャン直後に自動表示しない） |
| 端末内完結 | アプリ自身は**ネットワーク通信を行うコードを持たない**（`URLSession` 不使用）。外部遷移はユーザーがボタンを押した時の `openURL` のみ |

- App Privacy:「データの収集なし」。根拠＝Apple定義で「端末内のみで処理されるデータは収集に当たらない」「決済情報がアプリ外で入力され開発者がアクセスしない場合は収集に当たらない」「Appleが収集するデータは開発者の開示対象外」（[App privacy details](https://developer.apple.com/app-store/app-privacy-details/)）。
- ATT（App Tracking Transparency）不使用。`NSUserTrackingUsageDescription` を Info.plist に書かない。
- `PrivacyInfo.xcprivacy` を同梱：`NSPrivacyTracking=false`、収集データ空、Required Reason API は UserDefaults（理由コード `CA92.1`）のみ申告。

## 1. 技術スタック

| 項目 | 採用 | 備考 |
|---|---|---|
| 言語/UI | Swift 6 言語モード + SwiftUI | Observation（`@Observable`）で状態管理 |
| 最低OS | iOS 17.0 / iPadOS 17.0 | iPhone・iPad（`TARGETED_DEVICE_FAMILY = 1,2`） |
| スキャン | AVFoundation（`AVCaptureMetadataOutput`） | カメラ。プレビューは `UIViewRepresentable` |
| 画像読取 | Vision（`VNDetectBarcodesRequest`）+ PhotosUI（`PhotosPicker`） | `PhotosPicker` は写真ライブラリ読取権限不要 |
| 履歴 | SwiftData | `@Model ScanRecord` |
| QR生成 | CoreImage（`CIFilter.qrCodeGenerator`） | 誤り訂正レベル M |
| 課金 | StoreKit 2 | `Product.products(for:)` / `Transaction.currentEntitlements` / `Transaction.updates` / `AppStore.sync()` |
| Wi-Fi接続 | NetworkExtension（`NEHotspotConfigurationManager`） | **Hotspot Configuration capability 必須**（後述） |
| 連絡先追加 | ContactsUI（`CNContactViewController(forNewContact:)`） | |
| レビュー依頼 | StoreKit（SwiftUI `@Environment(\.requestReview)`） | |
| プロジェクト | XcodeGen `project.yml`（ビルドツールのみ。アプリには含まれない） | 生成手順を README に記載 |
| ビルド検証 | GitHub Actions macOS ランナー（`xcodegen` → `xcodebuild` シミュレータビルド＋ユニットテスト） | 後述「ビルド検証の制約」 |

## 2. 画面遷移

図: `docs/design/00_flow.svg`

```
App起動
 └─ RootView (TabView)  ※初期タブ=スキャン。オンボーディング/スプラッシュなし
     ├─ [スキャン] ScannerView ──(検出)──▶ ResultSheet（.sheet, medium/large）
     │      │   ├ トーチ ON/OFF            ├ URL: 全文表示 → [開く] [コピー] [共有]
     │      │   ├ 写真から読み取り ─▶ PhotosPicker ─▶ ResultSheet
     │      │   └ 連続スキャン ON          ├ Wi-Fi: SSID/暗号化/パスワード → [接続] [パスワードをコピー] [共有]
     │      │       └ 下部トレイに今回読取分を積む（シートは出さない）─(タップ)─▶ ResultSheet
     │      │                             ├ 連絡先: → [連絡先に追加]▶CNContactViewController
     │      └ カメラ未許可 ─▶ 権限説明ビュー [設定を開く] [写真から読み取り]
     ├─ [履歴] HistoryListView
     │      ├ 検索（日時・種類・内容）/ 種類フィルタ / お気に入りのみ
     │      ├ 行タップ ─▶ HistoryDetail（= ResultSheet と同一ビューをpush表示）
     │      ├ スワイプ: 削除 / お気に入り、編集→全件削除（確認ダイアログ）
     │      ├ CSVエクスポート ─(Pro)─▶ ShareSheet ／(無料)─▶ PaywallSheet
     │      └ 無料版で30件到達時のバナー ─(タップ)─▶ PaywallSheet
     ├─ [作成] CreateMenuView
     │      ├ テキスト / URL ─▶ 入力フォーム [QRコードを作成] ─▶ GeneratedQRView [写真に保存] [共有]
     │      └ Wi-Fi / 連絡先 / イベント（無料版は🔒） ─(無料)─▶ PaywallSheet ／(Pro)─▶ フォーム
     └─ [設定] SettingsView
            ├ Pro: 購入 ─▶ PaywallSheet ／ [購入を復元]
            ├ スキャン時の音 / 振動 / 履歴の自動保存
            └ プライバシーポリシー / 利用規約（Safariで開く）/ バージョン
```

- PaywallSheet の出現契機は「ユーザーがロック機能をタップ」「設定から購入」の2種のみ。
- ResultSheet 表示中はカメラセッションを一時停止し、閉じたら再開（誤連続検出の防止）。

## 3. ディレクトリ構成

```
iOS_QR_reader/
├── project.yml                         # XcodeGen 定義
├── README.md                           # ビルド手順・StoreKit設定・差し替え定数一覧
├── .github/workflows/ios-build.yml     # macOSランナーでの生成＋ビルド＋テスト
├── docs/
│   ├── DESIGN.md                       # 本書
│   ├── design/*.svg                    # 画面デザイン
│   └── AppStoreListing.md              # ⑤で作成: 掲載文下書き
├── SeijitsuQR/
│   ├── App/
│   │   ├── SeijitsuQRApp.swift         # @main, ModelContainer, ProStore 注入
│   │   ├── RootView.swift              # TabView
│   │   └── AppConstants.swift          # ★差し替え定数（URL・商品ID）
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── ScanRecord.swift        # SwiftData @Model
│   │   │   ├── PayloadKind.swift       # url/wifi/contact/email/phone/sms/geo/text
│   │   │   ├── CodeSymbology.swift     # 11コード種別 ⇔ AVMetadata/Vision 対応表
│   │   │   └── RecordSource.swift      # camera/photo/created
│   │   ├── Parsing/
│   │   │   ├── PayloadParser.swift     # 文字列 → ParsedPayload
│   │   │   ├── WiFiPayload.swift       # WIFI:T:;S:;P:;H:;; （エスケープ対応）
│   │   │   ├── ContactPayload.swift    # vCard(CNContactVCardSerialization) / MECARD
│   │   │   └── MessagePayloads.swift   # mailto/MATMSG, tel, sms/SMSTO, geo
│   │   ├── Encoding/
│   │   │   ├── PayloadEncoder.swift    # 入力 → QR文字列（WIFI, vCard 3.0, VEVENT）
│   │   │   └── QRCodeRenderer.swift    # CoreImage → UIImage
│   │   └── Services/
│   │       ├── HistoryStore.swift      # 保存・無料版30件制限・重複判定
│   │       ├── AppSettings.swift       # @AppStorage キー集中管理
│   │       ├── FeedbackPlayer.swift    # 触覚・音（設定値に従う）
│   │       ├── ReviewPromptPolicy.swift# 10回超過後に1回だけ
│   │       └── CSVExporter.swift
│   ├── Features/
│   │   ├── Scan/      ScannerView, CameraPreview, CaptureController, ImageCodeReader, ContinuousTray, CameraPermissionView
│   │   ├── Result/    ResultView, ResultActions, WiFiConnector, ContactAddView(UIViewControllerRepresentable)
│   │   ├── History/   HistoryListView, HistoryFilterBar, HistoryRow
│   │   ├── Create/    CreateMenuView, TextForm, URLForm, WiFiForm, ContactForm, EventForm, GeneratedQRView, PhotoLibrarySaver
│   │   ├── Store/     ProStore(@Observable), PaywallView
│   │   └── Settings/  SettingsView
│   ├── Resources/
│   │   ├── Assets.xcassets             # AppIcon, AccentColor
│   │   ├── scan_beep.caf               # 自作の短いビープ音
│   │   └── PrivacyInfo.xcprivacy
│   ├── SeijitsuQR.entitlements         # Hotspot Configuration
│   └── Configuration.storekit          # ローカル課金テスト用（¥800 非消耗型1点）
└── SeijitsuQRTests/                    # Parser / Encoder / 30件制限 / CSV のユニットテスト
```

## 4. データ構造

### 4.1 SwiftData

```swift
@Model final class ScanRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var content: String          // 生文字列（QRに入っていた/生成した文字列そのもの）
    var kindRaw: String          // PayloadKind.rawValue
    var symbologyRaw: String?    // CodeSymbology.rawValue（作成時は "qr"）
    var sourceRaw: String        // RecordSource.rawValue
    var isFavorite: Bool
}
```

- 検索: `@Query(sort: \.createdAt, order: .reverse)` で取得 → メモリ上で「内容」「種類名（日本語）」「日時文字列 `yyyy/MM/dd HH:mm`」に対し `localizedStandardContains`。
- 種類フィルタ: `PayloadKind?`（nil=すべて）＋お気に入りトグル。

### 4.2 解析結果（非永続）

```swift
enum ParsedPayload {
    case url(URL)
    case wifi(ssid: String, password: String?, security: WiFiSecurity, hidden: Bool)
    case contact(CNContact)          // 表示用に名前・電話・メール・組織を抽出
    case email(address: String, subject: String?, body: String?)
    case phone(String)
    case sms(number: String, body: String?)
    case geo(latitude: Double, longitude: Double, query: String?)
    case text(String)
}
```

判定順: WIFI → BEGIN:VCARD / MECARD → mailto/MATMSG → tel → sms/SMSTO → geo → URL（`http`/`https` のみURL扱い） → text。

## 5. 状態管理

| 状態 | 置き場所 | 共有範囲 |
|---|---|---|
| Pro購入状態 | `ProStore`（`@Observable`, `@MainActor`）。起動時に `Transaction.currentEntitlements` を検証、`Transaction.updates` を常時監視 | `.environment` で全画面 |
| 設定（音/振動/自動保存/スキャン成功回数/レビュー依頼済み） | `AppSettings`（`@AppStorage`） | 全画面 |
| カメラセッション・トーチ・連続モード・今回の読取済みセット | `CaptureController`（`@Observable`） | スキャンタブ内 |
| 表示中の結果 | `ScannerView` の `@State var presented: ScanResult?` | ローカル |
| 履歴 | SwiftData `ModelContext` / `@Query` | 全画面 |

- Pro状態は**キャッシュしない**（UserDefaults等に「購入済み」を書かない）。毎回 StoreKit の署名検証済みトランザクションで判定。オフライン時もStoreKitが端末内で検証できる。

## 6. 課金仕様（StoreKit 2）

- 商品: 非消耗型 1点。商品ID は `AppConstants.proProductID`（初期値 `com.example.seijitsuqr.pro`、要差し替え）。
- 価格表示: `product.displayPrice` をボタンにそのまま表示（例「¥800で購入」）。ハードコードしない。
- 課金画面の必須文言: 「これは買い切りです。毎月・毎週の支払いは発生しません」「広告は今後も入れません」。
- 使わない表現: 無料お試し / 期間限定 / 今だけ / 割引 / カウントダウン / ×ボタンを小さく隠す等。
- 復元: `AppStore.sync()`。課金画面と設定画面の2箇所に配置。

| 機能 | 無料 | Pro |
|---|---|---|
| スキャン | 無制限 | 無制限 |
| 履歴保存 | 直近30件 | 無制限 |
| QR作成 | テキスト・URL | 全5種 |
| CSVエクスポート | ✕ | ○ |

## 7. 権限・Info.plist

| キー | 文言 | 必須理由 |
|---|---|---|
| `NSCameraUsageDescription` | QRコードとバーコードを読み取るためにカメラを使用します。読み取った内容が外部に送信されることはありません | 仕様指定 |
| `NSPhotoLibraryAddUsageDescription` | 作成したQRコードの画像を写真ライブラリに保存するために使用します | QRを写真へ保存（追加のみ権限） |
| `NSContactsUsageDescription` | 読み取った連絡先を連絡先アプリに追加するために使用します | ※要実機確認（下記） |

- 写真からの読み取りは `PhotosPicker`（システムが別プロセスで提示）を使うため写真ライブラリ読取権限は要求しない。
- `CNContactViewController(forNewContact:)` が連絡先アクセス権なしで保存できるかは**一次情報で確認できなかった（不明）**。①〜②の実装時に実機で検証し、不要なら上記キーを削除する。

## 8. ビルド検証の制約（事実）

- 本作業環境は Linux コンテナで、Xcode / iOS SDK が存在しないため**ここでは iOS ビルドを実行できない**。
- 代替: リポジトリが public のため GitHub Actions の標準 macOS ランナーで `xcodegen generate` → `xcodebuild build test`（iOS Simulator、署名なし）を実行し、各ステップの完了条件を「CIグリーン」とする。
- 補足: Apple公式サイトには「Xcode 27」の記載がある一方、GitHub macos-26 イメージの既定は Xcode 26.6（2026-08時点の公開情報）。コードは Xcode 26 系以降でビルドできる書き方に留める。
- Hotspot Configuration は有料 Apple Developer Program のプロビジョニングで許可される entitlement。シミュレータビルド（署名なし）には影響しないが、無料 Apple ID の個人チームで実機ビルドすると署名エラーになる可能性がある（README に明記）。

## 9. 実装ステップと完了条件

| Step | 内容 | 完了条件 |
|---|---|---|
| ① スキャン | project.yml / CI / カメラ・トーチ・写真読取・連続モード・触覚音・ResultSheet（解析8種＋アクション）・自動保存の最小形 | CIグリーン、Parserテスト合格 |
| ② 履歴 | 一覧・検索・フィルタ・お気に入り・削除（単体/全件）・CSV（ゲート前） | CIグリーン、30件制限テスト |
| ③ QR作成 | 5種フォーム・生成・写真保存・共有・履歴保存 | CIグリーン、Encoderテスト |
| ④ 課金 | ProStore・Paywall・各ゲート接続・復元2箇所・.storekit | CIグリーン |
| ⑤ 仕上げ | 設定画面・レビュー依頼・PrivacyInfo・アイコン・README・掲載文 | CIグリーン |

## 10. 本設計で決めた事項（異論があれば指摘ください）

| # | 事項 | 決定内容 | 理由 |
|---|---|---|---|
| D1 | 作成QRの履歴保存タイミング | 入力中は保存せず、「QRコードを作成」押下時に1件保存 | 1文字ごとの保存を防ぐ |
| D2 | 結果シート表示中のカメラ | 一時停止し、閉じたら再開 | 同じコードの多重検出防止 |
| D3 | Pro状態の保持 | UserDefaults にキャッシュせず、毎回 StoreKit の検証済みトランザクションで判定 | 改ざん耐性・単一の真実 |
| D4 | スキャン音 | 自作の短い音声ファイルを同梱し再生 | システムサウンドIDは公開ドキュメントで確認できないため依存しない |
| D5 | 写真から複数コード検出 | 1件なら即結果表示、複数なら一覧から選択 | 誤った方を自動採用しない |
| D6 | アプリアイコン | 仮アイコン（SVGから1024px PNG生成）を同梱。差し替え前提 | ビルド・審査に必須 |
| D7 | iPad | 同一 TabView 構成（iPadOS 18以降はシステムがタブを上部表示） | 仕様外のレイアウト追加をしない |

## 11. 要確認事項（仕様外の判断・回答待ち）

| # | 論点 | 選択肢 | 推奨 |
|---|---|---|---|
| Q1 | 無料版で30件を超えたとき | A: 31件目の保存時に最古を自動削除（削除はお気に入り以外を優先）＋一覧上部に「直近30件まで」を常時表示 / B: 全件保持し表示のみ30件（購入で全件表示） / C: 30件で保存停止 | **A**（Bは「データを人質に課金」と受け取られ得る。Cは最新が残らない） |
| Q2 | 連続スキャンの「二重に記録しない」範囲 | A: 連続スキャンON〜OFFの1セッション内で同一（コード種別＋内容）を記録しない / B: 過去の履歴全体と照合 | **A**（Bは日を変えた同一商品の記録まで消える）。通常モードは毎回記録 |
| Q3 | http/https 以外のURLスキーム（独自スキーム・`javascript:` 等） | A: テキスト扱い（コピー・共有のみ。開くボタンなし） / B: すべて「開く」可能 | **A**（誤タップで他アプリ起動させない） |
| Q4 | メール／電話／SMS／地図座標のアクション（仕様はURL・Wi-Fi・連絡先・コピー・共有のみ） | A: 追加する（メール作成・電話・SMS作成・Appleマップで開く。いずれも押した時のみ） / B: 仕様通りコピー・共有のみ | **A**（種類判定の意味が出る。通信はOS標準アプリ側で、ユーザー操作時のみ） |
| Q5 | CSV形式 | A: UTF-8（BOM付き）、列＝日時, 種類, 内容, コード形式, 取得元, お気に入り / B: BOMなし | **A**（Excelで日本語が文字化けしない） |
| Q6 | Bundle ID / 商品ID | 仮値 `com.example.seijitsuqr` / `com.example.seijitsuqr.pro` で実装し README の差し替え一覧に記載 | 確定値があれば指示ください |
| Q7 | Wi-Fi接続（Hotspot Configuration entitlement） | A: 入れる（有料 Developer Program 前提） / B: 外してパスワードコピーのみ | **A**（仕様の「Wi-Fiに接続」を満たす唯一の公開API） |
