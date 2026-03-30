import console from "node:console";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { loadLedger, summarizeLedger, validateLedger } from "./ios-ledger-lib.mjs";

const currentDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(currentDir, "..", "..");
const ledgerPath = path.join(repoRoot, "agent", "ios-feature-ledger.json");

const ledger = loadLedger(ledgerPath);
validateLedger(ledger, { repoRoot });
const summary = summarizeLedger(ledger);

console.log(`Validated ${path.relative(repoRoot, ledgerPath)}`);
console.log(`Surface: ${ledger.surface}`);
console.log(`Updated: ${ledger.updatedAt}`);
console.log(`Features: ${summary.featureCount}`);
console.log(`Status counts: ${formatCounts(summary.byStatus)}`);
console.log(`Area counts: ${formatCounts(summary.byArea)}`);

function formatCounts(counts) {
  return Object.entries(counts)
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([key, value]) => `${key}=${value}`)
    .join(", ");
}
