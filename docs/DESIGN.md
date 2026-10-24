# 誠実QRリーダー 設計書（Step 1）

> ステータス: **確定（2026-10-24）**。Q1〜Q8 は推奨案（A）で確定。§14 の標準対応要件を追加。実装は ①スキャン から順に進める。

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

| `UISupportedInterfaceOrientations~iphone` | `UIInterfaceOrientationPortrait` のみ | iPhone は縦向き固定（要件） |
| `UISupportedInterfaceOrientations~ipad` | Portrait / PortraitUpsideDown / LandscapeLeft / LandscapeRight | iPad は全方向（要件） |
| `UIRequiresFullScreen` | 設定しない（false） | true にすると iPad のマルチタスク・リサイズから外れる（Apple: UIRequiresFullScreen） |

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
| ① スキャン | project.yml / CI / カメラ・トーチ・写真読取・連続モード・触覚音・ResultSheet（解析8種＋アクション）・自動保存の最小形・向き設定・カメラ中断時の表示 | CIグリーン、Parserテスト合格、iPad シミュレータで回転・ウィンドウ縮小時に崩れないこと |
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
| D7 | iPad / iPhone Duo | サイズクラスで 1 カラム⇔2 カラムを切り替える（§12・§13）。※当初の「同一 TabView 構成のみ」から、iPad/Duo 対応の指示を受けて変更 | HIG Layout / Designing for iPhone Duo |

## 11. 仕様外の判断（2026-10-24 すべて推奨案で確定）

| # | 論点 | 選択肢 | 推奨 |
|---|---|---|---|
| Q1 | 無料版で30件を超えたとき | A: 31件目の保存時に最古を自動削除（削除はお気に入り以外を優先）＋一覧上部に「直近30件まで」を常時表示 / B: 全件保持し表示のみ30件（購入で全件表示） / C: 30件で保存停止 | **A**（Bは「データを人質に課金」と受け取られ得る。Cは最新が残らない） |
| Q2 | 連続スキャンの「二重に記録しない」範囲 | A: 連続スキャンON〜OFFの1セッション内で同一（コード種別＋内容）を記録しない / B: 過去の履歴全体と照合 | **A**（Bは日を変えた同一商品の記録まで消える）。通常モードは毎回記録 |
| Q3 | http/https 以外のURLスキーム（独自スキーム・`javascript:` 等） | A: テキスト扱い（コピー・共有のみ。開くボタンなし） / B: すべて「開く」可能 | **A**（誤タップで他アプリ起動させない） |
| Q4 | メール／電話／SMS／地図座標のアクション（仕様はURL・Wi-Fi・連絡先・コピー・共有のみ） | A: 追加する（メール作成・電話・SMS作成・Appleマップで開く。いずれも押した時のみ） / B: 仕様通りコピー・共有のみ | **A**（種類判定の意味が出る。通信はOS標準アプリ側で、ユーザー操作時のみ） |
| Q5 | CSV形式 | A: UTF-8（BOM付き）、列＝日時, 種類, 内容, コード形式, 取得元, お気に入り / B: BOMなし | **A**（Excelで日本語が文字化けしない） |
| Q6 | Bundle ID / 商品ID | 仮値 `com.example.seijitsuqr` / `com.example.seijitsuqr.pro` で実装し README の差し替え一覧に記載 | 確定値があれば指示ください |
| Q7 | Wi-Fi接続（Hotspot Configuration entitlement） | A: 入れる（有料 Developer Program 前提） / B: 外してパスワードコピーのみ | **A**（仕様の「Wi-Fiに接続」を満たす唯一の公開API） |
| Q8 | iPhone 版モックアップ（01〜06）の見た目 | A: iPad/Duo と揃えて iOS 26 以降の Liquid Glass 表現（浮遊タブバー、ガラスのボタン）に更新し、課金画面の「閉じる」テキストをシステム標準の×ボタンに変更 / B: 現状のまま | **A**（HIG Toolbars「標準の Back/Close ボタンを使い、テキストラベルにしない」。最新 Xcode でビルドすると実機は Liquid Glass 表示になるため、モックアップとの差が出る） |

