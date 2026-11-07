# dsh-tool-search 的 Nix bundle 包装。
#
# 上游 npm 包没有运行时依赖，只有 dsh peer；这里删掉 package.json 里的
# scripts/deps，用最小的 package-lock 让 buildNpmPackage 走通，再通过
# installation = dsh-runtime 把安装里的 peer 模块共享进来。
{
  lib,
  fetchurl,
  fetchNpmDeps,
  buildDshBundle,
  dsh-runtime,
  jq,
  writers,
}:

buildDshBundle (finalAttrs: {
  pname = "dsh-tool-search";
  version = "0.1.10";

  src = fetchurl {
    url = "https://registry.npmjs.org/dsh-tool-search/-/dsh-tool-search-0.1.10.tgz";
    hash = "sha256-d4f/Z56LhgzF8UVNSuVQHOYxvf3+mPk97vkPhnqcGsQ=";
  };

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src postPatch;
    hash = "sha256-8lPk4ChhcYL8lnWltS2b2B3aAjdH1UpOpflmtu407jg=";
    forceEmptyCache = true;
    nativeBuildInputs = [ jq ];
  };

  nativeBuildInputs = [ jq ];
  installation = dsh-runtime;

  postPatch = ''
    jq 'del(.scripts, .dependencies, .devDependencies, .peerDependencies)' \
      package.json > package.json.tmp
    mv package.json.tmp package.json

    cp ${writers.writeJSON "package-lock.json" finalAttrs.passthru.packageLock} package-lock.json
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    appDir="$out/lib/node_modules/dsh-tool-search"
    mkdir -p "$appDir"
    cp -r package.json cordis.patch.yml lib "$appDir/"

    runHook postInstall
  '';

  passthru = {
    requiresWeb = true;
    packageLock = {
      name = "dsh-tool-search";
      version = finalAttrs.version;
      lockfileVersion = 3;
      requires = true;
      packages."" = {
        name = "dsh-tool-search";
        version = finalAttrs.version;
      };
    };
  };

  meta = {
    description = "Tool search and slimming for DeepSeek Harness";
    homepage = "https://github.com/Letter2025/dsh-tool-search";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
