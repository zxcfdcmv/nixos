# @ebony-vinyl/dsh-our-free-model 的 Nix bundle 包装。
#
# 这是一个第三方免费模型插件：免费车道走 OpenCode Zen / Kilo 公共网关，
# 不需要 API Key；另外的账号渠道才需要登录。
# 现在已挂进 nix-web 的 bundles。
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
  pname = "dsh-our-free-model";
  version = "2.8.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/@ebony-vinyl/dsh-our-free-model/-/dsh-our-free-model-2.8.0.tgz";
    hash = "sha256-+0gTDjnUXt1WKrGRJykJ6kIhPIUxfOOPsdsEXktQWZc=";
  };

  npmDeps = fetchNpmDeps {
    name = "${finalAttrs.pname}-${finalAttrs.version}-npm-deps";
    inherit (finalAttrs) src postPatch;
    hash = "sha256-BhfgIVSdI/bVz9dtWHEAQyio8LCMSQYZha00YjaTs0A=";
    forceEmptyCache = true;
    nativeBuildInputs = [ jq ];
  };

  nativeBuildInputs = [ jq ];
  installation = dsh-runtime;

  postPatch = ''
    # 插件的 cordis.patch.yml / client.js / updater 都硬编码裸包名
    # dsh-our-free-model；scoped npm 包名会让 loader 找不到模块。
    jq 'del(.scripts, .dependencies, .devDependencies, .peerDependencies) | .name = "dsh-our-free-model"' \
      package.json > package.json.tmp
    mv package.json.tmp package.json

    cp ${writers.writeJSON "package-lock.json" finalAttrs.passthru.packageLock} package-lock.json
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    appDir="$out/lib/node_modules/dsh-our-free-model"
    mkdir -p "$appDir"
    cp -r package.json cordis.patch.yml index.js client.js icon.svg \
      adapter locale src vendor "$appDir/"

    runHook postInstall
  '';

  passthru = {
    requiresWeb = true;
    packageLock = {
      name = "dsh-our-free-model";
      version = finalAttrs.version;
      lockfileVersion = 3;
      requires = true;
      packages."" = {
        name = "dsh-our-free-model";
        version = finalAttrs.version;
      };
    };
  };

  meta = {
    description = "Free frontier models for DeepSeek Harness via OpenCode Zen / Kilo";
    homepage = "https://github.com/Ebony-Vinyl/dsh-our-free-model";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
