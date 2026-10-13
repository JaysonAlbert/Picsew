# App Store Connect / TestFlight 操作指南

更新：2026-10-13。

## 用什么命令行

本项目已经用以下方式成功发布原生 iOS 构建：

| 工作                                         | 工具与入口                                                                          |
| -------------------------------------------- | ----------------------------------------------------------------------------------- |
| 编译、归档、签名和上传安装包                 | Apple 的 `/usr/bin/xcodebuild`；项目用 Node.js 脚本包装成 `npm run ios:release:*`   |
| 查询构建、编辑测试说明、关联测试组等管理操作 | Node.js 内置 `fetch` 调用 App Store Connect REST API，用团队 API Key 签发 ES256 JWT |
| Apple 网页上的补充操作                       | App Store Connect 页面；仅在现有 API 无法完成目标或需用户提供审核资料时使用         |

现有发布脚本是 `scripts/ios-native/release-environment.mjs`。项目的已验证
流程不要求先安装名为 `asc`、`appstoreconnect` 的第三方 CLI，也不依赖 Fastlane
或 App Store Connect MCP。管理 API 之前使用的是临时 Node.js 脚本；下文给出
可复用的临时脚本范例，不能假定仓库已有 `ios:testflight:*` 命令。

## Agent 开始前：先确认工作副本

本机主目录曾停在旧分支，新的发布脚本只在更新后的工作副本中。找不到
`asc` 可执行文件、MCP 或当前目录下的发布脚本，不代表没有发布能力或凭据。

先做一次有界检查：

```sh
git status --short
git log -1 --format='%h %s'
git worktree list
rg -n 'ios:release:' package.json
test -f scripts/ios-native/release-environment.mjs
```

脚本缺失时，检查已存在且更新到主分支的工作副本；可用
`git show origin/main:package.json` 核对已有命令。`origin/main` 也可能是旧的，
需要时按任务授权更新远端引用。不要重置、切换或清理有用户改动的工作副本，
也不要为了找发布工具遍历所有软件安装目录。修改发布代码时遵守项目的独立
分支与 worktree 规则。

原生发布目标固定为：

- 工程：`apps/ios-native/HostApp/PicsewNativeApp.xcodeproj`。
- Scheme：`PicsewNativeApp`。
- Bundle ID：`top.ibotcloud.picsew.native`。
- 版本与构建号：`apps/ios-native/HostApp/app-config.xcconfig`。
- 本地团队配置：`apps/ios-native/HostApp/local-signing.xcconfig`。

根目录 `ios/` 是过渡期 Capacitor shell，不能拿它替代原生发布目标。

## 凭据：复用已配置的团队 API Key

默认配置位于 `~/.config/picsew/app-store-connect.json`，包含以下字段：

| 字段       | 含义                              |
| ---------- | --------------------------------- |
| `keyPath`  | 仓库外 `.p8` 私钥的绝对路径       |
| `keyID`    | App Store Connect 团队 API Key ID |
| `issuerID` | 团队 API 的 Issuer ID             |

可通过 `PICSEW_ASC_CONFIG` 指定另一份配置的绝对路径。配置目录权限应为
700，配置和私钥权限为 600。使用项目中的
`scripts/ios-native/app-store-connect.example.json` 核对字段格式；不要输出真实
配置、私钥或 JWT，不把凭据、团队标识和审核联系资料提交到 Git。

```sh
npm run ios:release:auth
npm run ios:release:doctor
```

`auth` 验证本地配置与密钥格式；`doctor` 验证 Xcode 和系统 rsync。两者都不
代表 Apple 已接受上传。现有流程使用 Admin 团队 API Key 和云端托管的分发
签名；先复用该配置，不要重新创建、撤销密钥或要求用户重新登录。

## 安装包：归档、导出、上传

先按 [发布检查清单](ios-release-checklist.md) 完成相应验证和构建号变更。
产物与含团队信息的导出选项保存在忽略的 `.derived-data/` 下。

`ios:release:*` 包装器会把子进程 PATH 固定为
`/usr/bin:/bin:/usr/sbin:/sbin`，避免 Homebrew rsync 导致 Xcode 分发复制失败。

