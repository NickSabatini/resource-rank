import { VoteButtons } from "@/components/features/resources/VoteButtons";

type Resource = {
  id: string;
  title: string;
  url: string;
  score: number;
};

type ResourceListProps = {
  resources: Resource[];
};

export function ResourceList({ resources }: ResourceListProps) {
  if (resources.length === 0) {
    return <p className="text-sm text-black/70">No resources for this topic yet.</p>;
  }

  return (
    <ul className="space-y-3">
      {resources.map((resource) => (
        <li key={resource.id} className="rounded border border-black/10 p-3">
          <a href={resource.url} className="font-medium" target="_blank" rel="noreferrer">
            {resource.title}
          </a>
          <p className="text-sm text-black/70">Score: {resource.score}</p>
          <VoteButtons resourceId={resource.id} />
        </li>
      ))}
    </ul>
  );
}
