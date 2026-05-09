import path from "path";

export const vaultRoot = process.env.NORMAN_ROOT
  ? path.resolve(process.env.NORMAN_ROOT)
  : path.resolve(__dirname, "../..");
