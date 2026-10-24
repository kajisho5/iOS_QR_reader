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

- 必要環境: Xcode 26 以降（CI は Xcode 26.6 / iOS 26.5 シミュレータで検証）
- 実機で動かす場合は Xcode の Signing & Capabilities で自分のチームを選択してください。
- Wi-Fi 接続機能は Hotspot Configuration の entitlement を使います。有料の Apple Developer Program のチームでないと実機署名できない場合があります（シミュレータのビルドには影響しません）。

## テスト

```sh
xcodebuild test -project SeijitsuQR.xcodeproj -scheme SeijitsuQR \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

GitHub Actions（`.github/workflows/ios.yml`）でプルリクエストごとに、iPhone シミュレータでのビルド＋テストと iPad シミュレータでのビルドを実行します。

## 文字列の追加・変更

UI の文字列はすべて `SeijitsuQR/Resources/Localizable.xcstrings` で管理し、コードからは生成された `L10n` を通して参照します。カタログを編集したら次を実行してください（CI で差分がないことを検査します）。

```sh
python3 tools/gen_l10n.py
```

## 差し替えが必要な定数

| 場所 | 項目 | 現在の値 |
|---|---|---|
| `project.yml` | `PRODUCT_BUNDLE_IDENTIFIER` | `com.example.seijitsuqr` |
| `SeijitsuQR/App/AppConstants.swift` | `proProductID`（非消耗型 IAP の商品 ID） | `com.example.seijitsuqr.pro` |
| `SeijitsuQR/App/AppConstants.swift` | `privacyPolicyURL` | `https://example.com/seijitsuqr/privacy` |
| `SeijitsuQR/App/AppConstants.swift` | `termsOfUseURL` | `https://example.com/seijitsuqr/terms` |
| `SeijitsuQR/Resources/Assets.xcassets/AppIcon.appiconset` | アプリアイコン（仮） | `docs/design/src/app_icon.svg` から生成 |

## StoreKit（Pro 買い切り）の設定手順

アプリ内課金は非消耗型（Non-Consumable）1 点だけです。サブスクリプションは使いません。

1. **App Store Connect** でアプリを作成し、「App 内課金」→「＋」→ 種類 **非消耗型** を選びます。
   - 参照名: `Pro`、製品 ID: `AppConstants.proProductID` と同じ値（例 `com.yourcompany.seijitsuqr.pro`）
   - 価格: ¥800 を選択（App Store Connect の価格表で選べることを確認してください）
   - 表示名・説明（日本語）: `Pro（買い切り）`／「履歴の無制限保存、すべての種類のQRコード作成、CSVエクスポート（買い切り）」
   - 審査用のスクリーンショット（課金画面）を添付
2. `SeijitsuQR/App/AppConstants.swift` の `proProductID` を 1. の製品 ID に変更します。
3. ローカル確認用の `StoreKit/Configuration.storekit` の `productID` も同じ値に変更します（Xcode でファイルを開いて編集できます）。
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

App Store Connect の「App のプライバシー」は「データの収集なし」を選びます（アプリ自身は外部サーバーと通信せず、通信は購入・復元時の StoreKit と、利用者がリンクを開いたときの OS 標準アプリだけです。`PrivacyInfo.xcprivacy` でも収集データなしを宣言しています）。