包装器目前没有 `archive` 子命令。以下归档范例从受保护配置读取认证参数，
把 Xcode 原始日志存到本地，而不是把认证标识打印进对话：

```sh
npm run ios:release:auth && node --input-type=module <<'NODE'
import { readFileSync, mkdirSync, openSync, closeSync } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';
import { runWithSystemPath } from './scripts/ios-native/release-environment.mjs';

const configPath = process.env.PICSEW_ASC_CONFIG
  ?? path.join(homedir(), '.config/picsew/app-store-connect.json');
const config = JSON.parse(readFileSync(configPath, 'utf8'));
const output = path.resolve('.derived-data/release-candidate');
mkdirSync(output, { recursive: true, mode: 0o700 });
const log = openSync(path.join(output, 'archive.log'), 'w', 0o600);
const result = runWithSystemPath('/usr/bin/xcodebuild', [
  '-project', 'apps/ios-native/HostApp/PicsewNativeApp.xcodeproj',
  '-scheme', 'PicsewNativeApp', '-configuration', 'Release',
  '-destination', 'generic/platform=iOS',
  '-archivePath', path.join(output, 'PicsewNativeApp.xcarchive'),
  '-derivedDataPath', path.join(output, 'derived-data'),
  '-allowProvisioningUpdates',
  '-authenticationKeyPath', config.keyPath,
  '-authenticationKeyID', config.keyID,
  '-authenticationKeyIssuerID', config.issuerID,
  'archive',
], { stdio: ['ignore', log, log] });
closeSync(log);
console.log(`Archive exit status: ${result.status}`);
process.exitCode = result.status ?? 1;
NODE
```

为导出和上传分别准备本地 plist；选项如下：

| 选项                             | 导出                                      | 上传                |
| -------------------------------- | ----------------------------------------- | ------------------- |
| `method`                         | `app-store-connect`                       | `app-store-connect` |
| `destination`                    | `export`                                  | `upload`            |
| `signingStyle`                   | `automatic`                               | `automatic`         |
| `teamID`                         | 本地签名配置中的团队 ID                   | 同左                |
| `manageAppVersionAndBuildNumber` | `false`                                   | `false`             |
| `testFlightInternalTestingOnly`  | 仅内部测试为 `true`；要外部测试为 `false` | 必须与导出目标一致  |

```sh
npm run ios:release:export -- \
  "$PWD/.derived-data/release-candidate/PicsewNativeApp.xcarchive" \
  "$PWD/.derived-data/release-candidate/export" \
  "$PWD/.derived-data/release-candidate/ExportOptions.plist" \
  > "$PWD/.derived-data/release-candidate/export.log" 2>&1 && \
npm run ios:release:upload -- \
  "$PWD/.derived-data/release-candidate/PicsewNativeApp.xcarchive" \
  "$PWD/.derived-data/release-candidate/upload" \
  "$PWD/.derived-data/release-candidate/UploadOptions.plist" \
  > "$PWD/.derived-data/release-candidate/upload.log" 2>&1
```

上传前检查 archive/IPA 的 bundle、版本、构建号、签名和资源；TestFlight
分发包应有 `get-task-allow=false`、`beta-reports-active=true`，不包含私钥或
私有录屏。Xcode 日志中的 `Upload succeeded` 只证明传输完成，之后仍需核对
Apple 处理状态和测试组可用性。

## 管理 API：可复用的临时 Node.js 命令

以下是文档范例，不是需要安装的独立 CLI。脚本使用 Node.js 22 的内置模块，
读取同一份私钥，签发十分钟有效的 JWT；不需要额外 npm 依赖。只执行用户
授权范围内的写操作，本指南本身不授权发布、添加测试员或启用公开邀请链接。

