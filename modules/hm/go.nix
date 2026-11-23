# Go / 云原生开发环境
#
# 说明：
#   - 编译器、LSP、linter、调试器都走 nixpkgs，版本随 flake.lock 固定，可回滚。
#   - 只有 nixpkgs 里没有的工具（controller-gen）才用 `go install`，
#     它们会落到 $GOBIN（已加入 sessionPath）。
#   - envtest 不联网下载：直接用 nixpkgs 的 kube-apiserver / etcd / kubectl
#     在 ~/envtest 下拼一个 KUBEBUILDER_ASSETS 目录。
{ config, lib, pkgs, ... }:
let
  homeDirectory = config.home.homeDirectory;
in
{
  home.packages = with pkgs; [
    # --- Go 工具链 ---
    go              # go build / run / test / mod
    gcc             # cgo 需要（`go test -race` 必须有 C 编译器）
    gopls           # 语言服务器，Zed 直接指向这个二进制
    gotools         # goimports / godoc / gorename
    gomodifytags    # 快速改 struct tag（json/yaml）
    gotestsum       # 比原生 go test 好读的输出
    delve           # dlv 调试器
    golangci-lint   # 聚合 linter（go vet + staticcheck + ...）

    # --- 云原生 ---
    kubebuilder     # operator 脚手架
    k3d             # 一次性 k3s 集群，破坏性实验专用
    stern           # 多 pod 聚合日志（调控制器必备）
    kubectx         # 切 context / namespace

    # --- envtest 依赖（本机起一个真 apiserver 做测试）---
    kubernetes      # 提供 kube-apiserver
    etcd
  ];

  # go install 出来的二进制
  home.sessionPath = [
    "${homeDirectory}/go/bin"
  ];

  home.sessionVariables = {
    GOPATH = "${homeDirectory}/go";
    GOBIN = "${homeDirectory}/go/bin";
    # 国内代理：模块下载与校验和都走 goproxy.cn
    GOPROXY = "https://goproxy.cn,direct";
    # 注意：必须是 sum.golang.org（走 goproxy.cn 代理），
    # sum.golang.google.cn 在当前网络下 IPv6 连不通
    GOSUMDB = "sum.golang.org";
    # 禁止 go 自动下载新 toolchain（国内容易卡住，且会让环境不可复现）
    GOTOOLCHAIN = "local";
    # envtest 的二进制目录，见下方 activation
    KUBEBUILDER_ASSETS = "${homeDirectory}/envtest";
  };

  # envtest 要求一个目录里同时有 etcd / kube-apiserver / kubectl。
  # 用软链指向 nix store：升级 nixpkgs 后重新 switch 会自动指向新版本。
  home.activation.envtestAssets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${homeDirectory}/envtest"
    $DRY_RUN_CMD ln -sfn ${pkgs.etcd}/bin/etcd "${homeDirectory}/envtest/etcd"
    $DRY_RUN_CMD ln -sfn ${pkgs.kubernetes}/bin/kube-apiserver "${homeDirectory}/envtest/kube-apiserver"
    $DRY_RUN_CMD ln -sfn ${pkgs.kubectl}/bin/kubectl "${homeDirectory}/envtest/kubectl"
  '';
}
