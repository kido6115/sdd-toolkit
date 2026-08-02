#!/usr/bin/env bash
# trace.sh — requirements.md 的 N.M 與 Gherkin scenario 的雙向追溯
#
# 需求 → 設計 / 需求 → task 的涵蓋度不歸本腳本管，由 kiro-validate-impl
# 認定（見 ADR-0005）。本腳本只做 cc-sdd 結構上沒有的 scenario 那一軸。
#
# 用法:
#   trace.sh check  [--include-design] [--feature <name>]
#   trace.sh bind   [--dry-run] [--feature <name>]
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
DRY_RUN=0

die() { printf '{"error":"%s"}\n' "$1" >&2; exit 2; }

MODE="${1:-}"; shift || true
case "$MODE" in
  check|bind|verify) ;;
  *) die "usage: trace.sh {check|bind|verify} [options]" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --include-design) INCLUDE_DESIGN=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
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
TASKS_FILE="$SPEC_PATH/tasks.md"
LOCK_FILE="$SPEC_PATH/scenarios.lock"
TOOLCHAIN_FILE="${KIRO_DIR:-.kiro}/steering/toolchain.md"

hash_body() { printf '%s' "$1" | sha256sum | cut -c1-12; }

# 從一串 tag 取出指定前綴的 ID，逗號分隔；無則回 "-"
tags_of() {
  local out
  out="$(printf '%s\n' "$1" | grep -oE "@$2-[0-9.]+" | sed "s/^@//" | sort -u -V | paste -sd',' - || true)"
  printf '%s' "${out:--}"
}

