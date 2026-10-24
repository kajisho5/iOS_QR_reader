import Link from "next/link";
import { PageShell } from "@/components/PageShell";

export default function NotFound() {
  return (
    <PageShell active="top">
      <div className="mx-auto max-w-[712px] px-4 pt-16 text-center">
        <h1 className="text-[26px] font-extrabold">ページが見つかりません</h1>
        <p className="mt-3 text-sub">URL が変わったか、ページが削除された可能性があります。</p>
        <Link href="/" className="mt-8 inline-block rounded-xl bg-brand px-6 py-3 font-bold text-white dark:text-[#0e1211]">
          トップへ戻る
        </Link>
      </div>
    </PageShell>
  );
}