```sh
umask 077
PICSEW_ASC_WORK="$(mktemp -d /tmp/picsew-asc.XXXXXX)"
cat > "$PICSEW_ASC_WORK/asc.mjs" <<'NODE'
import { readFileSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { createPrivateKey, sign } from 'node:crypto';
import path from 'node:path';

async function main() {
  const [method, endpoint, bodyFile] = process.argv.slice(2);
  if (!['GET', 'POST', 'PATCH'].includes(method) || !endpoint?.startsWith('/v1/')) {
    throw new Error('Usage: node asc.mjs GET|POST|PATCH /v1/... [body.json]');
  }
  const configPath = process.env.PICSEW_ASC_CONFIG
    ?? path.join(homedir(), '.config/picsew/app-store-connect.json');
  if (!path.isAbsolute(configPath) || (statSync(configPath).mode & 0o077)) {
    throw new Error('Check private config path and file permissions.');
  }
  const config = JSON.parse(readFileSync(configPath, 'utf8'));
  if (!path.isAbsolute(config.keyPath) || (statSync(config.keyPath).mode & 0o077)) {
    throw new Error('Check private key path and file permissions.');
  }
  const key = createPrivateKey(readFileSync(config.keyPath));
  const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const input = `${encode({ alg: 'ES256', kid: config.keyID, typ: 'JWT' })}.${encode({
    iss: config.issuerID, iat: now, exp: now + 600, aud: 'appstoreconnect-v1',
  })}`;
  const token = `${input}.${sign('sha256', Buffer.from(input), {
    key, dsaEncoding: 'ieee-p1363',
  }).toString('base64url')}`;
  const response = await fetch(`https://api.appstoreconnect.apple.com${endpoint}`, {
    method, redirect: 'error', signal: AbortSignal.timeout(60000),
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: bodyFile ? JSON.stringify(JSON.parse(readFileSync(bodyFile, 'utf8'))) : undefined,
  });
  const raw = await response.text();
  const data = raw ? JSON.parse(raw) : null;
  if (!response.ok) {
    console.error(JSON.stringify({ status: response.status,
      errors: data?.errors?.map(({ code, title }) => ({ code, title })) }));
    process.exitCode = 1;
    return;
  }
  console.log(JSON.stringify(data ?? { status: response.status }, null, 2));
}
main().catch(() => {
  console.error('ASC request failed; check local config, request and connectivity.');
  process.exitCode = 1;
});
NODE

node "$PICSEW_ASC_WORK/asc.mjs" GET \
  '/v1/apps?filter[bundleId]=top.ibotcloud.picsew.native&fields[apps]=name,bundleId'
```

从返回值取得 App ID，再查询构建和测试组。下列 `APP_ID`、`BUILD_ID`、
`GROUP_ID` 必须替换为本次查询得到的值，不从旧会话或构建号推断资源 ID。
有分页时沿 `links.next` 继续读取；本范例限制请求路径为 `/v1/`，将 next URL
的 path 与 query 作为参数传入。

```sh
node "$PICSEW_ASC_WORK/asc.mjs" GET \
  '/v1/builds?filter[app]=APP_ID&sort=-uploadedDate&limit=10&include=preReleaseVersion,buildBetaDetail'
node "$PICSEW_ASC_WORK/asc.mjs" GET \
  '/v1/betaGroups?filter[app]=APP_ID&fields[betaGroups]=name,isInternalGroup,hasAccessToAllBuilds'
