import { TopicList } from "@/components/features/topics/TopicList";

const seedTopics = [
  { id: "1", name: "Coding", slug: "coding", resourceCount: 0 },
  { id: "2", name: "Sales", slug: "sales", resourceCount: 0 },
  { id: "3", name: "Skiing", slug: "skiing", resourceCount: 0 },
];

export default function Home() {
  return (
    <section className="space-y-4">
      <h1 className="text-3xl font-semibold">Discover Topics</h1>
      <p className="text-sm text-black/70">
        ResourceRank is a community-curated board of the best learning resources per
        topic.
      </p>
      <TopicList topics={seedTopics} />
    </section>
  );
}
