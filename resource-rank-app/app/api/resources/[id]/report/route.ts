import { NextResponse } from "next/server";
import type { ApiResponse } from "@/types";

type ReportRouteProps = {
  params: Promise<{ id: string }>;
};

export async function POST(_request: Request, { params }: ReportRouteProps) {
  const { id } = await params;

  const response: ApiResponse<{ resourceId: string }> = {
    success: false,
    data: { resourceId: id },
    error: "Not implemented",
  };

  return NextResponse.json(response, { status: 500 });
}
