#!/usr/bin/env bash
# trace.sh — requirements.md 的 N.M 與 Gherkin scenario 的雙向追溯
#
# 需求 → 設計 / 需求 → task 的涵蓋度不歸本腳本管，由 kiro-validate-impl
# 認定（見 ADR-0005）。本腳本只做 cc-sdd 結構上沒有的 scenario 那一軸。
#
# 用法:
#   trace.sh check  [--include-design] [--feature <name>]
#   trace.sh bind   [--feature <name>]
#   trace.sh verify [--feature <name>]
#
# Exit code: 0=通過  1=有缺口  2=執行錯誤
#
# 設計原則：判定邏輯全部在腳本裡，SKILL.md 只負責轉述輸出。
# 不要把判定交給模型。

set -euo pipefail

SPECS_DIR="${SPECS_DIR:-.kiro/specs}"
FEATURE=""
INCLUDE_DESIGN=0

die() { printf '{"error":"%s"}\n' "$1" >&2; exit 2; }

MODE="${1:-}"; shift || true
case "$MODE" in
  check|bind|verify) ;;
  *) die "usage: trace.sh {check|bind|verify} [options]" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --include-design) INCLUDE_DESIGN=1; shift ;;
    --feature) FEATURE="${2:-}"; shift 2 ;;
    *) die "unknown option: $1" ;;
  esac
done

# feature 選擇：不猜。多於一個候選就要求明確指定。
# （曾用 `ls -t` 取最近修改者——編輯器碰一下別的 spec 目錄就會靜默挑錯。）
if [ -z "$FEATURE" ]; then
  [ -d "$SPECS_DIR" ] || die "specs dir not found: $SPECS_DIR"
  candidates=()
  for d in "$SPECS_DIR"/*/; do
    [ -d "$d" ] || continue
    candidates+=("$(basename "$d")")
  done
  case ${#candidates[@]} in
    0) die "no feature found under $SPECS_DIR" ;;
    1) FEATURE="${candidates[0]}" ;;
    *) die "found ${#candidates[@]} features; specify --feature <name>: ${candidates[*]}" ;;
  esac
fi

SPEC_PATH="$SPECS_DIR/$FEATURE"
[ -d "$SPEC_PATH" ] || die "feature not found: $SPEC_PATH"

# ---------------------------------------------------------------
# ID 慣例（已定案，見 .kiro/steering/gherkin-guidelines.md）
#
#   @REQ-N.M  —— 直接用 cc-sdd requirements.md 的驗收條件編號，不另設別名
#   @SCN-NNN  —— 流水號，不含語意，單調遞增，永不重用
#   @BC-nn    —— grill-notes.md 的邊界條件，每個 feature 從 01 重編
#
# 比對為集合運算，順序不參與。
#
# .feature 位置（已定案，見 ADR-0008）
#   契約 $SPEC_PATH/features/*.feature —— 落在所有 task boundary 之外
#   step definition 放專案測試目錄，不在本腳本的掃描範圍
#
# tag 必須與 Scenario 相鄰且寫在同一行（見 gherkin-guidelines.md）。
# 下方的 parse_scenarios 依賴這個約束。
# ---------------------------------------------------------------

REQ_ID_PATTERN='[0-9]+\.[0-9]+'
FEATURE_GLOB="$SPEC_PATH/features"
REQ_FILE="$SPEC_PATH/requirements.md"
GRILL_FILE="$SPEC_PATH/grill-notes.md"
DESIGN_FILE="$SPEC_PATH/design.md"

json_escape() {
  # 轉義 JSON 字串內容：反斜線、雙引號、控制字元
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g'
}

# 把陣列轉成 JSON 字串陣列
json_array() {
  local first=1 item out="["
  for item in "$@"; do
    [ $first -eq 1 ] || out+=","
    out+="\"$(json_escape "$item")\""
    first=0
  done
  printf '%s]' "$out"
}

# ---------------------------------------------------------------
# 抽取
# ---------------------------------------------------------------

extract_req_ids() {
  # cc-sdd 的驗收條件編號為 N.M，出現在標題或條列項的行首。
  # 限定行首是為了避開內文裡的版本號與小數。
  #
  # TODO: 對照一份真實產出的 requirements.md 驗證此 pattern。
  #       cc-sdd 未固定驗收條件的排版（標題 / 條列 / 表格皆可能）。
  #       抓到 0 筆時本腳本會 exit 2，不會靜默回報「覆蓋率 0/0 通過」。
  grep -oE "^[[:space:]]*(#+[[:space:]]*|[-*][[:space:]]+)?${REQ_ID_PATTERN}" \
    "$REQ_FILE" 2>/dev/null | grep -oE "$REQ_ID_PATTERN" | sort -u -V || true
}

extract_bc_ids() {
  # grill-notes.md 的邊界條件編號，格式 "- [BC-01] 描述"
  grep -oE '^[[:space:]]*-[[:space:]]*\[BC-[0-9]+\]' "$GRILL_FILE" 2>/dev/null \
    | grep -oE 'BC-[0-9]+' | sort -u -V || true
}

# 解析 scenario：每列一條，TSV = tags <TAB> title <TAB> file
# 依賴「tag 單行、緊鄰 Scenario」的約束。Feature 層的 tag 併入該檔所有 scenario。
parse_scenarios() {
  awk '
    FNR==1 { ftags=""; pending="" }
    /^[[:space:]]*@/                      { pending=$0; next }
    /^[[:space:]]*Feature:/               { ftags=pending; pending=""; next }
    /^[[:space:]]*Scenario( Outline)?:/ {
        title=$0
        sub(/^[[:space:]]*Scenario( Outline)?:[[:space:]]*/, "", title)
        gsub(/\t/, " ", title)
        tags=ftags " " pending
        gsub(/\t/, " ", tags)
        print tags "\t" title "\t" FILENAME
        pending=""
        next
    }
  ' "$FEATURE_GLOB"/*.feature
}

