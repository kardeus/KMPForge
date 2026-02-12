#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

username_default=$(git config --get user.name 2>/dev/null || true)
if [[ -z "$username_default" ]]; then
  username_default=$(whoami)
fi

USERNAME="${KOTLIN_HEADER_USERNAME:-$username_default}"
EMAIL="${KOTLIN_HEADER_EMAIL:-}"
if [[ -z "$EMAIL" ]]; then
  EMAIL="$(git config --get user.email 2>/dev/null || true)"
fi
if [[ -z "$EMAIL" ]]; then
  EMAIL="unknown@example.com"
fi
DESCRIPTION_FALLBACK="${KOTLIN_HEADER_DESCRIPTION_FALLBACK:-관련 구현을 포함한다.}"
COPYRIGHT_OWNER="${FILE_AUTHORIZATION_OWNER:-KMPForge}"

declare -a files=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --email)
      EMAIL="$2"
      shift 2
      ;;
    --description)
      DESCRIPTION_FALLBACK="$2"
      shift 2
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        files+=("$1")
        shift
      done
      ;;
    *)
      files+=("$1")
      shift
      ;;
  esac
done

if [[ ${#files[@]} -eq 0 ]]; then
  while IFS= read -r f; do
    files+=("$f")
  done < <(rg --files -g '*.kt')
fi

is_tracked() {
  git ls-files --error-unmatch -- "$1" >/dev/null 2>&1
}

created_date_for() {
  local f="$1"
  local format="$2"
  local created=""

  if is_tracked "$f"; then
    created=$(git log --follow --diff-filter=A --format=%ad --date=format:"$format" -- "$f" | tail -n 1 || true)
    if [[ -z "$created" ]]; then
      created=$(git log --format=%ad --date=format:"$format" -- "$f" | tail -n 1 || true)
    fi
  fi

  if [[ -z "$created" ]]; then
    created=$(date +"$format")
  fi

  printf '%s' "$created"
}

derive_declaration() {
  local f="$1"
  perl -ne '
    BEGIN { $in = 0; }
    if ($. > 400) { exit; }
    if ($in) {
      if (/\*\//) { $in = 0; }
      next;
    }
    if (/^\s*\/\*/) { $in = 1; next; }
    next if /^\s*\/\//;
    next if /^\s*$/;
    next if /^\s*(package|import)\b/;
    if (/^\s*(?:(?:public|private|internal|protected|open|final|abstract|sealed|data|enum|annotation|value|expect|actual|suspend|inline|operator|tailrec|infix|external|const|lateinit|override)\s+)*(class|object|interface|fun|typealias)\s+([A-Za-z_]\w*)/) {
      print "$1:$2\n";
      exit;
    }
  ' "$f"
}

derive_description_for() {
  local file_path="$1"
  local analysis_file="$2"
  local base decl kind name

  base=$(basename "$file_path" .kt)
  decl=$(derive_declaration "$analysis_file" || true)
  kind="${decl%%:*}"
  name="${decl#*:}"

  if [[ -z "$decl" || "$kind" == "$name" ]]; then
    kind=""
    name="$base"
  fi

  name="$base"

  if [[ "$name" == "App" ]]; then
    printf '%s' "애플리케이션 루트 UI와 내비게이션 구성을 제공한다."
    return
  fi
  if [[ "$name" == "Constants" ]]; then
    printf '%s' "공용 상수를 정의한다."
    return
  fi

  if [[ "$name" =~ Screen$ ]]; then
    printf '%s' "${name} 화면 Composable을 제공한다."
    return
  fi
  if [[ "$name" =~ ViewModel$ ]]; then
    printf '%s' "${name} 상태와 이벤트 로직을 관리한다."
    return
  fi
  if [[ "$name" =~ Repository$ ]]; then
    printf '%s' "${name} 데이터 접근 로직을 제공한다."
    return
  fi
  if [[ "$name" =~ UseCase$ ]]; then
    printf '%s' "${name} 유스케이스를 수행한다."
    return
  fi
  if [[ "$name" =~ Module$ ]]; then
    printf '%s' "${name} 의존성 주입 모듈을 정의한다."
    return
  fi
  if [[ "$name" =~ Test$ ]]; then
    printf '%s' "${name} 동작 검증 테스트를 포함한다."
    return
  fi
  if [[ "$name" =~ Activity$ ]]; then
    printf '%s' "${name} Android Activity 진입점을 제공한다."
    return
  fi
  if [[ "$name" =~ Application$ ]]; then
    printf '%s' "${name} 애플리케이션 시작 구성을 정의한다."
    return
  fi
  if [[ "$name" =~ Factory$ ]]; then
    printf '%s' "${name} 객체 생성 로직을 제공한다."
    return
  fi
  if [[ "$name" =~ Service$ ]]; then
    printf '%s' "${name} 서비스 로직을 제공한다."
    return
  fi

  case "$kind" in
    class) printf '%s' "${name} 클래스를 정의한다." ;;
    object) printf '%s' "${name} 객체를 정의한다." ;;
    interface) printf '%s' "${name} 인터페이스를 정의한다." ;;
    fun) printf '%s' "${name} 함수를 정의한다." ;;
    typealias) printf '%s' "${name} 타입 별칭을 정의한다." ;;
    *) printf '%s' "${base} ${DESCRIPTION_FALLBACK}" ;;
  esac
}

strip_existing_headers() {
  local input_file="$1"
  local output_file="$2"

  perl -0777 -pe '
    s@\A/\*\*\n \* Created by [^\n]* on [0-9]{4}\. [0-9]{2}\. [0-9]{2}\.\n \* Email: [^\n]*\n \* Description: [^\n]*\n \*/\n+@@s;
    s@\A// File Authorization: Created [^\n]*\n+@@s;
  ' "$input_file" > "$output_file"
}

changed=0
unchanged=0

for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  [[ "$f" == *.kt ]] || continue

  cleaned_tmp=$(mktemp)
  final_tmp=$(mktemp)

  strip_existing_headers "$f" "$cleaned_tmp"

  created_dotted=$(created_date_for "$f" '%Y. %m. %d.')
  created_iso=$(created_date_for "$f" '%Y-%m-%d')
  year=${created_iso%%-*}
  description=$(derive_description_for "$f" "$cleaned_tmp")

  {
    cat <<EOT
/**
 * Created by ${USERNAME} on ${created_dotted}
 * Email: ${EMAIL}
 * Description: ${description}
 */

// File Authorization: Created ${created_iso} | Copyright (c) ${year} ${COPYRIGHT_OWNER}. All rights reserved.

EOT
    cat "$cleaned_tmp"
  } > "$final_tmp"

  if ! cmp -s "$f" "$final_tmp"; then
    mv "$final_tmp" "$f"
    changed=$((changed + 1))
  else
    rm -f "$final_tmp"
    unchanged=$((unchanged + 1))
  fi

  rm -f "$cleaned_tmp"
done

echo "changed=$changed unchanged=$unchanged"
