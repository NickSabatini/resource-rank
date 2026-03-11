import { NextResponse } from "next/server";
import type { ApiResponse } from "@/types";

export async function GET() {
  const response: ApiResponse<{ topics: [] }> = {
    success: true,
    data: { topics: [] },
  };

  return NextResponse.json(response, { status: 200 });
}

export async function POST(request: Request) {
  const body = (await request.json().catch(() => null)) as
    | { name?: string; description?: string }
    | null;

  if (!body?.name) {
    const response: ApiResponse = {
      success: false,
      error: "Topic name is required",
    };

    return NextResponse.json(response, { status: 400 });
  }

  const response: ApiResponse<{ topic: { name: string; description: string | null } }> = {
    success: true,
    data: {
      topic: {
        name: body.name,
        description: body.description ?? null,
      },
    },
  };

  return NextResponse.json(response, { status: 200 });
}
