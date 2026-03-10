type VoteButtonsProps = {
  resourceId: string;
};

export function VoteButtons({ resourceId }: VoteButtonsProps) {
  return (
    <div className="flex gap-2">
      <button type="button" className="rounded border border-black/10 px-2 py-1 text-sm">
        Upvote
      </button>
      <button type="button" className="rounded border border-black/10 px-2 py-1 text-sm">
        Downvote
      </button>
      <span className="sr-only">Voting controls for {resourceId}</span>
    </div>
  );
}
