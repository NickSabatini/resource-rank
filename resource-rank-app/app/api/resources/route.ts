import { NextResponse } from "next/server";
import type { ApiResponse } from "@/types";

export async function POST() {
  const response: ApiResponse = {
    success: false,
    error: "Not implemented",
  };

  return NextResponse.json(response, { status: 500 });
}
