#!/usr/bin/env bash
# 把本 toolkit 接進目標專案。
# 用 symlink 而非複製：改一次，所有專案生效。

set -euo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "用法: ./install.sh /path/to/your/project" >&2
  exit 1
fi
[ -d "$TARGET" ] || { echo "目標目錄不存在: $TARGET" >&2; exit 1; }

SRC="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$TARGET/.claude/skills" "$TARGET/.kiro/steering"

for d in "$SRC"/skills/*/; do
  name="$(basename "$d")"
  ln -sfn "$d" "$TARGET/.claude/skills/$name"
  echo "  skill    → .claude/skills/$name"
done

for f in "$SRC"/steering/*.md; do
  name="$(basename "$f")"
  ln -sfn "$f" "$TARGET/.kiro/steering/$name"
  echo "  steering → .kiro/steering/$name"
done

echo
echo "完成。注意："
echo "  - steering 是 symlink，改動會影響所有已安裝的專案"
echo "  - 專案專屬的規則請另外寫在 .kiro/steering/ 下的獨立檔案"
