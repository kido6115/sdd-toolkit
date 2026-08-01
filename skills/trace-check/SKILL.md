---
name: trace-check
description: 檢查 EARS 需求與 Gherkin scenario 的對應是否完整，找出沒有測試的需求與沒有需求的孤兒 scenario。在 kiro-spec-requirements 之後、進入 design 之前執行。加上 --include-design 時一併檢查 design.md 是否涵蓋所有 scenario。
---

執行 `${CLAUDE_SKILL_DIR}/scripts/trace.sh check $ARGUMENTS`，
把輸出的 JSON 報告整理成人類可讀的形式呈現。

**不要自行判讀通過與否。** 判定結果來自腳本的 exit code：
- 0 = 通過
- 1 = 有缺口，呈現缺口清單並告知使用者需退回 requirements 補齊
- 2 = 執行錯誤，呈現錯誤訊息

不要為未通過的結果找理由，不要建議使用者略過。

<!-- TODO: 若 scripts/trace.sh 尚未實作，本 skill 無法運作。 -->
