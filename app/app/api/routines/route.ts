import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import { vaultRoot } from "@/lib/vault";
import { parseFrontmatter } from "@/lib/frontmatter";

type Routine = {
  name: string;
  schedule: string;
  enabled: boolean;
  fallback_type: string;
};

export async function GET() {
  const routinesDir = path.join(vaultRoot, "vault", "Norman", "Routines");

  let filenames: string[];
  try {
    filenames = fs
      .readdirSync(routinesDir)
      .filter((f) => f.endsWith(".md") && f !== "_template.md");
  } catch {
    return NextResponse.json([]);
  }

  const routines: Routine[] = filenames.map((filename) => {
    const content = fs.readFileSync(path.join(routinesDir, filename), "utf-8");
    const fm = parseFrontmatter(content);
    return {
      name: fm.name ?? filename.replace(/\.md$/, ""),
      schedule: fm.schedule ?? "",
      enabled: fm.enabled !== "false",
      fallback_type: fm.fallback_type ?? "",
    };
  });

  return NextResponse.json(routines);
}
