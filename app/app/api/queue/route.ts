import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import { vaultRoot } from "@/lib/vault";
import { parseFrontmatter } from "@/lib/frontmatter";

type QueueItem = {
  filename: string;
  description: string;
  type: string;
  status: string;
  added_at: string;
};

export async function GET() {
  const queueDir = path.join(vaultRoot, "vault", "Norman", "Queue");

  let filenames: string[];
  try {
    filenames = fs
      .readdirSync(queueDir)
      .filter((f) => f.endsWith(".md") && f !== "_template.md");
  } catch {
    return NextResponse.json([]);
  }

  const items: QueueItem[] = filenames.map((filename) => {
    const content = fs.readFileSync(path.join(queueDir, filename), "utf-8");
    const fm = parseFrontmatter(content);
    return {
      filename,
      description: fm.description ?? "",
      type: fm.type ?? "",
      status: fm.status ?? "",
      added_at: fm.added_at ?? "",
    };
  });

  return NextResponse.json(items);
}
