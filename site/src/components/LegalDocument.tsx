import type { LegalDoc } from "@/content/types";
import { Blocks } from "./Blocks";
import { TocHighlighter } from "./TocHighlighter";

const formatDate = (iso: string) => {
  const [y, m, d] = iso.split("-").map(Number);
  return `${y}年${m}月${d}日`;
};

export function LegalDocument({ doc }: { doc: LegalDoc }) {
  return (
    <div className="mx-auto max-w-[1072px] px-4 pt-10 md:grid md:grid-cols-[260px_minmax(0,680px)] md:gap-[60px] md:pt-16">
      <aside className="hidden md:block">
        <TableOfContents doc={doc} className="sticky top-24" highlight />
        <TocHighlighter ids={doc.sections.map((s) => s.id)} />
      </aside>
      <article>
        <h1 className="text-[26px] font-extrabold leading-snug md:text-[34px]">{doc.title}</h1>
        <p className="mt-2 text-[13px] text-sub md:text-sm">
          制定日 <time dateTime={doc.enactedOn}>{formatDate(doc.enactedOn)}</time> ・ 最終改定日{" "}
          <time dateTime={doc.updatedOn}>{formatDate(doc.updatedOn)}</time>
        </p>
        <p className="mt-6 rounded-2xl bg-brand-soft px-5 py-4 font-semibold leading-[1.75] md:px-7 md:py-5 md:text-[17px]">{doc.lead}</p>
        <div className="mt-6 rounded-2xl border border-line bg-surface px-5 py-4 md:hidden">
          <TableOfContents doc={doc} />
        </div>
        {doc.sections.map((section, i) => (
          <section key={section.id} id={section.id} className="mt-11">
            <h2 className="mb-2 text-xl font-bold leading-snug">
              {i + 1}. {section.heading}
            </h2>
            <Blocks blocks={section.blocks} />
          </section>
        ))}
      </article>
    </div>
  );
}

function TableOfContents({ doc, className = "", highlight = false }: { doc: LegalDoc; className?: string; highlight?: boolean }) {
  return (
    <nav aria-label="目次" className={className}>
      <p className="text-sm font-bold text-sub">目次</p>
      <ol className="mt-2 space-y-1 text-[15px] md:text-sm">
        {doc.sections.map((section, i) => (
          <li key={section.id}>
            <a
              href={`#${section.id}`}
              data-toc-link={highlight ? section.id : undefined}
              className="block rounded-lg py-0.5 text-brand hover:underline md:-mx-3 md:px-3 md:py-1 md:text-text md:hover:bg-brand-soft md:hover:text-brand md:hover:no-underline md:data-active:bg-brand-soft md:data-active:font-bold md:data-active:text-brand"
            >
              {i + 1}. {section.heading}
            </a>
          </li>
        ))}
      </ol>
    </nav>
  );
}
