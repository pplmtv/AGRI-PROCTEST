# src_snapshot.sh
#!/usr/bin/env bash
set -euo pipefail

# ----------------------------
# how to use:
#   current directory should be agri-poctest
#   cd fastapi
#   chmod +x ops/src_snapshot.sh
#   ops/src_snapshot.sh . "py,ts,tsx" 5
# ----------------------------

ROOT="${1:-.}"
EXTS_CSV="${2:-py,js,ts,tsx,go,rs,java,kt,rb,php,cs,cpp,h,hpp,c,md}"
MAX_DEPTH="${3:-5}"

# ------------------------------------------------------------
# Output settings (FIXED)
# ------------------------------------------------------------
OUT_DIR="ops/output/src_snapshot"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$OUT_DIR/src_snapshot_${TIMESTAMP}.txt"

mkdir -p "$OUT_DIR"

# 以降の出力をすべてファイルにリダイレクト
exec > "$OUT_FILE"

# ------------------------------------------------------------

# Ignore common noise dirs
IGNORE_DIRS=(
  ".git"
  "node_modules"
  ".venv"
  "venv"
  "dist"
  "build"
  "__pycache__"
  ".pytest_cache"
  ".mypy_cache"
  ".next"
  ".turbo"
  "coverage"
  ".idea"
  ".vscode"
)

# Convert CSV to array
IFS=',' read -r -a EXTS <<< "$EXTS_CSV"

# Build find prune expression
PRUNE_EXPR=()
for d in "${IGNORE_DIRS[@]}"; do
  PRUNE_EXPR+=( -name "$d" -o )
done
if ((${#PRUNE_EXPR[@]} > 0)); then
  unset 'PRUNE_EXPR[${#PRUNE_EXPR[@]}-1]'
fi

# Section header helper
section () {
  echo
  echo "===== $1 "
}

{
  echo "=================================================="
  echo " SOURCE SNAPSHOT"
  echo " Generated at: $(date)"
  echo "=================================================="
}

abs_root() {
  (cd "$ROOT" && pwd)
}

ROOT_ABS="$(abs_root)"

section "ROOT: $ROOT_ABS"
section "OUTPUT: $OUT_FILE"

# ------------------------------------------------------------
# 1) Directory structure
# ------------------------------------------------------------
section "Directory structure (max depth: $MAX_DEPTH)"

find "$ROOT_ABS" \
  \( -type d \( "${PRUNE_EXPR[@]}" \) -prune \) -o \
  \( -type d -o -type f \) -print \
| awk -v root="$ROOT_ABS" -v maxd="$MAX_DEPTH" '
  BEGIN { rlen = length(root) }
  {
    rel = substr($0, rlen + 2)
    if (rel == "") {
      print "."
      next
    }

    depth = gsub(/\//, "/", rel) + 1
    if (depth > maxd) next

    indent=""
    for (i = 1; i < depth; i++) indent = indent "  "
    print indent rel
  }
'

# ------------------------------------------------------------
# 2) Source files grouped by directory
# ------------------------------------------------------------

# Build extension match for find
NAME_EXPR=()
for ext in "${EXTS[@]}"; do
  ext="${ext#.}"
  ext="${ext// /}"
  [[ -z "$ext" ]] && continue
  NAME_EXPR+=( -name "*.${ext}" -o )
done
if ((${#NAME_EXPR[@]} > 0)); then
  unset 'NAME_EXPR[${#NAME_EXPR[@]}-1]'
fi

section "Source files grouped by directory (extensions: $EXTS_CSV)"

current_dir=""
found=0

while IFS= read -r f; do
  found=1
  dir="$(dirname "$f")"
  rel_dir="${dir#"$ROOT_ABS"/}"
  rel_file="${f#"$ROOT_ABS"/}"

  if [ "$dir" != "$current_dir" ]; then
    current_dir="$dir"
    echo
    echo "### ${rel_dir:-.}"
  fi

  echo
  echo "----- ${rel_file} -----"
  cat "$f"
done < <(
  find "$ROOT_ABS" \
    \( -type d \( "${PRUNE_EXPR[@]}" \) -prune \) -o \
    -type f \( "${NAME_EXPR[@]}" \) -print \
  | sort
)

if [ "$found" -eq 0 ]; then
  echo "No matching files found."
fi
