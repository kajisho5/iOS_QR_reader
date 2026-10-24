import type { Block } from "@/content/types";
import { Icon } from "./Icon";

export function Blocks({ blocks, tone = "text" }: { blocks: Block[]; tone?: "text" | "sub" }) {
  const color = tone === "sub" ? "text-sub" : "text-text";
  return (
    <>
      {blocks.map((block, i) => {
        switch (block.kind) {
          case "p":
            return (
              <p key={i} className={`mt-2 first:mt-0 ${color}`}>
                {block.text}
              </p>
            );
          case "list":
            return (
              <ul key={i} className="mt-2 space-y-1 first:mt-0">
                {block.items.map((item) => (
                  <li key={item} className={`relative pl-5 ${color} before:absolute before:left-1 before:top-[0.8em] before:size-1.5 before:rounded-full before:bg-brand`}>
                    {item}
                  </li>
                ))}
              </ul>
            );
          case "note":
            return (
              <p key={i} className="mt-4 rounded-xl border-l-4 border-brand bg-brand-soft px-4 py-3 text-sm leading-[1.7]">
                {block.text}
              </p>
            );
          case "link":
            return (
              <p key={i} className="mt-2">
                <a href={block.href} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 font-medium text-brand underline underline-offset-4">
                  {block.text}
                  <Icon name="external" size={16} />
                  <span className="sr-only">（新しいタブで開きます）</span>
                </a>
              </p>
            );
        }
      })}
    </>
  );
}
