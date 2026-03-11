import { ResourceList } from "@/components/features/resources/ResourceList";

type TopicPageProps = {
  params: Promise<{ slug: string }>;
};

export default async function TopicPage({ params }: TopicPageProps) {
  const { slug } = await params;

  return (
    <section className="space-y-4">
      <h1 className="text-3xl font-semibold capitalize">{slug}</h1>
      <p className="text-sm text-black/70">Ranked resources will appear here.</p>
      <ResourceList resources={[]} />
    </section>
  );
}
