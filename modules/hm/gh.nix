{ pkgs, lib, ... }:

let
  gh-wrapped = pkgs.writeShellScriptBin "gh" ''
    export GH_TOKEN=$(${lib.getExe pkgs.rbw} get github-token)
    exec ${lib.getExe pkgs.gh} "$@"
  '';

  # 搜索仓库
  ghs = pkgs.writeShellScriptBin "ghs" ''
    GH_TOKEN=$(${pkgs.rbw}/bin/rbw get github-token)
    export GH_TOKEN
  
    cache=$(mktemp /tmp/ghs-cache.XXXXXX)
    export GHS_CACHE="$cache"
  
    preview=$(mktemp /tmp/ghs-preview.XXXXXX)
    trap 'rm -f "$cache" "$preview"' EXIT
  
    cat > "$preview" << 'EOF'
  #!/usr/bin/env bash
  name=$(printf '%s' "$1" | sed 's/[[:space:]]*$//')
  printf "\033[1;33m星标:\033[0m %s\n" "$2"
  printf "\033[1;35m更新:\033[0m %s\n\n" "$3"
  printf "\033[1;36m描述:\033[0m\n"
  awk -F"\t" -v n="$name" '
    {gsub(/[[:space:]]+$/, "", $1)}
    $1 == n {print $4; exit}
  ' "$GHS_CACHE"
  EOF
    chmod +x "$preview"
  
    echo "正在搜索..."
    ${pkgs.gh}/bin/gh search repos "$@" --limit 100 --sort stars --order desc \
      --json fullName,stargazersCount,updatedAt,description \
      | ${pkgs.jq}/bin/jq -r '.[] | [
          (.fullName | if length > 38 then .[0:38] + ".." else . end),
          .stargazersCount,
          (.updatedAt | split("T")[0]),
          (.description // "无描述" | gsub("[\n\r\t]"; " ") | if test("^\\s*$") then "无描述" else . end),
          .fullName
        ] | @tsv' \
      | awk -F'\t' 'BEGIN {OFS="\t"} {printf "%-40s\t%8s\t%12s\t%s\t%s\n", $1, $2, $3, $4, $5}' \
      > "$cache"
  
    echo "共 $(wc -l < "$cache") 个结果"
  
    while true; do
      selected=$(cat "$cache" | ${pkgs.fzf}/bin/fzf --delimiter '\t' --with-nth 1,2,3 \
        --tabstop=1 \
        --preview "$preview {1} {2} {3}" \
        --preview-window=right:50%:wrap \
        | ${pkgs.coreutils}/bin/cut -f5)
    
      [ -z "$selected" ] && break
    
      ${pkgs.gh}/bin/gh repo view "$selected"
    
      echo ""
      echo "按 Enter 回到列表，Ctrl-C 完全退出"
      read -r
    done
  '';

  # 查看仓库文件内容
  ghb = pkgs.writeShellScriptBin "ghb" ''
    GH_TOKEN=$(${pkgs.rbw}/bin/rbw get github-token)
    export GH_TOKEN
  
    if [ $# -eq 0 ]; then
      echo "用法: ghb owner/repo [branch]"
      exit 1
    fi
  
    repo="$1"
    branch="''${2:-$(${pkgs.gh}/bin/gh api "repos/$repo" --jq '.default_branch')}"
  
    cache=$(mktemp /tmp/ghb-cache.XXXXXX)
    preview=$(mktemp /tmp/ghb-preview.XXXXXX)
    trap 'rm -f "$cache" "$preview"' EXIT
  
    cat > "$preview" << EOF
  #!/usr/bin/env bash
  file="\$1"
  ${pkgs.gh}/bin/gh api "repos/$repo/contents/\$file?ref=$branch" --jq '.content' 2>/dev/null | ${pkgs.coreutils}/bin/base64 -d | ${pkgs.bat}/bin/bat --color=always --style=numbers --line-range :50 2>/dev/null || echo "无法预览"
  EOF
    chmod +x "$preview"
  
    echo "正在获取文件列表: $repo ($branch)..."
    ${pkgs.gh}/bin/gh api "repos/$repo/git/trees/$branch?recursive=1" \
      --jq '.tree[] | select(.type=="blob") | .path' \
      > "$cache"
  
    echo "共 $(wc -l < "$cache") 个文件"
  
    while true; do
      selected=$(cat "$cache" | ${pkgs.fzf}/bin/fzf --preview "$preview {}" --preview-window=right:60%:wrap)
    
      [ -z "$selected" ] && break
    
      ${pkgs.gh}/bin/gh api "repos/$repo/contents/$selected?ref=$branch" --jq '.content' | ${pkgs.coreutils}/bin/base64 -d | ${pkgs.bat}/bin/bat --color=always --style=numbers
    
      echo ""
      echo "按 Enter 回到列表，Ctrl-C 完全退出"
      read -r
    done
  '';
in
{
  programs.gh = {
    enable = true;
    package = gh-wrapped;
    settings = {
      git_protocol = "ssh";
      editor = "hx";
      prompt = "enabled";
      pager = "bat";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
        web = "repo view --web";
      };
    };
  };

  home.packages = [ ghs ghb ];
}