node "$PICSEW_ASC_WORK/asc.mjs" GET '/v1/betaGroups/GROUP_ID/builds?limit=100'
node "$PICSEW_ASC_WORK/asc.mjs" GET '/v1/builds/BUILD_ID/buildBetaDetail'
```

核对 `attributes.version`（构建号）、关联 `preReleaseVersion.attributes.version`
（营销版本）、`processingState`、`buildAudienceType`、`expired` 以及测试状态。
不要把两个 version 字段覆盖成同一个值。

读取测试组里的构建用 `/v1/betaGroups/{id}/builds`。
`GET /v1/builds/{id}/betaGroups` 曾返回不支持 GET_RELATED 的 403；不要将这种
关系接口错误解释成凭据失效，更不要据此要求用户重新登录。

常用写操作的 endpoint 和 JSON 如下。把 JSON 保存为权限 600 的本地文件，
再运行 `node "$PICSEW_ASC_WORK/asc.mjs" METHOD '/v1/...' /absolute/body.json`。
遇到结果不确定的写请求，先读当前状态再判断是否重试，避免重复提交审核。

| 操作                            | Method / endpoint                                   | 请求 JSON                                                                                                                                                                 |
| ------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 构建关联现有测试组              | `POST /v1/builds/BUILD_ID/relationships/betaGroups` | `{"data":[{"type":"betaGroups","id":"GROUP_ID"}]}`                                                                                                                        |
| 添加中文 What to Test           | `POST /v1/betaBuildLocalizations`                   | `{"data":{"type":"betaBuildLocalizations","attributes":{"locale":"zh-Hans","whatsNew":"测试说明"},"relationships":{"build":{"data":{"type":"builds","id":"BUILD_ID"}}}}}` |
| 提交 TestFlight Beta App Review | `POST /v1/betaAppReviewSubmissions`                 | `{"data":{"type":"betaAppReviewSubmissions","relationships":{"build":{"data":{"type":"builds","id":"BUILD_ID"}}}}}`                                                       |

创建测试说明前，先读 `/v1/builds/BUILD_ID/betaBuildLocalizations`；已有对应
locale 时用 `PATCH /v1/betaBuildLocalizations/LOCALIZATION_ID` 更新 `whatsNew`。
缺失出口合规时，核实候选代码的加密用途再决定
`PATCH /v1/builds/BUILD_ID` 的 `usesNonExemptEncryption`，不能机械复制旧答案。
历史构建 1.0 (4) 核实后使用的是 `false`。

不要把测试员邮件、审核联系人、私钥、JWT 或完整原始响应写入项目文档。
共享记录只保留目标版本、操作结果、验证状态和必要的公开资料。

## Friends 外部测试：实际操作顺序

1. 动态查询本 App 的测试组，找到名为 `Friends` 且 `isInternalGroup=false`
   的组；复用它，不创建重复组、不更改成员名单。
2. 检查目标构建已 `VALID`、未过期且允许外部测试。历史构建 1.0 (4) 按
   Internal Only 上传；其状态不是当前最新构建的默认值，必须读 Apple。
3. `INTERNAL_ONLY` 构建只能加入内部组，不能通过改组或提交 Beta Review
   转成外部构建。需要另一个允许外部测试的候选构建，递增共享构建号，并
   以 `testFlightInternalTestingOnly=false` 重新导出、上传和验证。
4. 检查 What to Test、测试信息、反馈邮箱、Beta Review 联系资料，以及有
   登录功能时的审核访问资料。沿用已有有效资料；缺失且无法从已授权资料
   取得时，只询问缺失信息，不编造联系人或密码。
5. 通过构建的 betaGroups 关系加入 `Friends`，按实际状态提交 Beta App
   Review。只有需要时提交；先检查现有审核状态，避免重复提交。
6. 首次外部构建需 Apple 审核。等待审核时报告“已提交／等待审核”，不能
   报告朋友可安装。已获批准但未启动分发时，在 `Friends` 中 Start Testing；
   自动通知选项是否开启必须核对，不能把批准等同于已经向组分发。
7. 再读 `/v1/betaGroups/GROUP_ID/builds` 与 buildBetaDetail，确认构建在
   `Friends` 且 `externalBuildState=IN_BETA_TESTING` 后，才报告外部测试可用。
   发邮件邀请、启用公开链接或改变测试员范围需要对应的用户授权。

Apple 的等待／审核状态是外部事实。没有 CLI/MCP 名称不构成操作阻塞；
缺少凭据、资料、权限或 Apple 审核未完成才是需要明确说明的限制。

## 本指南的验证边界

用途是固定已有发布入口及 Agent 操作顺序，不改变 app、发布配置或 Apple
账号状态。维护本文时核对 npm 入口、包装脚本、shell/JavaScript 范例语法和
文档链接；不要为了验证文档执行上传、邀请或审核提交。

## 官方资料

- [JWT 认证](https://developer.apple.com/documentation/appstoreconnectapi/generating-tokens-for-api-requests)。
- [关联构建与测试组](https://developer.apple.com/documentation/appstoreconnectapi/post-v1-builds-_id_-relationships-betagroups)。
- [读取测试组构建](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-betagroups-_id_-builds)。
- [提交 Beta Review](https://developer.apple.com/documentation/appstoreconnectapi/post-v1-betaappreviewsubmissions)。
- [外部测试与 Internal Only 限制](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers/)。
