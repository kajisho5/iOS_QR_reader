import { externalLinks } from "./site";
import type { LegalDoc } from "./types";

export const privacy: LegalDoc = {
  title: "プライバシーポリシー",
  description: "誠実QRリーダーは利用者の情報を収集しません。端末の中だけで扱う情報とアクセス権限について説明します。",
  enactedOn: "2026-10-24",
  updatedOn: "2026-10-24",
  lead: "本アプリは利用者の情報を収集しません。開発者のサーバーへ情報を送る仕組みもありません。",
  sections: [
    {
      id: "policy",
      heading: "基本方針",
      blocks: [{ kind: "p", text: "読み取り・作成・履歴の保存は、すべて端末の中だけで行います。アプリ自身はネットワーク通信を行いません。" }],
    },
    {
      id: "on-device",
      heading: "端末の中だけで扱う情報",
      blocks: [
        {
          kind: "list",
          items: [
            "カメラの映像：コードを読み取るためだけに使い、保存も送信もしません。",
            "写真から読み取るときに選んだ画像：端末内で解析するだけで、保存も送信もしません。写真ライブラリ全体へのアクセス権限は求めません。",
            "読み取り・作成の履歴と設定：端末内に保存します。アプリから個別または全件を削除でき、アプリを削除するとすべて消えます。",
          ],
        },
        { kind: "note", text: "端末のバックアップ（iCloud バックアップなど）を有効にしている場合、OS の機能によって履歴がバックアップに含まれることがあります。" },
      ],
    },
    {
      id: "permissions",
      heading: "アクセス権限",
      blocks: [
        { kind: "p", text: "いずれも、その機能を使うときにだけ OS の確認画面が出ます。許可しなくても、ほかの機能は使えます。" },
        {
          kind: "list",
          items: [
            "カメラ：コードの読み取り",
            "写真ライブラリへの追加：作成した QR コードの画像の保存",
            "連絡先：読み取った連絡先を「連絡先」アプリに追加するとき",
            "Wi-Fi の設定：読み取った Wi-Fi に接続するとき。ネットワーク名とパスワードを OS に渡します",
          ],
        },
      ],
    },
    {
      id: "tracking",
      heading: "アクセス解析・広告・トラッキング",
      blocks: [{ kind: "p", text: "アクセス解析、広告、トラッキングの仕組みは使っていません。トラッキングの許可も求めません。" }],
    },
    {
      id: "apple",
      heading: "Apple が提供する機能",
      blocks: [
        { kind: "p", text: "App 内課金とレビューの依頼は Apple の仕組みで処理されます。開発者は支払い情報を受け取りません。Apple による情報の扱いは、Apple のプライバシーポリシーに従います。" },
        { kind: "link", text: "Apple のプライバシーポリシー", href: externalLinks.applePrivacy },
      ],
    },
    {
      id: "external",
      heading: "外部のサイトやアプリ",
      blocks: [{ kind: "p", text: "読み取った URL や電話番号は、利用者が「開く」などを押したときだけ、ブラウザや電話アプリに渡します。渡した先での情報の扱いは、そのサイトやアプリの方針に従います。" }],
    },
    {
      id: "third-party",
      heading: "第三者への提供",
      blocks: [{ kind: "p", text: "利用者の情報を収集していないため、第三者に提供することもありません。" }],
    },
    {
      id: "contact",
      heading: "お問い合わせで受け取る情報",
      blocks: [{ kind: "p", text: "お問い合わせのメールで受け取った内容とメールアドレスは、回答のためだけに使います。" }],
    },
    {
      id: "changes",
      heading: "改定",
      blocks: [{ kind: "p", text: "内容を変えるときは、このページで改定日とともにお知らせします。" }],
    },
  ],
};
