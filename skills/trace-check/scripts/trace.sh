#!/usr/bin/env bash
# trace.sh — EARS / scenario / design / task 四方追溯
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
# TODO: 以下為待實作區塊。實作前需先確定兩件事：
#
#   1. EARS ID 慣例 —— requirements.md 裡怎麼標？
#      候選: EARS-001 / REQ-1.1 / 無編號（需先加）
#      下方 EARS_ID_PATTERN 依此調整。
#
#   2. .feature 檔位置 —— 見 steering/gherkin-guidelines.md 的 TODO
#      A. $SPEC_PATH/features/*.feature
#      B. 專案既有測試目錄
#      下方 FEATURE_GLOB 依此調整。
# ---------------------------------------------------------------

EARS_ID_PATTERN='EARS-[0-9]{3}'      # TODO: 確認慣例後調整
FEATURE_GLOB="$SPEC_PATH/features"   # TODO: 確認位置後調整

extract_ears_ids() {
  grep -oE "$EARS_ID_PATTERN" "$SPEC_PATH/requirements.md" 2>/dev/null | sort -u
}

extract_scenario_tags() {
  # 依賴 gherkin-guidelines.md 約定的 @SCN-xxx @EARS-xxx tag 格式
  grep -rhoE '@SCN-[0-9]{3}|@EARS-[0-9]{3}' "$FEATURE_GLOB" 2>/dev/null | tr -d '@' | sort -u
}

case "$MODE" in
  check)
    echo "TODO: 比對 EARS ID 與 scenario tag，輸出雙向缺口 JSON"
    [ "$INCLUDE_DESIGN" -eq 1 ] && echo "TODO: 一併檢查 design.md 是否涵蓋所有 scenario"
    ;;
  bind)
    echo "TODO: 寫入 tasks.md，為每個 task 標註 scenario 並改寫 DoD"
    ;;
  verify)
    echo "TODO: 四方對應驗證 + git diff 檢查 .feature 檔在實作階段是否被修改"
    ;;
esac

echo "--- 尚未實作，回傳 2 以免被誤判為通過 ---" >&2
exit 2
