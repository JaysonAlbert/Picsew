import { spawnSync } from "node:child_process";
import console from "node:console";
import { createPrivateKey } from "node:crypto";
import {
  existsSync,
  mkdtempSync,
  mkdirSync,
  writeFileSync,
  readFileSync,
  rmSync,
  statSync,
} from "node:fs";
import { homedir, tmpdir } from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, URL } from "node:url";

const systemPath = "/usr/bin:/bin:/usr/sbin:/sbin";

function authenticationArgs() {
  const explicit = process.env.PICSEW_ASC_CONFIG;
  const configPath =
    explicit ?? path.join(homedir(), ".config/picsew/app-store-connect.json");
  if (!existsSync(configPath) && explicit === undefined) return [];
  try {
    if (!path.isAbsolute(configPath)) throw new Error();
    const configStat = statSync(configPath);
    if (!configStat.isFile() || (configStat.mode & 0o077) !== 0)
      throw new Error();
    const config = JSON.parse(readFileSync(configPath, "utf8"));
    if (
      typeof config.keyPath !== "string" ||
      !path.isAbsolute(config.keyPath) ||
      typeof config.keyID !== "string" ||
      !/^[A-Z0-9]{10}$/.test(config.keyID) ||
      typeof config.issuerID !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        config.issuerID,
      )
    )
      throw new Error();
    const keyStat = statSync(config.keyPath);
    if (!keyStat.isFile() || (keyStat.mode & 0o077) !== 0) throw new Error();
    const privateKey = createPrivateKey(readFileSync(config.keyPath));
    if (
      privateKey.asymmetricKeyType !== "ec" ||
      privateKey.asymmetricKeyDetails?.namedCurve !== "prime256v1"
    )
      throw new Error();
    return [
      "-authenticationKeyPath",
      config.keyPath,
      "-authenticationKeyID",
      config.keyID,
      "-authenticationKeyIssuerID",
      config.issuerID,
    ];
  } catch {
    throw new Error(
      "Invalid App Store Connect configuration. Check JSON fields, absolute keyPath, key ID, issuer ID, and private file permissions (600).",
    );
  }
}

export function runWithSystemPath(command, args, options = {}) {
  return spawnSync(command, args, {
    ...options,
    env: { ...(options.env ?? process.env), PATH: systemPath },
  });
}

function checked(command, args, options = {}) {
  const result = runWithSystemPath(command, args, options);
  if (result.error || result.status !== 0) {
    const error = new Error(
      result.error?.message ?? `${command} exited with status ${result.status}`,
    );
    error.exitCode = result.status ?? 1;
    throw error;
  }
  return result.stdout?.toString().trim();
}

function requirePath(value) {
  if (!value || !existsSync(value))
    throw new Error(`Path does not exist: ${value ?? "(missing)"}`);
  return path.resolve(value);
}

function doctor() {
  checked("/usr/bin/rsync", ["--version"], { stdio: "inherit" });
  checked("/usr/bin/xcodebuild", ["-version"], { stdio: "inherit" });
  const root = mkdtempSync(path.join(tmpdir(), "picsew-release-doctor-"));
  try {
    const source = path.join(root, "source");
    const destination = path.join(root, "destination");
    mkdirSync(source);
    mkdirSync(destination);
    writeFileSync(path.join(source, "check.txt"), "Picsew distribution copy");
    checked("/usr/bin/rsync", ["-8aPhhE", `${source}/`, `${destination}/`]);
    if (
      readFileSync(path.join(destination, "check.txt"), "utf8") !==
      "Picsew distribution copy"
    ) {
      throw new Error("Distribution copy verification failed");
    }
    console.log(
      "System rsync copy passed. Apple account/signing status is checked during distribution.",
    );
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
}

function main(mode, args) {
  if (mode === "auth" && args.length === 0) {
    const authentication = authenticationArgs();
    if (!authentication.length)
      throw new Error("App Store Connect API-key configuration is missing.");
    console.log(
      "API-key configuration ready. Apple authentication and signing are checked during export/upload.",
    );
    return;
  }
  if (process.platform !== "darwin")
    throw new Error("Native release commands require macOS and Xcode.");
  if (mode === "doctor" && args.length === 0) return doctor();
  if (mode === "xcode" && args.length <= 1) {
    const running = runWithSystemPath("/usr/bin/pgrep", ["-x", "Xcode"]);
    if (running.error || ![0, 1].includes(running.status))
      throw new Error("Cannot check whether Xcode is running.");
    if (running.status === 0)
      throw new Error(
        "Xcode is already running with its existing environment. Quit Xcode normally, then rerun ios:release:xcode.",
      );
    const developerDir = checked("/usr/bin/xcode-select", ["-p"], {
      encoding: "utf8",
    });
    if (!developerDir.endsWith(".app/Contents/Developer"))
      throw new Error(
        "Select a full Xcode installation before launching the release environment.",
      );
    const app = path.resolve(developerDir, "../..");
    const project = fileURLToPath(
      new URL(
        "../../apps/ios-native/HostApp/PicsewNativeApp.xcodeproj",
        import.meta.url,
      ),
    );
    checked(
      "/usr/bin/open",
      [
        "--env",
        `PATH=${systemPath}`,
        "-a",
        app,
        requirePath(args[0] ?? project),
      ],
      { stdio: "inherit" },
    );
    console.log(
      "Launched Xcode with system tools. Continue distribution in Organizer.",
    );
    return;
  }
  if (["export", "upload"].includes(mode) && args.length === 3) {
    const authentication = authenticationArgs();
    const archive = requirePath(args[0]);
    const output = path.resolve(args[1]);
    const options = requirePath(args[2]);
    const destination = checked(
      "/usr/bin/plutil",
      ["-extract", "destination", "raw", "-o", "-", options],
      { encoding: "utf8" },
    );
    if (destination !== mode)
      throw new Error(
        `Export-options destination must be ${mode}; found ${destination}.`,
      );
    checked(
      "/usr/bin/xcodebuild",
      [
        "-exportArchive",
        "-archivePath",
        archive,
        "-exportPath",
        output,
        "-exportOptionsPlist",
        options,
        "-allowProvisioningUpdates",
        ...authentication,
      ],
      { stdio: "inherit" },
    );
    return;
  }
  throw new Error(
    "Usage: release-environment.mjs doctor | auth | xcode [project-or-archive] | export|upload <archive> <output-directory> <export-options-plist>",
  );
}

if (
  process.argv[1] &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  try {
    main(process.argv[2], process.argv.slice(3));
  } catch (error) {
    console.error(`Picsew release: ${error.message}`);
    process.exitCode = error.exitCode ?? 1;
  }
}
