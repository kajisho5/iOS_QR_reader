import { site } from "@/content/site";

export function Hero() {
  const badge = "rounded-xl border border-white/50 bg-white/15 px-6 py-3 text-[15px] font-bold text-white md:text-base";
  return (
    <section className="hero text-white">
      <div className="mx-auto flex max-w-[1072px] flex-col items-center px-4 py-10 text-center md:flex-row md:items-center md:justify-between md:py-[88px] md:text-left">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/app-icon.png" alt="" width={260} height={260} className="size-[104px] md:order-2 md:size-[260px]" />
        <div className="mt-5 md:mt-0">
          <h1 className="text-[28px] font-extrabold leading-tight md:text-5xl">{site.appName}</h1>
          <p className="mt-4 text-base font-semibold leading-[1.75] md:mt-6 md:text-[22px] md:leading-[1.65]">
            広告なし。サブスクなし。
            <br />
            読み取った内容は端末の外に出ません。
          </p>
          <p className="mt-3 hidden text-white/85 md:block">iPhone と iPad の QR コード・バーコードリーダー（{site.minimumOS}）</p>
          <div className="mt-8">
            {site.appStoreURL ? (
              <a href={site.appStoreURL} className={`inline-block ${badge} hover:bg-white/25`}>
                App Store でダウンロード
              </a>
            ) : (
              <p className={`inline-block ${badge}`}>App Store で近日公開</p>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
