import path from "path";

// NORMAN_ROOT is set by bin/dashboard.sh. Fallback resolves from dashboard/ up to repo root.
export const vaultRoot = process.env.NORMAN_ROOT
  ? path.resolve(process.env.NORMAN_ROOT)
  : path.resolve(process.cwd(), "..");
