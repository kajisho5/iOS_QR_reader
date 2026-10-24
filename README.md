# 誠実QRリーダー

広告なし・サブスクなし・端末内で完結する QR／バーコードリーダー（iOS / iPadOS 17 以降、SwiftUI）。

- 設計書: [`docs/DESIGN.md`](docs/DESIGN.md)
- 画面デザイン: [`docs/design/`](docs/design/)
- App Store 掲載文の案: [`docs/AppStoreListing.md`](docs/AppStoreListing.md)

## ビルド手順

Xcode プロジェクトは [XcodeGen](https://github.com/yonaskolb/XcodeGen) の `project.yml` から生成します（XcodeGen はビルド用ツールで、アプリには含まれません）。

```sh
brew install xcodegen
xcodegen generate
open SeijitsuQR.xcodeproj
```

- 必要環境: Xcode 26.x、または Xcode 27.1 以降（CI は Xcode 26.6 と Xcode 27.1 で検証）。Xcode 27.0 は iPhone Duo 用の API（iOS 27.1 SDK）がないためビルドできません。App Store に出すビルドは Xcode 27.1 以降を推奨（iPhone Duo の画面全体に描画するため）
- 実機で動かす場合は Xcode の Signing & Capabilities で自分のチームを選択してください。
- Wi-Fi 接続機能は Hotspot Configuration の entitlement を使います。有料の Apple Developer Program のチームでないと実機署名できない場合があります（シミュレータのビルドには影響しません）。

## テスト

```sh
xcodebuild test -project SeijitsuQR.xcodeproj -scheme SeijitsuQR \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

GitHub Actions（`.github/workflows/ios.yml`）でプルリクエストごとに、iPhone シミュレータでのビルド＋テストと iPad シミュレータでのビルドを実行します。

| ジョブ | ランナー | Xcode / シミュレータ | 位置づけ |
|---|---|---|---|
| `build-and-test` | `macos-26`（正式版） | Xcode 26.6 / iOS 26.5 | 必須。失敗したらマージしない |
| `latest-xcode` | `xcode-27`（GitHub のプレビュー版イメージ） | イメージの既定 Xcode 27 系 / 入っている最新の iOS ランタイムの iPhone・iPad | 参考。プレビュー版のため失敗・待ち時間があっても PR は止めない |

GitHub の正式版ランナー（`macos-26`）にはまだ Xcode 27 が入っていないため、最新環境の確認はプレビュー版のランナーで行っています。

## 文字列の追加・変更

UI の文字列はすべて `SeijitsuQR/Resources/Localizable.xcstrings` で管理し、コードからは生成された `L10n` を通して参照します。カタログを編集したら次を実行してください（CI で差分がないことを検査します）。

```sh
python3 tools/gen_l10n.py
```

## 設定済みの識別子と差し替えが必要な定数

| 場所 | 項目 | 現在の値 |
|---|---|---|
| `project.yml` | `PRODUCT_BUNDLE_IDENTIFIER` | `com.seventhwell.seijitsuqr` |
| `SeijitsuQR/App/AppConstants.swift` | `proProductID`（非消耗型 IAP の商品 ID） | `com.seventhwell.seijitsuqr.pro` |
| `SeijitsuQR/App/AppConstants.swift` | `privacyPolicyURL` | `https://example.com/seijitsuqr/privacy` |
| `SeijitsuQR/App/AppConstants.swift` | `termsOfUseURL` | `https://example.com/seijitsuqr/terms` |
| `SeijitsuQR/Resources/Assets.xcassets/AppIcon.appiconset` | アプリアイコン（仮） | `docs/design/src/app_icon.svg` から生成 |

## StoreKit（Pro 買い切り）の設定手順

アプリ内課金は非消耗型（Non-Consumable）1 点だけです。サブスクリプションは使いません。

1. **App Store Connect** でアプリを作成し、「App 内課金」→「＋」→ 種類 **非消耗型** を選びます。
   - 参照名: `Pro`、製品 ID: `com.seventhwell.seijitsuqr.pro`（`AppConstants.proProductID` と同じ値）
   - 価格: ¥800 を選択（App Store Connect の価格表で選べることを確認してください）
   - 表示名・説明（日本語）: `Pro（買い切り）`／「履歴の無制限保存、すべての種類のQRコード作成、CSVエクスポート（買い切り）」
   - 審査用のスクリーンショット（課金画面）を添付
2. `SeijitsuQR/App/AppConstants.swift` の `proProductID` は設定済みです（製品 ID を変える場合だけ、ここも同じ値に変更）。
3. ローカル確認用の `StoreKit/Configuration.storekit` の `productID` も同じ値に設定済みです。
   - スキーム `SeijitsuQR` の Run に設定済みのため、シミュレータでは App Store に接続せずに購入・復元・返金を試せます。
   - 動作確認の手順: シミュレータで「設定」タブ → 「購入」→ 購入、アプリを再起動して Pro のままか確認、Xcode の Debug → StoreKit → Manage Transactions で返金して Pro が外れるか確認、「購入を復元」で戻るか確認。
   - 価格を円で表示するには、Xcode でこのファイルを開き、Editor → Default Storefront を「Japan」にします。
   - CI のシミュレータでは StoreKit のテストセッションが反映されないため、ユニットテスト `ProStoreTests` は Pro 判定のルール（検証済み・未返金・Pro 製品のみ）だけを検証しています。
4. 審査提出時、App 内課金をアプリのバージョンと一緒に提出します。

アプリは購入状態を独自に保存せず、毎回 StoreKit の検証済みトランザクション（`Transaction.currentEntitlements`）で判定します。復元ボタンは課金画面と設定画面にあり、`AppStore.sync()` を呼びます。

## 提出前のチェック

CI ではシミュレータでのビルドとユニットテストだけを確認しています。次は実機で確認してください。

- [ ] カメラで QR コード・各種バーコードを読み取れる（連続スキャン、ライト、写真から読み取りを含む）
- [ ] カメラを「許可しない」にしたとき、「設定を開く」「写真から読み取る」が表示される
- [ ] Wi-Fi の QR コードで「Wi-Fiに接続」が動く（Hotspot Configuration の entitlement が付いたプロビジョニングが必要）
- [ ] 連絡先の追加、写真への保存、共有、CSV エクスポートが動く
- [ ] Sandbox アカウントで購入・復元ができ、Pro の機能が使えるようになる
- [ ] ダークモード、最大の文字サイズ、VoiceOver で操作できる
- [ ] iPad で回転・ウィンドウのサイズ変更をしてもレイアウトが崩れない
- [ ] 作成フォーム（特に連絡先）でキーボードを出しても、入力中の欄と「QRコードを作成」が隠れない。改行キーで次の欄へ進み、最後の欄の「完了」で作成できる
- [ ] 起動時に単色（黒）の画面のあと、すぐスキャン画面になる（ロゴ・アニメーション・広告なし）
- [ ] iPhone：写真・連続スキャン・ライトが画面下部にある。結果シートと課金画面の主な操作が下部に固定されている
- [ ] すべてのシートが左上の×・下スワイプで閉じる。結果シートから「連絡先に追加」を押すと、結果シートが閉じてから連絡先の画面が出る
- [ ] iPad：ボタン・カード・履歴の行にポインタのハイライトが出る。履歴の行を右クリック（2本指タップ）するとメニューが出る
- [ ] iPad：外付けキーボードで ⌘1〜⌘4（タブ）、⌘F（履歴を検索）、⌘O（写真から読み取る）、⌘Return（主な操作・作成）、⇧⌘C（コピー）、⌘D（お気に入り）、⌘Delete（履歴の詳細で削除）、esc（シートを閉じる）が動く。⌘ を長押しすると一覧に表示される

App Store Connect の「App のプライバシー」は「データの収集なし」を選びます（アプリ自身は外部サーバーと通信せず、通信は購入・復元時の StoreKit と、利用者がリンクを開いたときの OS 標準アプリだけです。`PrivacyInfo.xcprivacy` でも収集データなしを宣言しています）。
