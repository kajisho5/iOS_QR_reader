import { externalLinks } from "./site";
import type { FaqItem } from "./types";

export const faq: FaqItem[] = [
  {
    id: "restore",
    question: "購入した Pro が反映されない",
    answer: [{ kind: "p", text: "設定画面の「購入を復元」を押してください。購入時と同じ Apple ID でサインインしている必要があります。" }],
  },
  {
    id: "refund",
    question: "返金したい",
    answer: [
      { kind: "p", text: "App Store での購入の返金は Apple が受け付けています。「問題を報告する」から申請してください。" },
      { kind: "link", text: "問題を報告する（Apple）", href: externalLinks.reportProblem },
    ],
  },
  {
    id: "camera",
    question: "カメラが真っ暗で使えない",
    answer: [{ kind: "p", text: "iPhone の「設定」→「誠実QRリーダー」で、カメラをオンにしてください。写真から読み取る機能は、カメラの許可がなくても使えます。" }],
  },
  {
    id: "wifi",
    question: "Wi-Fi に接続できない",
    answer: [{ kind: "p", text: "コードに含まれる暗号化方式やパスワードが、実際の設定と違う可能性があります。結果画面の「パスワードをコピー」で、手動で接続することもできます。" }],
  },
  {
    id: "history",
    question: "履歴が 30 件で消える",
    answer: [{ kind: "p", text: "無料版では最新の 30 件を保存します。Pro にすると件数の上限がなくなります。" }],
  },
  {
    id: "devices",
    question: "対応している端末は？",
    answer: [{ kind: "p", text: "iOS 17 / iPadOS 17 以降の iPhone と iPad です。" }],
  },
];
