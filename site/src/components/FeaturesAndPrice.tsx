import { features, plans } from "@/content/site";
import { Icon } from "./Icon";

export function FeaturesAndPrice() {
  return (
    <div className="mx-auto mt-12 grid max-w-[1072px] gap-12 px-4 md:mt-20 md:grid-cols-[600px_1fr] md:gap-10">
      <section aria-labelledby="features">
        <h2 id="features" className="text-[22px] font-extrabold md:text-[26px]">
          できること
        </h2>
        <ul className="mt-4 grid gap-y-2 md:mt-6 md:grid-cols-2 md:gap-x-5 md:gap-y-3">
          {features.map((f) => (
            <li key={f} className="flex items-center gap-2.5">
              <Icon name="check" size={22} className="shrink-0 text-brand" />
              {f}
            </li>
          ))}
        </ul>
      </section>
      <section aria-labelledby="price">
        <h2 id="price" className="text-[22px] font-extrabold md:text-[26px]">
          価格
        </h2>
        <div className="mt-5 rounded-2xl border border-line bg-surface px-5 py-4 md:px-7">
          <div className="flex items-baseline justify-between text-[17px] font-bold">
            <span>{plans.free.name}</span>
            <span>{plans.free.price}</span>
          </div>
          <p className="mt-1 text-sm leading-[1.6] text-sub">{plans.free.body}</p>
          <hr className="my-4 border-line" />
          <div className="flex items-baseline justify-between text-[17px] font-bold text-brand">
            <span>{plans.pro.name}</span>
            <span className="font-extrabold">{plans.pro.price}</span>
          </div>
          <p className="mt-1 text-sm leading-[1.6] text-sub">{plans.pro.body}</p>
          <p className="mt-2 text-xs leading-[1.6] text-sub">{plans.pro.note}</p>
        </div>
      </section>
    </div>
  );
}
