# billion-context 的 Nix bundle 包装。
#
# 上游 npm 包名是 billion-context（不是 @ranxianglei/billion-context，
# 那是 GitHub repo 名）。它是 ACP 上下文压缩后端，会接管 compaction-basic。
#
# 为什么仓库里要带 billion-context-package-lock.json：
# npm tarball 不自带 lock，而且 package.json 的 devDependencies 里有
# file:./kernel、file:./pi-subagents，npm tarball 不带这两个目录。
# 这里用一份“只含运行期依赖”的 production lock，保证 buildNpmPackage
# 的依赖可复现。
#
# 升级步骤：
# 1. 改 version / src.url / src.hash（nix-prefetch-url 拿 hash）
# 2. 临时目录里放一个只含 dependencies + optionalDependencies 的
#    package.json，执行：
#      npm install --package-lock-only --omit=dev --ignore-scripts
# 3. 用生成的 package-lock.json 替换 ./billion-context-package-lock.json
# 4. 把 npmDeps.hash 改成 lib.fakeHash，nix build，把报错里的 got
#    填回 npmDeps.hash
{
  lib,
  fetchurl,
  fetchNpmDeps,
  buildDshBundle,
  dsh-runtime,
  jq,
}:

buildDshBundle (finalAttrs: {
  pname = "billion-context";
  version = "0.1.212";

  src = fetchurl {
    url = "https://registry.npmjs.org/billion-context/-/billion-context-0.1.212.tgz";
    hash = "sha256-dnKU4MjDwulEy8zky4WDqotw4bg8VW/I/afTdY/gTus=";
  };

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src postPatch;
    hash = "sha256-segMfnlrGZ+3vgTFY4yN9ppp8YY4xmZsLUWHfgtoKrU=";
    forceEmptyCache = true;
    nativeBuildInputs = [ jq ];
  };

  nativeBuildInputs = [ jq ];
  installation = dsh-runtime;

  postPatch = ''
    # devDependencies 里有 file:./kernel / file:./pi-subagents，
    # npm tarball 不带这两个目录；运行期只需要 mysql2/zod/jimp。
    jq 'del(.devDependencies, .scripts, .workspaces)' \
      package.json > package.json.tmp
    mv package.json.tmp package.json

    cp ${./billion-context-package-lock.json} package-lock.json
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    appDir="$out/lib/node_modules/billion-context"
    mkdir -p "$appDir"
    cp -r . "$appDir/"

    runHook postInstall
  '';

  passthru.requiresWeb = true;

  meta = {
    description = "ACP context compression for DeepSeek Harness";
    homepage = "https://github.com/ranxianglei/billion-context";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