## 12. iPad / iPhone Duo 対応（デザイン: `docs/design/07_ipad.svg`, `08_iphone_duo.svg`）

根拠: [HIG: Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo)（2026-09-09 新設）、[Preparing your app for iPhone Duo](https://developer.apple.com/documentation/TechnologyOverviews/preparing-your-app-for-iphone-duo)、[iPhone Duo 技術仕様](https://www.apple.com/iphone-duo/specs/)。

### 12.1 基本方針
- **レイアウトはサイズクラスで切り替える**（デバイス種別・向きで分岐しない。`userInterfaceIdiom` を使わない）。compact 幅＝iPhone／Duo 外側、regular 幅＝iPad／Duo 内側。
- **画面ごとに作り直さない**。compact では 1 カラム（現行 iPhone 設計）、regular では一段深い階層を並べる（HIG「内側では追加の階層を表示してよい」）。機能と状態はどの画面・姿勢でも同一。
- 標準コンテナ（`TabView` / `NavigationSplitView` / `NavigationStack` の `.toolbar`）を使い、**独自のバーを作らない**。Duo の縦配置・オーバーフロー・折り目回避はシステムが行う。
- ツールバー項目はすべて **SF Symbol＋タイトルの `Label`** で定義する（縦配置ではアイコン、オーバーフローではアイコン＋タイトルが使われる。タイトルのみの項目は縦配置されない）。

### 12.2 画面別の regular 幅レイアウト

| 画面 | compact（iPhone・Duo 外側） | regular（iPad・Duo 内側） |
|---|---|---|
| スキャン | カメラ全面＋結果は `.sheet` | 左: カメラ ／ 右: 読み取り結果ペイン（シートを出さず常時表示）。Duo では `ArrangementView`（split, 横軸のみ） |
| 履歴 | 一覧 → push で詳細 | `NavigationSplitView`: 一覧（選択を持続ハイライト）｜詳細 |
| 作成 | 種類メニュー → フォーム → 生成結果 | `NavigationSplitView`: 種類一覧｜フォーム＋プレビュー |
| 課金 | `.sheet` | iPad: フォームシート ／ Duo 内側: システム既定の配置（折り目を自動回避） |
| 設定 | グループ化リスト | 同じリストを読みやすい幅に制限して中央表示 |

### 12.3 iPhone Duo 固有

| 項目 | 方針 |
|---|---|
| 縦配置バー | 外側ディスプレイと内側の横向きでは、Dynamic Island／ステータスバー／ツールバー／タブバーが後縁に縦に並ぶ（システム既定。上書きしない）。内側の縦向きは通常の横バー |
| ツールバーの順序 | 上から「閉じる・戻る」→ 主要アクション → その他。スキャン: [連続スキャン, 写真, ライト]、結果: [閉じる] [コピー, 共有, お気に入り]、履歴詳細: [コピー, 共有, お気に入り, 削除] |
| 操作の位置 | 一覧に作用する操作（CSV・選択）は一覧ペインの上に置き、詳細に作用する操作は後縁の縦バーへ（HIG「操作は対象コンテンツの近くに」） |
| 折り目（部分的に折りたたみ） | 標準のスプリットビューは列幅を折り目基準で左右対称に自動調整。カメラ｜結果の分割は `ArrangementView` が折り目を避けて配置。独自ビューで重要要素が折り目にかかる場合のみ `ReservedRegion` で回避 |
| カメラ | 外側カメラ領域は常に予約領域。開閉・回転で表示ディスプレイとカメラの向きが変わるため、スキャンは背面カメラを向きで選択し、プレビューの回転を追従させる（[Choosing a camera by the direction it faces](https://developer.apple.com/documentation/AVKit/choosing-a-camera-by-the-direction-it-faces)） |
| 画面寸法 | Apple は pt 値を公開していない。モックアップは公開ピクセル値（外側 1398×2034、内側 1878×2670）を @3x 換算した**推定値**（外側 466×678pt、内側 890×626pt）。実装は寸法に依存しない |

### 12.4 実装上の制約（事実）
- `ArrangementView`、`ReservedRegion`、`toolbarVerticalBehavior(_:)`、`toolbarVerticalEdge` は **iOS / iPadOS 27.1 以降**（Apple Developer Documentation の platform 情報）。最低OSは iOS 17 のまま、`if #available(iOS 27.1, *)` で分岐し、未対応OSでは `HStack` による分割で代替する。
- 「Xcode 26 以前でビルドするとステータスバーとカメラの下まで描画しない」（Preparing your app for iPhone Duo）。Duo 最適化には iOS 27.1 SDK を含む Xcode でのビルドが必要。**CI（GitHub Actions）のランナーにその Xcode が載っているかは未確認**で、実装時に確認する。
- iPad 寸法（1180×820pt）は Apple 公開の 2360×1640px（iPad Air 11インチ）を @2x 換算した値。

## 13. 画面の向き・iPad マルチタスク（デザイン: `docs/design/09_ipad_multitasking.svg`）

要件: iPhone は縦向き固定（回転しない）。iPad は回転と画面分割に対応し、レイアウトが崩れないこと。

### 13.1 前提の訂正（事実）
- 「Split View / ステージマネージャ」は **iPadOS 18 以前**の名称。**iPadOS 26 以降**のマルチタスクは「全画面」か「ウィンドウ表示（Windowed Apps）」の 2 方式で、左右に並べる操作はウィンドウのタイル配置で行う（[HIG Multitasking](https://developer.apple.com/design/human-interface-guidelines/multitasking)、[UIRequiresFullScreen](https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen)）。
- 最低対応 OS が iOS / iPadOS 17 のため、**両方に対応する**（iPadOS 17〜18: Split View・Slide Over・ステージマネージャ ／ iPadOS 26 以降: ウィンドウ表示）。どちらも「ウィンドウの大きさが変わる」だけなので、実装はサイズクラスによるレイアウト切替で共通。

### 13.2 向きの設定
| 端末 | 設定 | 備考 |
|---|---|---|
| iPhone | 縦向きのみ | Info.plist の `~iphone` キー |
| iPhone Duo 外側ディスプレイ | 縦向きのみ（iPhone と同じ設定が適用される） | Apple Tech Talk「外側の向きは他の iPhone と同じ」 |
| iPhone Duo 内側ディスプレイ | **アプリ側で固定できない可能性が高い** | 同じ Tech Talk 内で「内側は対応向きの設定に従わない」「対応向きは尊重するが内側ではアプリが拡大縮小される」と矛盾する説明がある（[Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)）。どちらでも崩れないよう、内側は §12 の regular 幅レイアウト（横長）で設計済み。実機で要確認 |
| iPad | 全方向 | `UIRequiresFullScreen` は設定しない |

### 13.3 レイアウト切替の基準（iPad）
| 条件 | レイアウト |
|---|---|
| 横幅 regular（全画面の縦・横、2/3 分割、大きいウィンドウ） | 2 カラム（スキャン: カメラ｜結果、履歴・作成: 一覧｜詳細）。タブバーは上部 |
| 横幅 compact（1/2〜1/3 分割、狭いウィンドウ） | iPhone と同じ 1 カラム。タブバーは下部 |
| スキャン画面で高さ＞幅 | カメラ｜結果を上下に並べる |
| 共通 | 端末の種類・向きで分岐しない。最小幅 320pt（iPhone SE 相当）まで崩れないこと。ウィンドウ表示時は左上のウィンドウコントロールと重ならないよう、操作ボタンは右上に置く（HIG Windows） |

### 13.4 カメラの制約（事実）と対応
- iPad では、他のアプリと同時に表示している間（Split View・ウィンドウ表示など）は**システムがカメラを停止する**のが既定。継続利用できるのは `isMultitaskingCameraAccessSupported` が true の場合のみで、その条件は「外部ディスプレイに接続してステージマネージャを使える iPad」「VoIP アプリ」「VoIP アプリ限定の専用 entitlement」（[isMultitaskingCameraAccessSupported](https://developer.apple.com/documentation/avfoundation/avcapturesession/ismultitaskingcameraaccesssupported)、[Accessing the camera while multitasking on iPad](https://developer.apple.com/documentation/avkit/accessing-the-camera-while-multitasking-on-ipad)）。本アプリは VoIP ではないため entitlement は使えない。
- 対応: サポートされる環境では `isMultitaskingCameraAccessEnabled = true` にする。停止された場合（中断理由 `videoDeviceNotAvailableWithMultipleForegroundApps`）は「他のアプリと同時に表示中はカメラを使えません」と表示し、「写真から読み取る」を案内する。全画面に戻ったら自動で再開する（09 の C）。
- iPadOS 26 のウィンドウ表示を内蔵ディスプレイだけで使うときに上記条件に当てはまるか（＝カメラが使えるか）は、ドキュメントから**判断できない**。実機で確認する。
- 回転時のプレビューの向きは `AVCaptureDevice.RotationCoordinator`（iOS 17 以降）で補正する（[RotationCoordinator](https://developer.apple.com/documentation/avfoundation/avcapturedevice/rotationcoordinator)）。読み取り枠の座標変換もプレビューレイヤー基準で行う。

## 14. 標準対応（必須要件）

デザイン: `docs/design/10_dark_mode.svg`（ダークモード）、`11_empty_and_permission.svg`（空状態・権限拒否）、`12_dynamic_type.svg`（最大文字サイズ）。

### 14.1 ダークモードと色
- 背景・文字・区切り線はシステムのセマンティックカラー（`Color(.systemGroupedBackground)`、`.primary`、`.secondary` 等）を使い、独自色はアセットカタログの Color Set で **Any / Dark / 高コントラスト** の各値を定義する。コードに RGB を書かない。
- 独自色（アセット名と値）。コントラスト比は WCAG 2.x の計算式で算出（17pt 以下の文字は 4.5:1 以上、太字・18pt 以上と非テキストは 3:1 以上）。

| アセット名 | 用途 | Light | Dark | 主なコントラスト |
|---|---|---|---|---|
| `AccentColor` | アクセントの文字・アイコン | #0E7C66 | #2BA083 | Light: 白背景 5.1:1 ／ Dark: #1C1C1E 上 5.2:1、黒上 6.5:1 |
| `AccentFill` | 塗りボタンの背景（白文字） | #0E7C66 | #1C8269 | 白文字 Light 5.1:1 ／ Dark 4.7:1 |
| `AccentSoft` / `AccentOnSoft` | 注意書きカードの背景と文字 | #E3F2EE / #0A5F4E | #10302A / #8FE3CB | Light 6.6:1 ／ Dark 9.5:1 |
| `FavoriteTint` | お気に入りの星（非テキスト） | #A87800 | #FFD60A | 白上 3.9:1 ／ #1C1C1E 上 12:1 |
| `FavoriteFill` | スワイプ操作「お気に入り」の背景（白文字） | #8F6500 | #8F6500 | 白文字 5.2:1 |
| 高コントラスト時 | `AccentColor` | #0A5F4E | #5ED6B8 | 白上 7.6:1 ／ #1C1C1E 上 9.6:1 |

- 「お気に入り」の文字は星の色ではなく通常の文字色で表示する（#F5B400 の黄色文字は白背景で 1.8:1 となり基準未達のため不採用）。
- 生成した QR コード画像は両モードとも **白地に黒** で表示・保存する（読み取り性の確保）。
- 確認方法: Xcode プレビューと UI テストで Light / Dark / 高コントラストの各外観を表示して確認する。

### 14.2 Dynamic Type
- すべての文字はテキストスタイル（`.body`、`.headline` 等）で指定し、固定サイズを使わない。アクセシビリティサイズ（AX1〜AX5）では `@Environment(\.dynamicTypeSize).isAccessibilitySize` を見て、横並び（アイコン＋文字、アクション 3 つ並び、ラベル＋スイッチ）を縦積みに切り替える。
- タイトル・URL・コード内容は切り詰めずに折り返す（URL は全文表示の方針と一致）。画面は `ScrollView` で全文に到達できること。
- 確認方法: 最小（xSmall）と最大（AX5）で各画面のプレビューを用意し、文字の欠け・重なりがないことを確認する。

### 14.3 VoiceOver
- アイコンだけのボタンには必ずラベルを付ける（ツールバー項目は `Label(タイトル, systemImage:)` で定義し、Duo の縦配置にも使う）。

| 要素 | ラベル | 値・ヒント |
|---|---|---|
| ライト | 「ライト」 | 値「オン」「オフ」 |
| 写真から読み取る | 「写真から読み取る」 | — |
| 連続スキャン | 「連続スキャン」 | トグル。値「オン」「オフ」 |
| カメラプレビュー | 「カメラのプレビュー」 | ヒント「コードを枠内に合わせてください」 |
| 読み取り成功 | 読み上げ通知「読み取りました。種類：URL」 | — |
| お気に入り | 「お気に入りに追加」／「お気に入りから外す」 | — |
| 閉じる・共有・コピー・削除 | 「閉じる」「共有」「コピー」「削除」 | — |
| 生成した QR 画像 | 「QR コードの画像」 | 値に内容の文字列 |
| 履歴の行 | 「URL、https://…、10月24日 8時12分、お気に入り」のように 1 要素にまとめる | カスタムアクション「お気に入り」「削除」 |

- 装飾（読み取り枠、背景の図形）は `accessibilityHidden(true)`。

### 14.4 文字列管理（String Catalogs）
- UI 文字列はすべて `Localizable.xcstrings`（開発言語: 日本語）で管理する。コードには **英語のキー**（例 `history.empty.title`）だけを書き、日本語の文言を直接書かない。
- キーの打ち間違いを防ぐため、`Localizable.xcstrings` から型付きの定数ファイル `L10n.swift` を生成する（`tools/gen_l10n.py`）。CI で再生成して差分がないことを検査し、ユニットテストで全キーに日本語の値があることを確認する。
- Info.plist の権限説明文は `InfoPlist.xcstrings` で管理する。

### 14.5 権限拒否時の代替導線と空状態
| 状況 | 表示 | 導線 |
|---|---|---|
| カメラ拒否 | 01-C | 「設定を開く」（`UIApplication.openSettingsURLString`）／「写真から読み取る」 |
| カメラ制限（スクリーンタイム等） | 01-C の文言違い（設定で変更できない旨） | 「写真から読み取る」のみ |
| 写真への保存を拒否 | 11-D のアラート | 「設定を開く」／「キャンセル」 |
| 連絡先の追加で権限が必要だった場合 | 11-D と同形式 | 同上（§7 の実機確認で要否を判断） |
| 他アプリと同時表示でカメラ停止（iPad） | 09-C | 「写真から読み取る」 |
| 画像にコードがない | 11-E | 「別の画像を選ぶ」／「キャンセル」 |
| 履歴 0 件 | 11-A | 「スキャンを始める」（スキャンタブへ） |
| 検索・絞り込みで 0 件 | 11-B | 「絞り込みを解除」 |
| 自動保存オフで 0 件 | 11-C | 「設定を開く」（アプリ内の設定タブ） |
| 連続スキャンで今回 0 件 | トレイを表示しない | — |

### 14.6 プライバシーマニフェスト（`PrivacyInfo.xcprivacy`）
- `NSPrivacyTracking` = false、`NSPrivacyTrackingDomains` = 空、`NSPrivacyCollectedDataTypes` = 空。
- `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults`（理由 `CA92.1`：アプリ自身だけが読み書きする設定値）。実装中に他の必須理由 API（ファイルの日時、空き容量、起動時刻など）を使う場合は、その時点で追記する。

### 14.7 履歴データの保持（バックアップ・アップデート・機種変更）
- SwiftData のストアは `Application Support/History.store` に明示的に置く。このフォルダは iCloud バックアップと端末間の移行の対象で、`isExcludedFromBackup` は設定しない（`Caches` や `tmp` には置かない）。
- バックアップは利用者自身の iCloud に保存され、開発者は内容にアクセスできない。アプリ自体はネットワーク通信を行わない（原則「端末内完結」と両立）。CloudKit による同期は行わない。
- アップデートで消えないよう、初版から `VersionedSchema`（SchemaV1）と `SchemaMigrationPlan` を用意し、以後の変更は移行ステージを追加して行う。移行のユニットテストを書く。
- 事実として、アプリを削除すると端末内のデータは OS によって削除される（バックアップからの復元は可能）。この点は設定画面の「履歴」欄の注記で利用者に伝える。
