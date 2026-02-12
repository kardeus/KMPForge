#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${KMPFORGE_HOME:-$HOME/.kmpforge}"
BIN_DIR="${KMPFORGE_BIN_DIR:-$HOME/.local/bin}"
REPO_URL="${KMPFORGE_REPO_URL:-https://github.com/kardeus/KMPForge.git}"

canonical_path() {
  local p="$1"
  mkdir -p "$p"
  (cd "$p" && pwd -P)
}

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[INFO] updating existing install: $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
else
  if [[ -e "$INSTALL_DIR" ]]; then
    echo "[ERROR] install path exists but is not a git repo: $INSTALL_DIR"
    echo "기존 디렉토리를 정리하거나 KMPFORGE_HOME을 다른 경로로 지정하세요."
    exit 1
  fi
  if [[ -d "$REPO_URL" ]]; then
    SRC_CANON="$(canonical_path "$REPO_URL")"
    INSTALL_PARENT_CANON="$(canonical_path "$(dirname "$INSTALL_DIR")")"
    INSTALL_CANON="$INSTALL_PARENT_CANON/$(basename "$INSTALL_DIR")"

    if [[ "$INSTALL_CANON" == "$SRC_CANON"* ]]; then
      echo "[ERROR] local source 내부 경로로 설치할 수 없습니다."
      echo "source: $SRC_CANON"
      echo "install: $INSTALL_CANON"
      echo "KMPFORGE_HOME을 소스 외부 경로(예: ~/.kmpforge)로 지정하세요."
      exit 1
    fi

    echo "[INFO] copying local source: $REPO_URL -> $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a \
        --exclude ".git" \
        --exclude ".tmp*" \
        --exclude ".DS_Store" \
        "$REPO_URL"/ "$INSTALL_DIR"/
    else
      tar -C "$REPO_URL" \
        --exclude ".git" \
        --exclude ".tmp*" \
        --exclude ".DS_Store" \
        -cf - . | tar -C "$INSTALL_DIR" -xf -
    fi
  else
    echo "[INFO] cloning: $REPO_URL -> $INSTALL_DIR"
    git clone --depth 1 "$REPO_URL" "$INSTALL_DIR"
  fi
fi

mkdir -p "$BIN_DIR"
chmod +x "$INSTALL_DIR/bin/kmpforge" "$INSTALL_DIR/scripts/init/"*.sh "$INSTALL_DIR/install.sh"
ln -sfn "$INSTALL_DIR/bin/kmpforge" "$BIN_DIR/kmpforge"

echo "[OK] installed: $BIN_DIR/kmpforge"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "[OK] PATH already includes $BIN_DIR"
    ;;
  *)
    echo "[ACTION REQUIRED] PATH에 $BIN_DIR 추가 필요"
    echo "zsh: echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
    ;;
esac

echo ""
echo "Try:"
echo "  kmpforge help"
echo "  kmpforge init --name MyApp --package com.example.myapp --target ./MyApp"
