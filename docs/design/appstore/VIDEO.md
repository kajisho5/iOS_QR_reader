# App Store 用動画（ヘッダ・検索結果）設計書（Step 1）

> ステータス: **確定・実装済み（2026-10-24）**。実装は `appstore/video/`（`npm run render:header` / `npm run render:search`）。絵コンテは `docs/design/appstore/storyboard-header.svg`（ヘッダ 21:9）と
> `storyboard-search.svg`（検索結果 3:2）。生成元は `docs/design/appstore/src/storyboard.js`。

## 1. 目的と仕様

App Store の製品ページのヘッダと検索結果に流す動画（iOS 27 / iPadOS 27 以降で表示）。

| 置き場所 | 縦横比・解像度 | 長さ | 形式 | 音 |
|---|---|---|---|---|
| 製品ページのヘッダ | 21:9・3840×1646 | 15 秒（ループ） | .mp4（H.264）30fps | なし（最初は消音で再生され、見る人が音を出せる。今回は音を入れない） |
| 検索結果 | 3:2・3840×2560 | 15 秒（ループ） | .mp4（H.264）30fps | なし（検索結果では音を出せない） |

出典: [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications/)、
[App Store Asset Best Practices](https://developer.apple.com/app-store/asset-best-practices/)

**守ること（Apple のガイドラインから）**
- 価格・割引・URL・©を入れない → 購入画面（¥800 が写る）は使わない
- 裏付けのない主張を入れない → 言うのはアプリの事実だけ（広告なし・サブスクなし・端末内で完結）
- 大事な要素は中央に置く。文字は短いフレーズにする。年齢制限 4+ に合う内容にする
- 検索結果では「何のアプリか」が一目で分かるよう、実際の画面を見せる

## 2. 構成（15 秒・ループ）

| 時間 | シーン | 見出し（補足） | 内容 |
|---|---|---|---|
| 0.0–1.5 秒 | ① 読み取り | — | 緑の背景の中央に QR コード（図）。四隅の枠が近づいて合う |
| 1.5–3.0 秒 | ② 読み取れた | — | 枠が緑に光って波紋が広がる |
| 3.0–6.0 秒 | ③ かざすだけ | かざすだけ。 | QR が小さくなりながら左へ。中央右に iPhone が下から上がり、実際の「URL の結果画面」を表示 |
| 6.0–9.0 秒 | ④ 余計なものはない | 余計なものは、入れていない。（広告も、アクセス解析も。） | iPhone は「履歴」画面 |
| 9.0–12.0 秒 | ⑤ 買い切り | 毎月の支払いは、いらない。（必要なら、一度買うだけ。） | iPhone は「作成」画面。価格は出さない |
| 12.0–13.8 秒 | ⑥ 端末の中だけ | 読んだ中身は、どこにも送らない。（ぜんぶ、この iPhone の中で。） | 鍵のアイコン。iPhone は「履歴」画面 |
| 13.8–15.0 秒 | ⑦ 締め | 誠実QRリーダー（ちゃんと、読むだけ。） | アプリアイコンとアプリ名。最後の 0.4 秒で①へつなぎ、ループの継ぎ目を見せない |

**文言の方針**: 「〜なし」と言い切る説明調を避け、短い見出しと小さな補足で、作り手の姿勢として伝える。書くのはアプリの事実だけ（アプリ自身は通信しない、広告・解析なし、課金は買い切りのみ）。

- **画面の中身**: CI で撮った実際のスクリーンショット（URL・履歴・作成）を使う。架空の機能は描かない。冒頭の QR と枠はアプリアイコンと同じ図柄（`docs/design/icon/src`）、締めのアイコンは fresnel で描き出した Liquid Glass の見た目（`public/icon-glass.png`）
- **動き**: 0.4〜0.6 秒のスプリング（Remotion の `spring`）。文字は下から 24px ずつ上がりながらフェードイン。切り替えはクロスフェード 0.3 秒
- **色・書体**: アイコン・サイトと同じ緑（背景 `#0F7F68 → #0A5F4E` のグラデーション、白文字）。書体は Noto Sans CJK JP（太字）
- **安全な領域**: ヘッダは左右の端が切れることがあるため、文字と iPhone を中央 60% の幅に収める

検索結果（3:2）は同じ流れで、iPhone を大きく中央に、フレーズを上に置く。

## 3. 技術構成

| 項目 | 採用 |
|---|---|
| 動画生成 | Remotion 4.0.538 + React + TypeScript（指定どおり React ベース） |
| スタイル | インラインスタイル（Remotion の推奨。Tailwind は使わない） |
| 書き出し | `npx remotion render`（H.264 / yuv420p / 30fps）。このセッションの Chromium で書き出す |
| 置き場所 | `appstore/video/`（アプリのビルドには含めない） |

```
appstore/video/
├── package.json / tsconfig.json / remotion.config.ts
├── public/            # スクリーンショット（JPEG）とアプリアイコン
└── src/
    ├── index.ts       # registerRoot
    ├── Root.tsx       # Composition: Header（3840×1646）、Search（3840×2560）
    ├── Promo.tsx      # 共通のシーン構成（layout = "header" | "search"）
    ├── scenes/        # ScanScene, ResultScene, MessageScene
    └── components/    # Phone（端末の枠）, QRGlyph, Reticle, Caption, LockIcon
```

**ライセンス**: Remotion は、個人・従業員 3 人以下の営利団体・非営利団体なら商用でも無料。それより大きい組織は会社ライセンスが必要（同梱の LICENSE.md より）。

## 4. 確認したいこと

1. この構成（7 シーン・15 秒）と文言でよいか
2. ヘッダと検索結果を同じ流れにしてよいか（検索結果は別の内容にもできる）
