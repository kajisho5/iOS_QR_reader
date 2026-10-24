import { promises } from "@/content/site";
import { Icon } from "./Icon";

export function PromiseCards() {
  return (
    <section aria-labelledby="promises" className="mx-auto mt-12 max-w-[1072px] px-4 md:mt-[72px]">
      <h2 id="promises" className="text-[22px] font-extrabold md:text-center md:text-3xl">
        3つの約束
      </h2>
      <ul className="mt-5 grid gap-3 md:mt-9 md:grid-cols-3 md:gap-6">
        {promises.map((p) => (
          <li key={p.title} className="flex gap-4 rounded-2xl border border-line bg-surface p-5 md:flex-col md:p-7">
            <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-brand-soft text-brand md:size-12">
              <Icon name={p.icon} size={24} />
            </span>
            <div>
              <h3 className="text-[17px] font-bold md:text-xl">{p.title}</h3>
              <p className="mt-1 text-sm leading-[1.6] text-sub md:mt-2 md:text-[15px] md:leading-[1.75]">{p.body}</p>
            </div>
          </li>
        ))}
      </ul>
    </section>
  );
}
