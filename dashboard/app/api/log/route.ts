import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import { vaultRoot } from "@/lib/vault";

export async function GET() {
  const today = new Date().toISOString().slice(0, 10);
  const logPath = path.join(vaultRoot, "vault", "Norman", "Log", `${today}.md`);

  let content: string | null = null;
  try {
    content = fs.readFileSync(logPath, "utf-8");
  } catch {
    // file doesn't exist
  }

  return NextResponse.json({ date: today, content });
}
