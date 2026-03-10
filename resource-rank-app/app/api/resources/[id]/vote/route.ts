import { NextResponse } from "next/server";
import type { ApiResponse } from "@/types";

type VoteRouteProps = {
  params: Promise<{ id: string }>;
};

export async function POST(_request: Request, { params }: VoteRouteProps) {
  const { id } = await params;

  const response: ApiResponse<{ resourceId: string }> = {
    success: false,
    data: { resourceId: id },
    error: "Not implemented",
  };

  return NextResponse.json(response, { status: 500 });
}
