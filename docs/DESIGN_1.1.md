# 誠実QRリーダー 1.1 / 1.2 追加機能 設計書（Step 1）

> ステータス: **提案中（2026-11-06）・確認待ち**。デザインは `docs/design/15_show_code.svg`〜`18_entry_points.svg`（生成元 `docs/design/src/v11.js`）。
> 1.0 の設計書は `docs/DESIGN.md`。3 原則（広告なし・サブスクなし・端末内完結）はそのまま守る。

## 0. 追加する機能と出す順番

| 案 | 機能 | 無料 / Pro | 出す版 | 理由 |
|---|---|---|---|---|
| A | 読み取った QR を再表示（全画面・保存・共有） | 無料 | 1.1 | 毎日使える。アプリ本体だけで作れる |
| C | URL の注意表示（開く前に端末内で確認） | 無料 | 1.1 | 「誠実」の約束に一番合う。アプリ本体だけで作れる |
| D | すぐ読める入口（コントロールセンター・ロック画面・アクションボタン・ショートカット） | 無料 | 1.2 | ウィジェット拡張（Widget Extension）が要る |
| B | ウィジェット（お気に入りの QR をホーム画面に） | **Pro** | 1.2 | 同上。Pro の目玉にする |
| E | 共有シートから画像の QR を読む | 無料 | 1.2 | 共有拡張（Share Extension）が要る |

**分ける理由（事実）**: B・D・E はアプリとは別の「拡張」ターゲットになり、拡張ごとに別のバンドル ID・プロビジョニングプロファイル・App Group が要る。TestFlight 送信（kajisho5/runway）が複数ターゲットの署名に対応しているかは**未確認**。1.1 をアプリ本体だけで出し、1.2 の前に runway の対応を確認する。

## 1. A：読み取った QR を再表示（`15_show_code.svg`）

### 要件
- 結果シート（A1）の操作タイルに「QRを表示」を追加（3 → 4 タイル）。履歴の詳細（A3）は一番上に QR を表示し、タップで全画面（A2）。
- 全画面（A2）: 白地（ダークモードでも白。読み取る側のため）、QR は画面幅いっぱい、表示中は画面の明るさを最大にし、閉じたら元に戻す。「写真に保存」「画像を共有」。
- 作り直した QR は中身が同じでも模様が元と違うことがある。その旨を画面に書く（誇張しない）。

### 表示できる種類（事実：CoreImage にある生成フィルタ）
| 種類 | 生成 | 1.1 の扱い |
|---|---|---|
| QR | `CIQRCodeGenerator` | 表示（誤り訂正 M。作成機能と同じ） |
| Code 128 | `CICode128BarcodeGenerator` | 表示 |
| PDF417 | `CIPDF417BarcodeGenerator` | 表示 |
| Aztec | `CIAztecCodeGenerator` | 表示 |
| EAN-13/8・UPC-E・Code 39/93・ITF-14・Data Matrix | iOS に生成機能なし | 「表示できません」（A4）。自前で描くかは 1.2 以降に判断 |

### 実装
| ファイル | 内容 |
|---|---|
| `Core/Encoding/CodeImageRenderer.swift`（新規） | `CodeSymbology` と文字列から `CGImage?` を作る。既存 `QRCodeRenderer` を内部で使う。作れない種類は `nil` |
| `Features/Result/CodeDisplayView.swift`（新規） | 全画面表示。`UIScreen.brightness` を表示時に 1.0、`onDisappear` と `scenePhase` の変化で元の値へ戻す |
| `Features/Result/ResultView.swift` | タイルを 4 つに。作れない種類は無効表示 |
| `Features/History/HistoryView.swift`（詳細） | 上部に QR サムネイル |
| 保存 | 既存 `PhotoLibrarySaver`（追加のみの権限）を使う |

## 2. C：URL の注意表示（`16_url_check.svg`）

### 要件
- URL の結果シートで、**通信せず**に URL の文字列だけを調べ、該当すれば注意カードを出す。短縮 URL の行き先は調べない（調べるには通信が要るため）。その旨をそのまま書く。
- 注意がある URL で「ブラウザで開く」を押したら確認を挟む（C3）。「開かない」を既定（太字）にする。
- 注意がなければ今と同じ（何も足さない）。

### 判定ルール（`Core/Parsing/URLRiskAnalyzer.swift` 新規、純粋関数）
| ルール | 判定 | 重さ |
|---|---|---|
| 見た目の似た文字 | ホストに `xn--` を含む、または ASCII 以外の文字が入っている（IDN）。表示用に Unicode 形と実際の punycode 形の両方を出す | 警告（赤） |
| ドメインの偽装 | `https://example.com@evil.example/` のようにユーザー情報（`@` の前）がある | 警告（赤） |
| 短縮 URL | ホストが既知の短縮サービス一覧（bit.ly, t.co, tinyurl.com, goo.gl, ow.ly, is.gd, buff.ly, cutt.ly, rebrand.ly, x.gd など。一覧はコードに持ち、増やせる） | 注意（黄） |
| 暗号化なし | スキームが `http` | 注意（黄） |
| IP アドレス直接 | ホストが IPv4 / IPv6 リテラル | 注意（黄） |
| 標準でないポート | `http` で 80 以外、`https` で 443 以外のポート指定 | 注意（黄） |

