import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";

import { loadLedger, summarizeLedger, validateLedger } from "./ios-ledger-lib.mjs";

const currentDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(currentDir, "..", "..");
const ledgerPath = path.join(repoRoot, "agent", "ios-feature-ledger.json");

test("real iOS ledger validates and summarizes expected baseline coverage", () => {
  const ledger = loadLedger(ledgerPath);

  validateLedger(ledger, { repoRoot });

  const summary = summarizeLedger(ledger);
  assert.equal(summary.featureCount, 6);
  assert.equal(summary.byStatus.baseline, 5);
  assert.equal(summary.byStatus.planned, 1);
});

test("duplicate feature ids are rejected", () => {
  const ledger = {
    version: 1,
    surface: "ios-native",
    updatedAt: "2026-03-30",
    defaultSmokeCommands: ["npm run ios:harness:check"],
    features: [
      {
        id: "ios.preview.export",
        title: "Preview",
        area: "preview",
        priority: "P0",
        status: "baseline",
        docs: ["docs/features/native-ios-agent-harness-foundation.md"],
        validators: ["swift test --package-path apps/ios-native/PicsewApp"],
      },
      {
        id: "ios.preview.export",
        title: "Preview duplicate",
        area: "preview",
        priority: "P0",
        status: "baseline",
        docs: ["docs/features/native-ios-agent-harness-foundation.md"],
        validators: ["swift test --package-path apps/ios-native/PicsewApp"],
      },
    ],
  };

  assert.throws(() => validateLedger(ledger, { repoRoot }), /Duplicate feature id/);
});
