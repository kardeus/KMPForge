#!/usr/bin/env bash
set -euo pipefail

TEMPLATE_SOURCE="${1:?template source is required}"
TARGET_DIR="${2:?target dir is required}"
APP_NAME="${3:?app name is required}"
BASE_PACKAGE="${4:?base package is required}"

if [[ ! -d "$TEMPLATE_SOURCE" ]]; then
  echo "[ERROR] template source not found: $TEMPLATE_SOURCE"
  exit 1
fi

if [[ ! "$BASE_PACKAGE" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
  echo "[ERROR] invalid BASE_PACKAGE: $BASE_PACKAGE"
  echo "예: com.kardeus.myapp"
  exit 1
fi

mkdir -p "$TARGET_DIR"

if command -v rsync >/dev/null 2>&1; then
  rsync -a \
    --exclude ".git" \
    --exclude ".gradle" \
    --exclude ".idea" \
    --exclude "build" \
    --exclude "*/build" \
    --exclude "local.properties" \
    --exclude ".DS_Store" \
    "$TEMPLATE_SOURCE"/ "$TARGET_DIR"/
else
  tar -C "$TEMPLATE_SOURCE" \
    --exclude ".git" \
    --exclude ".gradle" \
    --exclude ".idea" \
    --exclude "build" \
    --exclude "*/build" \
    --exclude "local.properties" \
    --exclude ".DS_Store" \
    -cf - . | tar -C "$TARGET_DIR" -xf -
fi

old_pkg_path="com/example/sample"
new_pkg_path="$(printf '%s' "$BASE_PACKAGE" | tr '.' '/')"

while IFS= read -r old_dir; do
  base_root="${old_dir%/$old_pkg_path}"
  new_dir="$base_root/$new_pkg_path"

  mkdir -p "$(dirname "$new_dir")"

  if [[ -d "$new_dir" ]]; then
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "$old_dir"/ "$new_dir"/
    else
      cp -R "$old_dir"/. "$new_dir"/
    fi
    find "$old_dir" -type f -delete 2>/dev/null || true
    find "$old_dir" -depth -type d -exec rmdir {} \; 2>/dev/null || true
  else
    mv "$old_dir" "$new_dir"
  fi

  find "$base_root/com" -depth -type d -exec rmdir {} \; 2>/dev/null || true
done < <(find "$TARGET_DIR" -type d -path "*/$old_pkg_path" | sort)

app_id_segment="$(printf '%s' "$APP_NAME" | tr -cd '[:alnum:]')"
if [[ -z "$app_id_segment" ]]; then
  app_id_segment="App"
fi

while IFS= read -r -d '' file; do
  APP_NAME="$APP_NAME" BASE_PACKAGE="$BASE_PACKAGE" APP_ID_SEGMENT="$app_id_segment" perl -pi -e '
    my $pkg = $ENV{"BASE_PACKAGE"};
    my $app = $ENV{"APP_NAME"};
    my $appId = $ENV{"APP_ID_SEGMENT"};
    s/com\.example\.sample/$pkg/g;
    s/rootProject\.name\s*=\s*"Sample"/rootProject.name = "$app"/g;
    s/PRODUCT_NAME=Sample/PRODUCT_NAME=$app/g;
    s/Sample\.app/$app.app/g;
    s/\.Sample\$\(TEAM_ID\)/.$appId\$(TEAM_ID)/g;
    s{<string name="app_name">Sample</string>}{<string name="app_name">$app</string>}g;
  ' "$file"
done < <(
  find "$TARGET_DIR" \
    \( -path "$TARGET_DIR/.git" -o -path "$TARGET_DIR/.gradle" -o -path "$TARGET_DIR/.idea" -o -path "$TARGET_DIR/build" \) -prune -o \
    -type f \
    \( -name "*.kts" -o -name "*.kt" -o -name "*.swift" -o -name "*.plist" -o -name "*.xml" -o -name "*.toml" -o -name "*.md" -o -name "*.xcconfig" -o -name "*.pbxproj" -o -name "*.xcworkspacedata" -o -name "*.properties" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" \) \
    -print0
)

remaining_pkg_dirs="$(find "$TARGET_DIR" -type d -path "*/$old_pkg_path" | wc -l | tr -d ' ')"
if [[ "$remaining_pkg_dirs" != "0" ]]; then
  echo "[ERROR] package path migration incomplete: found $remaining_pkg_dirs remaining '$old_pkg_path' directories"
  exit 1
fi

remaining_pkg_refs="$(rg -n --hidden --glob '!.git/**' --glob '!.gradle/**' --glob '!build/**' 'com\\.example\\.sample' "$TARGET_DIR" || true)"
if [[ -n "$remaining_pkg_refs" ]]; then
  echo "[WARN] found remaining 'com.example.sample' references:"
  echo "$remaining_pkg_refs"
fi

echo "[OK] project scaffolded from template: $TEMPLATE_SOURCE"
