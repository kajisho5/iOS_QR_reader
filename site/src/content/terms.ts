import { externalLinks } from "./site";
import type { LegalDoc } from "./types";

export const terms: LegalDoc = {
  title: "利用規約",
  description: "誠実QRリーダーの利用規約です。Pro（買い切り）の扱いや免責事項について定めます。",
  enactedOn: "2026-10-24",
  updatedOn: "2026-10-24",
  lead: "本アプリを使う前にお読みください。本アプリを使うことで、この規約に同意したものとみなします。",
  sections: [
    {
      id: "scope",
      heading: "適用",
      blocks: [
        { kind: "p", text: "この規約は、誠実QRリーダー（以下「本アプリ」）の利用に適用します。Apple の標準使用許諾契約（EULA）とあわせて適用されます。" },
        { kind: "link", text: "Apple の標準使用許諾契約（EULA）", href: externalLinks.appleEula },
      ],
    },
    {
      id: "pro",
      heading: "Pro（買い切り）",
      blocks: [
        {
          kind: "list",
          items: [
            "一度の購入で、同じ Apple ID でサインインしている端末で使えます。定期的な課金はありません。",
            "機種変更や再インストールのあとは、設定画面の「購入を復元」で再び使えるようになります。",
            "返金は Apple の手続きに従います。",
          ],
        },
      ],
    },
    {
      id: "content",
      heading: "読み取った内容について",
      blocks: [{ kind: "p", text: "コードに含まれる内容（URL など）が安全かどうかは保証しません。開く前に、表示された内容を確認してください。" }],
    },
    {
      id: "prohibited",
      heading: "禁止事項",
      blocks: [{ kind: "list", items: ["法令に違反する目的での利用", "本アプリの改変、解析、再配布"] }],
    },
    {
      id: "disclaimer",
      heading: "免責",
      blocks: [
        { kind: "p", text: "開発者は、故意または重大な過失がある場合を除き、本アプリの利用によって生じた損害について責任を負いません。" },
        { kind: "p", text: "本アプリは、予告なく内容の変更や提供の終了をすることがあります。" },
      ],
    },
    {
      id: "changes",
      heading: "規約の変更",
      blocks: [{ kind: "p", text: "規約を変えるときは、このページで改定日とともにお知らせします。" }],
    },
    {
      id: "law",
      heading: "準拠法",
      blocks: [{ kind: "p", text: "この規約は日本法に従って解釈します。" }],
    },
  ],
};
