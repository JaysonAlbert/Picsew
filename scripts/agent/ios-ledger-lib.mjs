import fs from "node:fs";
import path from "node:path";

export const VALID_PRIORITIES = new Set(["P0", "P1", "P2"]);
export const VALID_STATUSES = new Set([
  "baseline",
  "active",
  "planned",
  "blocked",
]);
export const VALID_AREAS = new Set([
  "shell",
  "upload",
  "processing",
  "preview",
  "feedback",
  "automation",
]);
export const VALID_SCENARIOS = new Set([
  "onboarding",
  "upload",
  "processing",
  "preview",
  "feedback",
]);

export function loadLedger(ledgerPath) {
  return JSON.parse(fs.readFileSync(ledgerPath, "utf8"));
}

export function validateLedger(ledger, { repoRoot }) {
  assert(typeof ledger === "object" && ledger !== null, "Ledger must be an object.");
  assert(ledger.version === 1, "Ledger version must be 1.");
  assert(ledger.surface === "ios-native", "Ledger surface must be ios-native.");
  assert(
    typeof ledger.updatedAt === "string" && ledger.updatedAt.length > 0,
    "Ledger updatedAt must be a non-empty string.",
  );
  assert(
    Array.isArray(ledger.defaultSmokeCommands) &&
      ledger.defaultSmokeCommands.length > 0,
    "Ledger defaultSmokeCommands must be a non-empty array.",
  );
  assert(Array.isArray(ledger.features) && ledger.features.length > 0, "Ledger features must be a non-empty array.");

  const seenIds = new Set();

  for (const feature of ledger.features) {
    assert(
      typeof feature.id === "string" && feature.id.length > 0,
      "Each feature must have a non-empty id.",
    );
    assert(!seenIds.has(feature.id), `Duplicate feature id: ${feature.id}`);
    seenIds.add(feature.id);

    assert(
      typeof feature.title === "string" && feature.title.length > 0,
      `Feature ${feature.id} must have a non-empty title.`,
    );
    assert(
      VALID_AREAS.has(feature.area),
      `Feature ${feature.id} must use a supported area.`,
    );
    assert(
      VALID_PRIORITIES.has(feature.priority),
      `Feature ${feature.id} must use a supported priority.`,
    );
    assert(
      VALID_STATUSES.has(feature.status),
      `Feature ${feature.id} must use a supported status.`,
    );
    assert(
      Array.isArray(feature.docs) && feature.docs.length > 0,
      `Feature ${feature.id} must list at least one doc.`,
    );
    assert(
      Array.isArray(feature.validators) && feature.validators.length > 0,
      `Feature ${feature.id} must list at least one validator.`,
    );

    if (feature.automationScenario !== undefined) {
      assert(
        VALID_SCENARIOS.has(feature.automationScenario),
        `Feature ${feature.id} must use a supported automationScenario.`,
      );
    }

    for (const docPath of feature.docs) {
      assert(
        typeof docPath === "string" && docPath.length > 0,
        `Feature ${feature.id} doc paths must be non-empty strings.`,
      );
      assert(
        fs.existsSync(path.join(repoRoot, docPath)),
        `Feature ${feature.id} references missing doc: ${docPath}`,
      );
    }

    for (const validator of feature.validators) {
      assert(
        typeof validator === "string" && validator.length > 0,
        `Feature ${feature.id} validators must be non-empty strings.`,
      );
    }
  }

  return ledger;
}

export function summarizeLedger(ledger) {
  const byStatus = {};
  const byArea = {};

  for (const feature of ledger.features) {
    byStatus[feature.status] = (byStatus[feature.status] ?? 0) + 1;
    byArea[feature.area] = (byArea[feature.area] ?? 0) + 1;
  }

  return {
    featureCount: ledger.features.length,
    byStatus,
    byArea,
  };
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}
