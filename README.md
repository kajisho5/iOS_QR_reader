# 誠実QRリーダー

広告なし・サブスクなし・端末内で完結する QR／バーコードリーダー（iOS / iPadOS 17 以降、SwiftUI）。

- 設計書: [`docs/DESIGN.md`](docs/DESIGN.md)
- 画面デザイン: [`docs/design/`](docs/design/)

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

StoreKit の商品 ID 設定手順は課金機能の実装時（ステップ④）に追記します。
