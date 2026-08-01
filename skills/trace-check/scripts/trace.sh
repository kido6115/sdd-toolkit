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

die() { echo "{\"error\":\"$1\"}" >&2; exit 2; }

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

# 未指定 feature 時，取 .kiro/specs 下最近修改的目錄
if [ -z "$FEATURE" ]; then
  [ -d "$SPECS_DIR" ] || die "specs dir not found: $SPECS_DIR"
  FEATURE="$(ls -t "$SPECS_DIR" 2>/dev/null | head -1)" || true
  [ -n "$FEATURE" ] || die "no feature found under $SPECS_DIR"
fi

SPEC_PATH="$SPECS_DIR/$FEATURE"
[ -d "$SPEC_PATH" ] || die "feature not found: $SPEC_PATH"

# ---------------------------------------------------------------
# ID 慣例（已定案，見 .kiro/steering/gherkin-guidelines.md）
#
#   @REQ-N.M  —— 直接用 cc-sdd requirements.md 的驗收條件編號，不另設別名
#   @SCN-NNN  —— 流水號，不含語意，單調遞增，永不重用
#
# 兩者無序號關聯。SCN-042 → REQ-2.1、SCN-043 → REQ-7.3 皆屬正常，
# 比對為集合運算，順序不參與。
#
# .feature 位置（已定案，見 ADR-0008）
#   契約 $SPEC_PATH/features/*.feature —— 落在所有 task boundary 之外
#   step definition 放專案測試目錄，不在本腳本的掃描範圍
# ---------------------------------------------------------------

REQ_ID_PATTERN='[0-9]+\.[0-9]+'
FEATURE_GLOB="$SPEC_PATH/features"

extract_req_ids() {
  # cc-sdd 的驗收條件編號為 N.M，出現在標題或條列項的行首。
  # 限定行首是為了避開內文裡的版本號與小數。
  #
  # TODO: 對照一份真實產出的 requirements.md 驗證此 pattern。
  #       cc-sdd 未固定驗收條件的排版（標題 / 條列 / 表格皆可能），
  #       實測後可能需要放寬或收緊。
  grep -oE "^[[:space:]]*(#+[[:space:]]*|[-*][[:space:]]+)?${REQ_ID_PATTERN}" \
    "$SPEC_PATH/requirements.md" 2>/dev/null \
    | grep -oE "$REQ_ID_PATTERN" | sort -u -V
}

extract_scn_ids() {
  grep -rhoE '@SCN-[0-9]+' "$FEATURE_GLOB" 2>/dev/null | tr -d '@' | sort -u -V
}

extract_req_refs() {
  # scenario tag 上引用的需求編號
  grep -rhoE '@REQ-[0-9]+\.[0-9]+' "$FEATURE_GLOB" 2>/dev/null \
    | sed 's/^@REQ-//' | sort -u -V
}

extract_bc_ids() {
  # grill-notes.md 的邊界條件編號，格式 "- [BC-01] 描述"
  grep -oE '^\s*-\s*\[BC-[0-9]+\]' "$SPEC_PATH/grill-notes.md" 2>/dev/null \
    | grep -oE 'BC-[0-9]+' | sort -u -V
}

extract_bc_refs() {
  # scenario tag 上引用的邊界條件編號
  grep -rhoE '@BC-[0-9]+' "$FEATURE_GLOB" 2>/dev/null | tr -d '@' | sort -u -V
}

case "$MODE" in
  check)
    echo "TODO: 雙向差集 —— extract_req_ids vs extract_req_refs，輸出缺口 JSON"
    echo "TODO: 孤兒偵測 —— 每個 @SCN 所在 scenario 是否至少帶一個 @REQ"
    echo "TODO: BC 覆蓋 —— extract_bc_ids 每一條是否出現在 extract_bc_refs"
    echo "TODO: grill-notes.md 不存在時 exit 2，不得當作通過"
    echo "TODO: 報告需一併輸出 scenario 標題，ID 本身不可讀"
    [ "$INCLUDE_DESIGN" -eq 1 ] && echo "TODO: 一併檢查 design.md 是否涵蓋所有 scenario"
    ;;
  bind)
    echo "TODO: 寫入 tasks.md，為每個 task 標註 scenario 並改寫 DoD"
    ;;
  verify)
    echo "TODO: git diff 檢查 .feature 檔在實作階段是否被修改（依 @SCN 歸因）"
    echo "TODO: tag 遺失、綁定失效、缺 step definition"
    ;;
esac

echo "--- 尚未實作，回傳 2 以免被誤判為通過 ---" >&2
exit 2
