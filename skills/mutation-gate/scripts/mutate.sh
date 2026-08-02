#!/usr/bin/env bash
# mutate.sh — 對本次 diff 涉及的檔案執行 mutation testing
#
# 用法:
#   mutate.sh [--base <git-ref>] [--threshold <n>]
#
# Exit code: 0=達標  1=未達標  2=執行錯誤
#
# 設計原則：判定邏輯全部在腳本裡，SKILL.md 只負責轉述輸出。
# 不要把判定交給模型。
#
# 語言相依的部分只有 MUTATION_RUN_CMD / MUTATION_RESULT_CMD，
# 定義在 .kiro/steering/toolchain.md。分數計算與門檻比對是語言無關的。

set -euo pipefail

BASE="${MUTATE_BASE:-}"
THRESHOLD=""
KIRO_DIR="${KIRO_DIR:-.kiro}"
TOOLCHAIN="$KIRO_DIR/steering/toolchain.md"
GATES="$KIRO_DIR/steering/quality-gates.md"

die() { printf '{"error":"%s"}\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:-}"; shift 2 ;;
    --threshold) THRESHOLD="${2:-}"; shift 2 ;;
    *) die "unknown option: $1" ;;
  esac
done

# ---------------------------------------------------------------
# 設定
# ---------------------------------------------------------------

[ -f "$TOOLCHAIN" ] || die "toolchain.md not found: $TOOLCHAIN — 見 steering-custom/toolchain.md 範本"

# 從 toolchain.md 的 ini 區塊取值（KEY=VALUE，取第一個非註解命中）
toolchain_get() {
  grep -oE "^${1}=.*$" "$TOOLCHAIN" 2>/dev/null | head -1 | cut -d= -f2- || true
}

MUTATION_RUN_CMD="$(toolchain_get MUTATION_RUN_CMD)"
MUTATION_RESULT_CMD="$(toolchain_get MUTATION_RESULT_CMD)"

[ -n "$MUTATION_RUN_CMD" ] || die "toolchain.md 未定義 MUTATION_RUN_CMD —— 若本專案的語言沒有可用的 mutation 工具（例如 Go），請在 quality-gates.md 明確標為不適用，不要留一道跑不動的閘門"
[ -n "$MUTATION_RESULT_CMD" ] || die "toolchain.md 未定義 MUTATION_RESULT_CMD"

# 門檻：優先用 --threshold，否則從 quality-gates.md 的表格抓第一個百分比
if [ -z "$THRESHOLD" ]; then
  [ -f "$GATES" ] || die "quality-gates.md not found: $GATES"
  THRESHOLD="$(grep -oE '\| *[0-9]+% *\|' "$GATES" 2>/dev/null | grep -oE '[0-9]+' | head -1 || true)"
fi
[ -n "$THRESHOLD" ] || die "在 $GATES 找不到 mutation 門檻，且未指定 --threshold"

# ---------------------------------------------------------------
# diff scope
# ---------------------------------------------------------------

git rev-parse --git-dir >/dev/null 2>&1 || die "不在 git repo 內，無法決定 diff scope"

if [ -z "$BASE" ]; then
  # 預設與上游分支比；沒有上游就跟 HEAD~1 比
  BASE="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || echo '')"
  [ -n "$BASE" ] || BASE="HEAD~1"
fi
git rev-parse --verify --quiet "$BASE" >/dev/null || die "base ref 不存在: $BASE"

mapfile -t CHANGED < <(git diff --name-only --diff-filter=ACMR "$BASE"...HEAD -- '*.py' 2>/dev/null || true)

if [ ${#CHANGED[@]} -eq 0 ]; then
  # 沒有變更檔就沒有 diff scope。這不是通過，是無事可做——
  # 但也不該擋住流程，所以回 0 並明確說明範圍為空。
  cat <<JSON
{
  "base": "$BASE",
  "changed_files": [],
  "scope": "empty",
  "note": "本次 diff 未涉及可 mutate 的檔案，未執行 mutation testing",
  "verdict": "SKIPPED"
}
JSON
  exit 0
fi

# 路徑 → 模組前綴：exporter/paginator.py → exporter.paginator
MODULES=()
for f in "${CHANGED[@]}"; do
  case "$f" in
    */__init__.py|__init__.py) continue ;;
    *test*) continue ;;
  esac
  m="${f%.py}"; m="${m//\//.}"
  MODULES+=("$m")
done

[ ${#MODULES[@]} -gt 0 ] || die "diff 中有 .py 變更，但全部是測試或 __init__，無可 mutate 的目標"

# ---------------------------------------------------------------
# 執行
# ---------------------------------------------------------------

PATTERNS=()
for m in "${MODULES[@]}"; do PATTERNS+=("$m.*"); done

run_cmd="${MUTATION_RUN_CMD//\{MODULES\}/${PATTERNS[*]}}"
eval "$run_cmd" >/dev/null 2>&1 || true   # 有存活的 mutant 時工具本身可能回非 0，判定看分數

results="$(eval "$MUTATION_RESULT_CMD" 2>/dev/null || true)"
[ -n "$results" ] || die "mutation 工具沒有輸出結果 —— 確認 MUTATION_RESULT_CMD 與工具設定"

# ---------------------------------------------------------------
# 只計 diff scope 的分數
#
# 工具的報表通常涵蓋整個資料庫的累積結果（mutmut 確實如此），
# 所以這裡自己依模組前綴篩，不用工具給的總分。
# 全域分數容易靠灌水達標，diff scope 藏不住。
# ---------------------------------------------------------------

killed=0; survived=0; other=0
SURVIVORS=()
while IFS= read -r line; do
  # 工具輸出帶縮排（mutmut 是四個空白），前後空白一律剝掉。
  # `${var## }` 只會去掉一個空白，不夠用。
  line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  [ -n "$line" ] || continue
  case "$line" in *:*) ;; *) continue ;; esac
  name="${line%%:*}"
  status="${line##*: }"
  in_scope=0
  for m in "${MODULES[@]}"; do
    case "$name" in "$m".*) in_scope=1; break ;; esac
  done
  [ "$in_scope" -eq 1 ] || continue
  case "$status" in
    killed)   killed=$((killed+1)) ;;
    survived) survived=$((survived+1)); SURVIVORS+=("$name") ;;
    *)        other=$((other+1)) ;;
  esac
done <<< "$results"

total=$((killed + survived))
if [ "$total" -eq 0 ]; then
  die "diff scope 內沒有任何 mutant —— 可能是模組前綴推導錯誤（改到的檔案不是被 mutate 的來源目錄？），不當作通過"
fi

score=$(( killed * 100 / total ))
verdict="PASS"; rc=0
if [ "$score" -lt "$THRESHOLD" ]; then verdict="FAIL"; rc=1; fi

json_escape() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
arr() {
  local out="[" first=1 i
  for i in "$@"; do [ $first -eq 1 ] || out+=","; out+="\"$(json_escape "$i")\""; first=0; done
  printf '%s]' "$out"
}

cat <<JSON
{
  "base": "$(json_escape "$BASE")",
  "changed_files": $(arr "${CHANGED[@]}"),
  "modules": $(arr "${MODULES[@]}"),
  "scope": "diff",
  "counts": { "killed": $killed, "survived": $survived, "other": $other, "total": $total },
  "score": $score,
  "threshold": $THRESHOLD,
  "survivors": $(arr ${SURVIVORS[@]+"${SURVIVORS[@]}"}),
  "verdict": "$verdict"
}
JSON
exit $rc