# ---------------------------------------------------------------
# check
# ---------------------------------------------------------------

run_check() {
  [ -f "$REQ_FILE" ]   || die "requirements.md not found: $REQ_FILE"
  [ -f "$GRILL_FILE" ] || die "grill-notes.md not found: $GRILL_FILE — 先跑 /grill-me 與 /grill-capture"
  [ -d "$FEATURE_GLOB" ] || die "features dir not found: $FEATURE_GLOB — 先跑 /scenario-write"
  compgen -G "$FEATURE_GLOB/*.feature" >/dev/null \
    || die "no .feature under $FEATURE_GLOB — 先跑 /scenario-write"
  if [ "$INCLUDE_DESIGN" -eq 1 ] && [ ! -f "$DESIGN_FILE" ]; then
    die "design.md not found: $DESIGN_FILE"
  fi

  local req_ids bc_ids
  req_ids="$(extract_req_ids)"
  bc_ids="$(extract_bc_ids)"

  # 自檢：抓不到任何 REQ ID 幾乎一定是 pattern 不符實際排版。
  # 這種情況下所有需求都會被判成「無對應 scenario」，是假陽性而非缺口。
  [ -n "$req_ids" ] || die "在 $REQ_FILE 找不到任何 N.M 格式的驗收條件編號 —— REQ_ID_PATTERN 可能不符實際排版，請確認後調整"

  local scenarios
  scenarios="$(parse_scenarios)"
  [ -n "$scenarios" ] || die "解析不到任何 Scenario —— 確認 tag 與 Scenario 相鄰且寫在同一行"

  local req_refs bc_refs scn_ids
  req_refs="$(printf '%s\n' "$scenarios" | grep -oE '@REQ-[0-9]+\.[0-9]+' | sed 's/^@REQ-//' | sort -u -V || true)"
  bc_refs="$(printf '%s\n'  "$scenarios" | grep -oE '@BC-[0-9]+'          | tr -d '@'      | sort -u -V || true)"
  scn_ids="$(printf '%s\n'  "$scenarios" | grep -oE '@SCN-[0-9]+'         | tr -d '@'      | sort -u -V || true)"

  # --- 缺口 1：需求沒有 scenario
  local req_without_scn
  req_without_scn="$(comm -23 <(printf '%s\n' "$req_ids" | sort) <(printf '%s\n' "$req_refs" | sort) || true)"

  # --- 缺口 2：孤兒 scenario（沒帶 @REQ）與 缺口 3：沒帶 @SCN
  local orphan_titles=() untagged_titles=() dup_scn=()
  local tags title file
  while IFS=$'\t' read -r tags title file; do
    [ -n "$title" ] || continue
    case "$tags" in
      *@REQ-*) ;;
      *) orphan_titles+=("${title} [${file##*/}]") ;;
    esac
    case "$tags" in
      *@SCN-*) ;;
      *) untagged_titles+=("${title} [${file##*/}]") ;;
    esac
  done <<< "$scenarios"

  # --- 缺口 4：SCN 重複使用
  local d
  while IFS= read -r d; do
    [ -n "$d" ] && dup_scn+=("$d")
  done < <(printf '%s\n' "$scenarios" | grep -oE '@SCN-[0-9]+' | tr -d '@' | sort | uniq -d || true)

  # --- 缺口 5：BC 沒有 scenario 覆蓋
  local bc_without_scn=""
  if [ -n "$bc_ids" ]; then
    bc_without_scn="$(comm -23 <(printf '%s\n' "$bc_ids" | sort) <(printf '%s\n' "$bc_refs" | sort) || true)"
  fi

  # --- 缺口 6：--include-design，被引用的 REQ 是否出現在 design.md
  # design.md 不認識 SCN，所以走 REQ 傳遞：cc-sdd 的 design 有
  # Requirements Traceability 表（design-principles.md），REQ 應出現在那裡。
  local req_not_in_design=()
  if [ "$INCLUDE_DESIGN" -eq 1 ]; then
    local r
    while IFS= read -r r; do
      [ -n "$r" ] || continue
      grep -qE "(^|[^0-9.])${r//./\\.}([^0-9]|\$)" "$DESIGN_FILE" || req_not_in_design+=("$r")
    done <<< "$req_refs"
  fi

  # --- 統計
  local n_req n_scn n_bc n_req_covered n_bc_covered
  n_req=$(printf '%s\n' "$req_ids" | grep -c . || true)
  n_scn=$(printf '%s\n' "$scn_ids" | grep -c . || true)
  n_bc=$(printf '%s\n'  "$bc_ids"  | grep -c . || true)
  n_req_covered=$(( n_req - $(printf '%s\n' "$req_without_scn" | grep -c . || true) ))
  n_bc_covered=$((  n_bc  - $(printf '%s\n' "$bc_without_scn"  | grep -c . || true) ))

  # --- 判定
  local verdict="PASS" rc=0
  if [ -n "$req_without_scn" ] || [ -n "$bc_without_scn" ] \
     || [ ${#orphan_titles[@]} -gt 0 ] || [ ${#untagged_titles[@]} -gt 0 ] \
     || [ ${#dup_scn[@]} -gt 0 ] || [ ${#req_not_in_design[@]} -gt 0 ]; then
    verdict="FAIL"; rc=1
  fi

  # --- 輸出
  local a_req_without a_bc_without
  mapfile -t _tmp < <(printf '%s\n' "$req_without_scn" | grep . || true)
  a_req_without="$(json_array "${_tmp[@]+"${_tmp[@]}"}")"
  mapfile -t _tmp < <(printf '%s\n' "$bc_without_scn" | grep . || true)
  a_bc_without="$(json_array "${_tmp[@]+"${_tmp[@]}"}")"

  cat <<JSON
{
  "feature": "$(json_escape "$FEATURE")",
  "spec_path": "$(json_escape "$SPEC_PATH")",
  "include_design": $([ "$INCLUDE_DESIGN" -eq 1 ] && echo true || echo false),
  "counts": { "req": $n_req, "scenario": $n_scn, "bc": $n_bc },
  "coverage": { "req": "$n_req_covered/$n_req", "bc": "$n_bc_covered/$n_bc" },
  "gaps": {
    "req_without_scenario": $a_req_without,
    "scenario_without_req": $(json_array "${orphan_titles[@]+"${orphan_titles[@]}"}"),
    "scenario_without_scn_tag": $(json_array "${untagged_titles[@]+"${untagged_titles[@]}"}"),
    "duplicate_scn": $(json_array "${dup_scn[@]+"${dup_scn[@]}"}"),
    "bc_without_scenario": $a_bc_without,
    "req_not_in_design": $(json_array "${req_not_in_design[@]+"${req_not_in_design[@]}"}")
  },
  "verdict": "$verdict"
}
JSON
  return $rc
}

case "$MODE" in
  check)
    run_check
    ;;
  bind)
    # 映射是機械的：cc-sdd 每個 sub-task 都帶 _Requirements: X.X_
    # （tasks-generation.md 的 Checkbox Format），與 scenario 的 @REQ 取交集即可。
    echo "TODO: 讀 tasks.md 的 _Requirements:_，與 @REQ 取交集，寫入 _DoD: SCN-xxx 由紅轉綠_" >&2
    echo "TODO: 交集為空的 task 要特別標出" >&2
    echo "--- bind 尚未實作，回傳 2 以免被誤判為通過 ---" >&2
    exit 2
    ;;
  verify)
    echo "TODO: git diff 檢查 .feature 在實作階段是否被修改（依 @SCN 歸因）" >&2
    echo "TODO: 基準線來源未定，見 ADR-0008「未解決」" >&2
    echo "TODO: 缺 step definition 需跑測試框架 dry-run，與技術棧綁定" >&2
    echo "--- verify 尚未實作，回傳 2 以免被誤判為通過 ---" >&2
    exit 2
    ;;
esac
