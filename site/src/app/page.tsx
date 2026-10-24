import { FeaturesAndPrice } from "@/components/FeaturesAndPrice";
import { Hero } from "@/components/Hero";
import { PageShell } from "@/components/PageShell";
import { PromiseCards } from "@/components/PromiseCards";

export default function HomePage() {
  return (
    <PageShell active="top">
      <Hero />
      <PromiseCards />
      <FeaturesAndPrice />
    </PageShell>
  );
}
