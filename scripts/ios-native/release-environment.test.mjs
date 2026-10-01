import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { generateKeyPairSync } from "node:crypto";
import {
  existsSync,
  mkdtempSync,
  mkdirSync,
  writeFileSync,
  readFileSync,
  rmSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, URL } from "node:url";

import { runWithSystemPath } from "./release-environment.mjs";

test("API-key authentication accepts a complete private local configuration without exposing values", () => {
  const root = mkdtempSync(path.join(tmpdir(), "picsew-api-auth-"));
  try {
    const keyPath = path.join(root, "AuthKey_TESTKEY123.p8");
    const configPath = path.join(root, "app-store-connect.json");
    const { privateKey } = generateKeyPairSync("ec", {
      namedCurve: "prime256v1",
    });
    writeFileSync(
      keyPath,
      privateKey.export({ type: "pkcs8", format: "pem" }),
      { mode: 0o600 },
    );
    writeFileSync(
      configPath,
      JSON.stringify({
        keyPath,
        keyID: "TESTKEY123",
        issuerID: "11111111-2222-3333-4444-555555555555",
      }),
      { mode: 0o600 },
    );
    const result = spawnSync(
      process.execPath,
      [
        fileURLToPath(new URL("./release-environment.mjs", import.meta.url)),
        "auth",
      ],
      {
        env: { ...process.env, PICSEW_ASC_CONFIG: configPath },
        encoding: "utf8",
      },
    );
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /API-key configuration ready/);
    assert.doesNotMatch(
      result.stdout + result.stderr,
      /TESTKEY123|11111111|PRIVATE KEY/,
    );
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test("API-key authentication rejects malformed or incomplete configuration without exposing supplied values", () => {
  const root = mkdtempSync(path.join(tmpdir(), "picsew-api-auth-invalid-"));
  try {
    const configPath = path.join(root, "app-store-connect.json");
    for (const content of [
      "PRIVATE_SENTINEL invalid JSON",
      JSON.stringify({ keyID: "PRIVATE_SENTINEL" }),
    ]) {
      writeFileSync(configPath, content, { mode: 0o600 });
      const result = spawnSync(
        process.execPath,
        [
          fileURLToPath(new URL("./release-environment.mjs", import.meta.url)),
          "auth",
        ],
        {
          env: { ...process.env, PICSEW_ASC_CONFIG: configPath },
          encoding: "utf8",
        },
      );
      assert.equal(result.status, 1);
      assert.match(result.stderr, /Invalid App Store Connect configuration/);
      assert.doesNotMatch(result.stdout + result.stderr, /PRIVATE_SENTINEL/);
    }
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
});

test(
  "native Xcode-style copying succeeds despite an incompatible rsync on caller PATH",
  {
    skip: process.platform !== "darwin" && "Requires Apple's rsync",
  },
  () => {
    const root = mkdtempSync(path.join(tmpdir(), "picsew release copy "));
    try {
      const source = path.join(root, "source files");
      const destination = path.join(root, "copied files");
      const incompatibleBin = path.join(root, "incompatible bin");
      for (const dir of [source, destination, incompatibleBin]) mkdirSync(dir);
      writeFileSync(
        path.join(source, "check.txt"),
        "Picsew distribution content",
      );
      writeFileSync(
        path.join(incompatibleBin, "rsync"),
        "#!/bin/sh\necho 'incompatible child rsync' >&2\nexit 64\n",
        { mode: 0o755 },
      );
      const env = {
        ...process.env,
        PATH: `${incompatibleBin}:${process.env.PATH}`,
      };
      const args = ["-8aPhhE", `${source}/`, `${destination}/`];

      const baseline = spawnSync("/usr/bin/rsync", args, {
        env,
        encoding: "utf8",
      });
      assert.notEqual(
        baseline.status,
        0,
        "The contaminated PATH must reproduce failure",
      );
      assert.match(baseline.stderr, /incompatible child rsync/);

      const released = runWithSystemPath("/usr/bin/rsync", args, {
        env,
        encoding: "utf8",
      });
      assert.equal(released.status, 0, released.stderr);
      assert.equal(
        readFileSync(path.join(destination, "check.txt"), "utf8"),
        "Picsew distribution content",
      );
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  },
);

test("release children preserve unrelated environment without changing caller PATH", () => {
  const callerPath = process.env.PATH;
  const env = {
    ...process.env,
    PATH: "/incompatible/tools",
    PICSEW_RELEASE_PROBE: "kept",
  };
  const result = runWithSystemPath(
    process.execPath,
    ["-e", "process.stdout.write(process.env.PICSEW_RELEASE_PROBE)"],
    { env, encoding: "utf8" },
  );
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, "kept");
  assert.equal(env.PATH, "/incompatible/tools");
  assert.equal(process.env.PATH, callerPath);
});

test("release runner preserves child failure status", () => {
  const result = runWithSystemPath(process.execPath, [
    "-e",
    "process.exit(37)",
  ]);
  assert.equal(result.status, 37);
});

test(
  "doctor completes its real native copy check",
  {
    skip: process.platform !== "darwin" && "Requires Xcode and Apple's rsync",
  },
  () => {
    const result = spawnSync(
      process.execPath,
      [
        fileURLToPath(new URL("./release-environment.mjs", import.meta.url)),
        "doctor",
      ],
      { encoding: "utf8" },
    );
    assert.equal(result.status, 0, result.stderr);
    assert.match(result.stdout, /System rsync copy passed/);
  },
);

test(
  "upload rejects export-only options before invoking Apple distribution",
  {
    skip: process.platform !== "darwin" && "Requires Apple's plutil",
  },
  () => {
    const root = mkdtempSync(path.join(tmpdir(), "picsew-release-options-"));
    try {
      const archive = path.join(root, "candidate.xcarchive");
      const options = path.join(root, "options.plist");
      mkdirSync(archive);
      writeFileSync(options, JSON.stringify({ destination: "export" }));
      const result = spawnSync(
        process.execPath,
        [
          fileURLToPath(new URL("./release-environment.mjs", import.meta.url)),
          "upload",
          archive,
          path.join(root, "output"),
          options,
        ],
        { encoding: "utf8" },
      );
      assert.equal(result.status, 1);
      assert.match(result.stderr, /destination must be upload/);
      assert.equal(existsSync(path.join(root, "output")), false);
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  },
);
