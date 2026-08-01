#!/usr/bin/env bash
# scn-alloc.sh — 配發 @SCN-NNN 流水號
#
# 用法:
#   scn-alloc.sh peek          印出目前最高水位
#   scn-alloc.sh next <count>  配發 count 個新號碼並推進水位
#
# 水位檔預設 .kiro/scn-highwater（單一整數），刻意放在 specs/ 之外，
# 以免與 cc-sdd 掃描 .kiro/specs/ 找 feature 目錄的行為互相干擾。
#
# 「永不重用」靠水位檔保證：scenario 被刪除後號碼不會回收。
# 自我修復：若掃描到的既有 SCN 大於水位檔（水位檔遺失或過期），以掃描值為準。
#
# Exit code: 0=成功  2=執行錯誤

set -euo pipefail

KIRO_DIR="${KIRO_DIR:-.kiro}"
SPECS_DIR="${SPECS_DIR:-$KIRO_DIR/specs}"
HIGHWATER_FILE="${SCN_HIGHWATER_FILE:-$KIRO_DIR/scn-highwater}"

die() { echo "scn-alloc: $1" >&2; exit 2; }

# 掃描所有 spec 的 .feature，取最大的 SCN 號碼
scan_max() {
  local max=0 n
  while IFS= read -r n; do
    [ -n "$n" ] || continue
    n=$((10#${n#SCN-}))          # 10# 避免前導零被當八進位
    if (( n > max )); then max=$n; fi
  done < <(grep -rhoE '@SCN-[0-9]+' "$SPECS_DIR" 2>/dev/null | tr -d '@' | sort -u || true)
  echo "$max"
}

current() {
  local stored=0 scanned
  if [ -f "$HIGHWATER_FILE" ]; then
    stored="$(tr -dc '0-9' < "$HIGHWATER_FILE")"
    [ -n "$stored" ] || stored=0
    stored=$((10#$stored))
  fi
  scanned="$(scan_max)"
  if (( scanned > stored )); then echo "$scanned"; else echo "$stored"; fi
}

MODE="${1:-}"
case "$MODE" in
  peek)
    current
    ;;
  next)
    count="${2:-1}"
    [[ "$count" =~ ^[0-9]+$ ]] || die "count 必須是正整數，收到: $count"
    (( count > 0 )) || die "count 必須大於 0"
    cur="$(current)"
    new=$(( cur + count ))
    mkdir -p "$(dirname "$HIGHWATER_FILE")"
    printf '%s\n' "$new" > "$HIGHWATER_FILE"
    for (( i = cur + 1; i <= new; i++ )); do
      printf 'SCN-%03d\n' "$i"
    done
    ;;
  *)
    die "用法: scn-alloc.sh {peek|next <count>}"
    ;;
esac