# 產生 lock 內容（stdout）。trace-bind 寫入，trace-verify 比對。
build_lock() {
  printf '# scenarios.lock —— 由 trace-bind 產生，勿手動修改\n'
  printf '# SCN\thash\tREQ\tBC\tfile\ttitle\n'
  local tags title file body scn
  while IFS=$'\t' read -r tags title file body; do
    [ -n "$title" ] || continue
    scn="$(printf '%s\n' "$tags" | grep -oE '@SCN-[0-9]+' | head -1 | tr -d '@' || true)"
    [ -n "$scn" ] || continue
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$scn" "$(hash_body "$body")" "$(tags_of "$tags" REQ)" "$(tags_of "$tags" BC)" \
      "${file##*/}" "$title"
  done < <(parse_scenarios_full) | sort -V
}

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

# 解析 scenario 並附正規化後的內容，供 lock 比對。
# 每列 TSV = tags <TAB> title <TAB> file <TAB> body
# body 是 Scenario 標題與其後所有步驟（含 Examples），逐行去除前後空白、
# 丟棄空行後以 \x1f 接起——這樣重排版不會誤報，內容變動才會。
parse_scenarios_full() {
  awk '
    function emit() {
      if (cur != "") print curtags "\t" curtitle "\t" curfile "\t" body
      cur=""; body=""
    }
    FNR==1 { emit(); ftags=""; pending="" }
    /^[[:space:]]*@/                      { emit(); pending=$0; next }
    /^[[:space:]]*Feature:/               { emit(); ftags=pending; pending=""; next }
    /^[[:space:]]*Scenario( Outline)?:/ {
        emit()
        line=$0; sub(/^[[:space:]]*/,"",line); sub(/[[:space:]]*$/,"",line)
        curtitle=line; sub(/^Scenario( Outline)?:[[:space:]]*/, "", curtitle)
        gsub(/\t/, " ", curtitle)
        curtags=ftags " " pending; gsub(/\t/, " ", curtags)
        curfile=FILENAME
        cur="y"; body=line
        pending=""
        next
    }
    {
        if (cur != "") {
            l=$0; sub(/^[[:space:]]*/,"",l); sub(/[[:space:]]*$/,"",l)
            if (l != "") { gsub(/\t/," ",l); body = body "\037" l }
        }
    }
    END { emit() }
  ' "$FEATURE_GLOB"/*.feature
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

# ---------------------------------------------------------------
# bind
#
# 映射是機械的，不是語意判斷：cc-sdd 每個 sub-task 都帶
# `_Requirements: X.X_`（tasks-generation.md 的 Checkbox Format），
# 與 scenario 的 @REQ 取交集即可。
#
#   task 4.1  _Requirements: 3.1, 3.2_
#             ∩  SCN-042 @REQ-3.1
#             →  _Scenarios: SCN-042_
#
# 寫入兩行，各有分工：
#   - 驗收條件：…       detail bullet，cc-sdd 本來就要求每個子任務有一條
#                        「observable completion condition」（tasks-generation.md:127）
#   - _Scenarios: …_    標註，與 _Requirements: / _Boundary: / _Depends: 同一家族
#
# 冪等：兩行都會被重算後取代，不會累積。舊的 _DoD:_ 一併清除。
# ---------------------------------------------------------------

# 每列 = "task_id <TAB> requirements(逗號分隔，可能為空)"
parse_tasks() {
  awk '
    function flush() { if (tid != "") print tid "\t" reqs }
    # 子任務： - [ ] 4.1 描述     （X.Y 編號才是執行單位）
    /^[[:space:]]*-[[:space:]]*\[[ xX]\]\*?[[:space:]]+[0-9]+\.[0-9]+/ {
        flush()
        match($0, /[0-9]+\.[0-9]+/); tid = substr($0, RSTART, RLENGTH); reqs = ""
        next
    }
    # 主任務標頭： - [ ] 4. 描述  （分組用，不是執行單位）
    /^[[:space:]]*-[[:space:]]*\[[ xX]\]\*?[[:space:]]+[0-9]+\./ {
        flush(); tid = ""; reqs = ""; next
    }
    /_Requirements:/ {
        if (tid != "") {
            l = $0
            sub(/.*_Requirements:[[:space:]]*/, "", l)
            sub(/_.*$/, "", l)
            gsub(/[[:space:]]/, "", l)
            reqs = l
        }
    }
    END { flush() }
  ' "$TASKS_FILE"
}

run_bind() {
  [ -f "$TASKS_FILE" ] || die "tasks.md not found: $TASKS_FILE — 先跑 /kiro-spec-tasks"
  [ -d "$FEATURE_GLOB" ] || die "features dir not found: $FEATURE_GLOB — 先跑 /scenario-write"
  compgen -G "$FEATURE_GLOB/*.feature" >/dev/null \
    || die "no .feature under $FEATURE_GLOB — 先跑 /scenario-write"

  local scenarios
  scenarios="$(parse_scenarios)"
  [ -n "$scenarios" ] || die "解析不到任何 Scenario —— 確認 tag 與 Scenario 相鄰且寫在同一行"

  # scenario → 它涵蓋的需求。每列 = "SCN-nnn <TAB> req,req"
  local scn_map
  scn_map="$(printf '%s\n' "$scenarios" | awk -F'\t' '
    {
      scn = ""; reqs = ""
      n = split($1, t, /[[:space:]]+/)
      for (i = 1; i <= n; i++) {
        if (t[i] ~ /^@SCN-[0-9]+$/) { scn = substr(t[i], 2) }
        else if (t[i] ~ /^@REQ-[0-9]+\.[0-9]+$/) {
          reqs = (reqs == "" ? "" : reqs ",") substr(t[i], 6)
        }
      }
      if (scn != "" && reqs != "") print scn "\t" reqs
    }' | sort -u -V)"

  local tasks
  tasks="$(parse_tasks)"
  [ -n "$tasks" ] || die "在 $TASKS_FILE 找不到任何 X.Y 子任務 —— 確認 tasks.md 的 checkbox 格式"

  local bindings=() no_reqs=() no_scn=() plan_file
  plan_file="$(mktemp)"
  trap 'rm -f "$plan_file"' RETURN

  local tid treqs
  while IFS=$'\t' read -r tid treqs; do
    [ -n "$tid" ] || continue
    if [ -z "$treqs" ]; then
      no_reqs+=("$tid")
      continue
    fi
    # 取交集：task 的需求 ∩ 各 scenario 的 @REQ
    local matched=()
    local scn sreqs
    while IFS=$'\t' read -r scn sreqs; do
      [ -n "$scn" ] || continue
      local r
      local IFS_SAVE="$IFS"; IFS=','
      for r in $treqs; do
        case ",$sreqs," in
          *",$r,"*) matched+=("$scn"); break ;;
        esac
      done
      IFS="$IFS_SAVE"
    done <<< "$scn_map"

    if [ ${#matched[@]} -eq 0 ]; then
      no_scn+=("$tid ($treqs)")
      continue
    fi
    local joined
    # paste -d 接受的是「循環使用的單字元清單」，不是分隔字串，
    # 所以 -d', ' 會交替用逗號與空白。先用逗號接，再補空白。
    joined="$(printf '%s\n' "${matched[@]}" | sort -u -V | paste -sd',' - | sed 's/,/, /g')"
    printf '%s\t%s\n' "$tid" "$joined" >> "$plan_file"
    bindings+=("{\"task\":\"$(json_escape "$tid")\",\"requirements\":\"$(json_escape "$treqs")\",\"scenarios\":\"$(json_escape "$joined")\"}")
  done <<< "$tasks"

  # --- 寫入
  if [ "$DRY_RUN" -eq 0 ] && [ -s "$plan_file" ]; then
    local tmp; tmp="$(mktemp)"
    awk -v plan="$plan_file" '
      BEGIN {
        while ((getline l < plan) > 0) { split(l, a, "\t"); dod[a[1]] = a[2] }
      }
      /^[[:space:]]*-[[:space:]]*\[[ xX]\]\*?[[:space:]]+[0-9]+\.[0-9]+/ {
          match($0, /[0-9]+\.[0-9]+/); tid = substr($0, RSTART, RLENGTH)
          print; next
      }
      /^[[:space:]]*-[[:space:]]*\[[ xX]\]\*?[[:space:]]+[0-9]+\./ { tid = ""; print; next }
      # 本 skill 寫過的兩行一律丟棄，稍後重算後重寫（冪等）。
      # _DoD: 是舊欄位名，一併清掉以便從舊版遷移。
      /^[[:space:]]*-[[:space:]]*_DoD:/            { next }
      /^[[:space:]]*-[[:space:]]*_Scenarios:/      { next }
      /^[[:space:]]*-[[:space:]]*驗收條件：SCN-/   { next }
      /_Requirements:/ {
          indent = $0; sub(/[^[:space:]].*$/, "", indent)
          # detail bullet 在 annotation 之前，照 cc-sdd 的排列
          if (tid != "" && tid in dod)
              printf "%s- 驗收條件：%s 由紅轉綠（實作前先跑，必須是紅）\n", indent, dod[tid]
          print
          # _Scenarios: 與 _Requirements: / _Boundary: / _Depends: 同一家族
          if (tid != "" && tid in dod)
              printf "%s- _Scenarios: %s_\n", indent, dod[tid]
          next
      }
      { print }
    ' "$TASKS_FILE" > "$tmp" && mv "$tmp" "$TASKS_FILE"
  fi

  # scenarios.lock：記錄此刻每條 scenario 的內容雜湊，供 trace-verify 比對。
  # 不依賴 git 歷史——rebase 或 squash 之後基準線仍然有效。
  if [ "$DRY_RUN" -eq 0 ]; then
    build_lock > "$LOCK_FILE"
  fi

  local n_tasks n_bound verdict rc
  n_tasks=$(printf '%s\n' "$tasks" | grep -c . || true)
  n_bound=${#bindings[@]}
  verdict="PASS"; rc=0
  if [ ${#no_reqs[@]} -gt 0 ] || [ ${#no_scn[@]} -gt 0 ]; then
    verdict="FAIL"; rc=1
  fi

  local b_json="[" first=1 b
  for b in ${bindings[@]+"${bindings[@]}"}; do
    [ $first -eq 1 ] || b_json+=","
    b_json+="$b"; first=0
  done
  b_json+="]"

  cat <<JSON
{
  "feature": "$(json_escape "$FEATURE")",
  "mode": "bind",
  "dry_run": $([ "$DRY_RUN" -eq 1 ] && echo true || echo false),
  "counts": { "tasks": $n_tasks, "bound": $n_bound },
  "bindings": $b_json,
  "gaps": {
    "task_without_requirements": $(json_array "${no_reqs[@]+"${no_reqs[@]}"}"),
    "task_without_scenario": $(json_array "${no_scn[@]+"${no_scn[@]}"}")
  },
  "verdict": "$verdict"
}
JSON
  return $rc
}

# ---------------------------------------------------------------
# verify
#
# 基準線來自 scenarios.lock（trace-bind 產生），不來自 git 歷史——
# rebase 或 squash 之後 git 基準線會失準，雜湊不會。
#
# 只驗 cc-sdd 結構上看不見的那一層。需求涵蓋、設計漂移、跨 task 整合
# 由 kiro-validate-impl 負責，本模式一律不重複檢查。
# ---------------------------------------------------------------

run_verify() {
  [ -f "$LOCK_FILE" ] || die "scenarios.lock not found: $LOCK_FILE — 先跑 /trace-bind"
  [ -d "$FEATURE_GLOB" ] || die "features dir not found: $FEATURE_GLOB"
  compgen -G "$FEATURE_GLOB/*.feature" >/dev/null || die "no .feature under $FEATURE_GLOB"

  local current
  current="$(build_lock | grep -v '^#' || true)"
  [ -n "$current" ] || die "解析不到任何帶 @SCN 的 scenario"

  local modified=() removed=() added=() tag_changed=() binding_broken=()

  # --- 逐條比對 lock
  local scn hash req bc file title
  while IFS=$'\t' read -r scn hash req bc file title; do
    case "$scn" in '#'*|'') continue ;; esac
    local cur_line
    cur_line="$(printf '%s\n' "$current" | awk -F'\t' -v s="$scn" '$1==s {print; exit}')"
    if [ -z "$cur_line" ]; then
      removed+=("$scn「$title」")
      continue
    fi
    local c_hash c_req c_bc c_title
    c_hash="$(printf '%s' "$cur_line" | cut -f2)"
    c_req="$(printf '%s' "$cur_line" | cut -f3)"
    c_bc="$(printf '%s' "$cur_line" | cut -f4)"
    c_title="$(printf '%s' "$cur_line" | cut -f6)"
    if [ "$c_hash" != "$hash" ]; then
      if [ "$c_title" != "$title" ]; then
        modified+=("$scn 內容與標題皆變更：「$title」→「$c_title」")
      else
        modified+=("$scn「$title」內容變更")
      fi
    fi
    if [ "$c_req" != "$req" ] || [ "$c_bc" != "$bc" ]; then
      tag_changed+=("$scn「$title」 REQ:$req→$c_req BC:$bc→$c_bc")
    fi
  done < "$LOCK_FILE"

  # --- lock 沒有、現在有 → bind 之後新增
  local locked_scns
  locked_scns="$(grep -v '^#' "$LOCK_FILE" | cut -f1 | sort -u || true)"
  while IFS=$'\t' read -r scn hash req bc file title; do
    [ -n "$scn" ] || continue
    printf '%s\n' "$locked_scns" | grep -qx "$scn" || added+=("$scn「$title」")
  done <<< "$current"

  # --- tasks.md 的 _Scenarios:_ 引用了已不存在的 SCN
  if [ -f "$TASKS_FILE" ]; then
    local cur_scns d
    cur_scns="$(printf '%s\n' "$current" | cut -f1 | sort -u)"
    while IFS= read -r d; do
      [ -n "$d" ] || continue
      printf '%s\n' "$cur_scns" | grep -qx "$d" || binding_broken+=("$d")
    done < <(grep -oE '_Scenarios:[^_]*_' "$TASKS_FILE" 2>/dev/null | grep -oE 'SCN-[0-9]+' | sort -u -V || true)
  fi

  # --- 缺 step definition（語言相依，指令來自 toolchain.md）
  local undefined_steps=() dryrun_status="OK" dryrun_cmd=""
  if [ -f "$TOOLCHAIN_FILE" ]; then
    dryrun_cmd="$(grep -oE '^FEATURE_DRYRUN_CMD=.*$' "$TOOLCHAIN_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  fi
  if [ -z "$dryrun_cmd" ]; then
    die "toolchain.md 未定義 FEATURE_DRYRUN_CMD ($TOOLCHAIN_FILE)。若本專案的框架無此能力，明確設為 '-' 以豁免；缺席不等於豁免"
  elif [ "$dryrun_cmd" = "-" ]; then
    dryrun_status="EXEMPT"
  else
    # ⚠️ 不可用 exit code。pytest --generate-missing 在「有缺步驟」時回 0、
    # 「全部實作完」時回 3——反的。一律解析輸出。
    local out
    out="$(eval "${dryrun_cmd//\{FEATURE\}/$FEATURE}" 2>&1 || true)"
    while IFS= read -r l; do
      [ -n "$l" ] && undefined_steps+=("$l")
    done < <(printf '%s\n' "$out" | grep -E 'is not defined|undefined' | sed 's/^[[:space:]]*//' | head -20 || true)
  fi

  local verdict="PASS" rc=0
  if [ ${#modified[@]} -gt 0 ] || [ ${#removed[@]} -gt 0 ] || [ ${#added[@]} -gt 0 ] \
     || [ ${#tag_changed[@]} -gt 0 ] || [ ${#binding_broken[@]} -gt 0 ] \
     || [ ${#undefined_steps[@]} -gt 0 ]; then
    verdict="FAIL"; rc=1
  fi

  cat <<JSON
{
  "feature": "$(json_escape "$FEATURE")",
  "mode": "verify",
  "baseline": "$(json_escape "$LOCK_FILE")",
  "step_definition_check": "$dryrun_status",
  "findings": {
    "scenario_modified": $(json_array "${modified[@]+"${modified[@]}"}"),
    "scenario_removed": $(json_array "${removed[@]+"${removed[@]}"}"),
    "scenario_added_after_bind": $(json_array "${added[@]+"${added[@]}"}"),
    "tag_changed": $(json_array "${tag_changed[@]+"${tag_changed[@]}"}"),
    "binding_broken": $(json_array "${binding_broken[@]+"${binding_broken[@]}"}"),
    "undefined_steps": $(json_array "${undefined_steps[@]+"${undefined_steps[@]}"}")
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
    run_bind
    ;;
  verify)
    run_verify
    ;;
esac
