#!/usr/bin/env bash
set -euo pipefail
srcDir="$1"      # /nix/store/xxx-sbxlm
linkDir="$2"     # $HOME/.local/share/fcitx5/rime
mkdir -p "$linkDir"
find "$srcDir" -mindepth 1 -maxdepth 1 -exec ln -sfn {} "$linkDir/" \;
