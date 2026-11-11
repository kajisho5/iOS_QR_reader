# App Store 掲載の改善（1.1 で反映する）

> ステータス: **確定（2026-11-09）**。1.0.1 の承認後、1.1.0 を作るときに `appstore/listing.json` へ反映して `asc-listing` で設定する。
> 手順は利用者から受け取った「ASO 手順書」に従った（App Store Connect の変更は承認後のみ、推測の数値は使わない）。

## 根拠（Apple 公式、2026-11-09 確認）
- [App Store search](https://developer.apple.com/app-store/search/): Keywords は 100 characters、カンマ区切り。名前・サブタイトル・カテゴリの語を繰り返さない。競合のアプリ名・商標は入れない。Promotional text は検索順位に影響しない。
- [Creating Your Product Page](https://developer.apple.com/app-store/product-page/): Name / Subtitle は 30 characters。プレビューが無いと最初の 1〜3 枚のスクショが検索結果に出る。説明文の最初の一文が最重要。説明文に具体的な価格を書かない（地域で違う）。レビュー依頼は 365 日に 3 回まで。

## 現状（1.0.x）の監査
| 項目 | 判定 | 内容 |
|---|---|---|
| Name「誠実QRリーダー」 | OK | 8 文字。何のアプリか分かる。変えない |
| Subtitle「広告なし・サブスクなしのQRリーダー」 | 要改善 | 18 文字。「QRリーダー」が Name と重複 |
| Keywords | 要改善 | 46 / 100 文字。「広告なし」が Subtitle と重複 |
| 説明文 | 要改善 | 「¥800」が 2 か所（公式は価格を書かないよう求める） |
| 最初の 3 枚のスクショ | 要改善 | UI のみで便益の見出しなし |
| レビュー依頼 | OK | 読み取り成功 10 回超で 1 回だけ、純正 API |
| 計測 | 不明 | App Analytics の数値をもらってから |

## 1.1 で反映する内容
| 項目 | 新しい値 | 文字数（Python の len。最終は Connect の判定） |
|---|---|---|
| Subtitle | 広告なし・買い切り｜QRとバーコードを読み取り | 23 |
| Keywords | QRコード,読み取り,スキャン,スキャナー,作成,JAN,ISBN,WiFi,名刺,連絡先,URL,カメラ,写真,履歴,安全,プライバシー,オフライン,商品コード | 81 |
| 説明文 | 「¥800」を消し「Pro は一度買えばずっと使える買い切り」に。1.1 の機能（コードの再表示・URL の注意・商品コードの検索）を「できること」に追加 | — |

- Keywords の語が実際にどれだけ探されているかは測っていない（仮説）。「ISBN」「商品コード」は 1.1 の機能があるので 1.1 から入れる。
- スクショの見出し（1: URL の結果「開く前に、URL を全部見せる」/ 2: 履歴「読んだ中身は、この iPhone の中だけ」/ 3: 作成「広告なし。買い切りで、ずっと使える」）は、画像の作り直しが要るため、デザイン（SVG）を確認してから別に行う。

## 計測
公開後、App Analytics で impressions・product page views・conversion rate・downloads・Pro の購入を変更前後で見る。同時に変えた項目が多いので、単一の要因で効果を断定しない。