- 結果は `[URLRisk]`（種類・重さ・説明文の L10n キー）。ユニットテストで各ルールの真偽を確認する。
- 誤検知を避けるため、上の 6 つ以外（「怪しい単語」など推測的な判定）は入れない。

## 3. D：すぐ読める入口（`18_entry_points.svg` D1・D2）

- iOS 18 以降: `ControlWidget`（`ControlWidgetButton` + `OpenIntent`）で「QRスキャン」。コントロールセンター・ロック画面・アクションボタンに置ける。押すとアプリが開き、スキャンタブでカメラが始まる（起動直後からカメラを準備する 1.0.1 の仕組みをそのまま使う）。
- iOS 17: `AppShortcutsProvider` で「QRをスキャン」をショートカットアプリと Siri に出す（アクションボタンにも割り当てられる）。
- 置き場所: ウィジェット拡張（B と同じターゲット）。

## 4. B：ウィジェット（`17_widget.svg`、Pro）

- 小（QR + 名前）・中（QR + 名前 + 内容の一部）。表示する QR は**お気に入り**から選ぶ（`AppIntentConfiguration`、B2）。
- データの受け渡し: 履歴の SwiftData ストアは**移動しない**（移動は既存ユーザーのデータを失う危険があるため）。アプリが「お気に入りの一覧（id・名前・種類・中身）」を App Group の小さな JSON に書き出し、ウィジェットはそれを読んで QR を描く。お気に入りの変更時と起動時に書き出し、`WidgetCenter.reloadAllTimelines()`。
- Pro 判定: アプリが購入状態を App Group に書き、ウィジェットは未購入なら B3 の表示（タップで購入画面を開く URL）。
- 注意（プライバシー）: Wi-Fi のパスワードを含む QR もホーム画面に出ることになる。B2 の選択画面に「ホーム画面に表示されます」と明記する。

## 5. E：共有シートから読む（`18_entry_points.svg` E1・E2）

- 共有拡張（`com.apple.share-services`）。画像を受け取り、既存の `ImageCodeReader`（Vision）で読む。複数あれば選ばせる（アプリと同じ）。
- 結果は拡張の中で表示（E2）。「ブラウザで開く」「コピー」「共有」「アプリで開く」。C の注意表示も同じく出す。
- 履歴: 拡張から SwiftData ストアには書かない。App Group の「未取り込みキュー」（JSON）に追加し、アプリが次に開いたときに履歴へ取り込む（自動保存がオフなら取り込まない）。E2 にその旨を書く。
- 通信なし・解析なしの方針は拡張にも同じく適用（`PrivacyInfo.xcprivacy` を拡張にも同梱）。

## 6. 状態管理・データ（追加分）

| 名前 | 種類 | 中身 |
|---|---|---|
| `URLRisk` | struct（非永続） | `kind`, `severity`（`.caution` / `.warning`）, 表示用文字列 |
| `CodeDisplayItem` | struct（非永続） | 種類・中身・タイトル。A2 に渡す |
| `WidgetSnapshot`（1.2） | Codable、App Group の JSON | `isPro: Bool`, `favorites: [{id, title, kind, symbology, content}]` |
| `PendingScan`（1.2） | Codable、App Group の JSON 配列 | 共有拡張で読んだ結果。アプリが取り込んだら消す |

SwiftData のスキーマは変えない（マイグレーションなし）。

## 7. ディレクトリ構成（追加分）

```
SeijitsuQR/
  Core/Encoding/CodeImageRenderer.swift        (1.1)
  Core/Parsing/URLRiskAnalyzer.swift           (1.1)
  Features/Result/CodeDisplayView.swift        (1.1)
  Core/Shared/AppGroupStore.swift              (1.2) WidgetSnapshot / PendingScan の読み書き
SeijitsuQRWidgets/                             (1.2) ウィジェット + コントロール
SeijitsuQRShare/                               (1.2) 共有拡張
SeijitsuQRTests/URLRiskAnalyzerTests.swift     (1.1)
SeijitsuQRTests/CodeImageRendererTests.swift   (1.1)
```

## 8. App Store・審査まわり

- 1.1 の「このバージョンの新機能」と、説明文の「できること」に A・C を追記する（API で設定）。
- 1.2 は Pro の内容が増える（ウィジェット）。課金画面（`PaywallView`）の機能一覧・App 内課金の説明・スクリーンショットを更新する。
- App Privacy は「データの収集なし」のまま（拡張も通信しない）。

## 9. 確認したいこと

1. 出す順番（1.1 = A・C、1.2 = B・D・E）でよいか
2. 無料 / Pro の分け方（B だけ Pro）でよいか
3. JAN/EAN など iOS で作れないバーコードは、1.1 では「表示できません」でよいか（自前で描くと作業が増える）
4. ウィジェットに Wi-Fi のパスワード入りの QR を出せてよいか（出せるが、選ぶ画面で注意を書く案）
