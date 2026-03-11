import Link from "next/link";

type Topic = {
  id: string;
  name: string;
  slug: string;
  resourceCount: number;
};

type TopicListProps = {
  topics: Topic[];
};

export function TopicList({ topics }: TopicListProps) {
  if (topics.length === 0) {
    return <p className="text-sm text-black/70">No topics yet.</p>;
  }

  return (
    <ul className="space-y-2">
      {topics.map((topic) => (
        <li key={topic.id} className="rounded border border-black/10 p-3">
          <Link href={`/topics/${topic.slug}`} className="font-medium">
            {topic.name}
          </Link>
          <p className="text-sm text-black/70">{topic.resourceCount} resources</p>
        </li>
      ))}
    </ul>
  );
}
