import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import { vaultRoot } from "@/lib/vault";

type Routine = {
  name: string;
  schedule: string;
  enabled: boolean;
  fallback_type: string;
};

function parseFrontmatter(content: string): Record<string, string> {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  const result: Record<string, string> = {};
  for (const line of match[1].split("\n")) {
    const colonIdx = line.indexOf(":");
    if (colonIdx === -1) continue;
    const key = line.slice(0, colonIdx).trim();
    const value = line.slice(colonIdx + 1).trim().replace(/^"|"$/g, "");
    result[key] = value;
  }
  return result;
}

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
