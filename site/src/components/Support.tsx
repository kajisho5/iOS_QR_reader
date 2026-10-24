import { faq } from "@/content/faq";
import { site } from "@/content/site";
import { Blocks } from "./Blocks";
import { Icon } from "./Icon";

export function ContactCard() {
  return (
    <section aria-labelledby="contact" className="mt-6 rounded-2xl border border-line bg-surface p-5 md:p-7">
      <div className="flex items-center gap-4">
        <span className="flex size-10 items-center justify-center rounded-full bg-brand-soft text-brand">
          <Icon name="mail" />
        </span>
        <h2 id="contact" className="text-[17px] font-bold">
          お問い合わせ
        </h2>
      </div>
      {site.contactEmail ? (
        <a href={`mailto:${site.contactEmail}`} className="mt-4 inline-block text-[15px] font-semibold text-brand underline underline-offset-4">
          {site.contactEmail}
        </a>
      ) : null}
      <p className="mt-2 text-[13px] leading-[1.7] text-sub">不具合のご報告・ご意見はメールでお送りください。</p>
    </section>
  );
}

export function FaqList() {
  return (
    <section aria-labelledby="faq" className="mt-11">
      <h2 id="faq" className="text-[22px] font-extrabold">
        よくある質問
      </h2>
      <div className="mt-5 space-y-2.5">
        {faq.map((item, i) => (
          <details key={item.id} id={item.id} open={i === 0} className="group rounded-[14px] border border-line bg-surface">
            <summary className="flex cursor-pointer list-none items-center justify-between gap-4 px-5 py-4 font-semibold">
              {item.question}
              <Icon name="chevron" className="shrink-0 text-sub transition-transform group-open:rotate-180" />
            </summary>
            <div className="mx-5 border-t border-line py-4 text-[15px] leading-[1.75]">
              <Blocks blocks={item.answer} tone="sub" />
            </div>
          </details>
        ))}
      </div>
    </section>
  );
}
