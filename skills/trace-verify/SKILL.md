---
name: trace-verify
description: 實作完成後驗證 EARS、scenario、design、task 四方對應是否仍完整，抓出實作過程中的漂移。在所有 task 完成後、mutation-gate 之前執行。
---

執行 `${CLAUDE_SKILL_DIR}/../trace-check/scripts/trace.sh verify $ARGUMENTS`。

這一步抓的是**過程中的漂移**，與 trace-check 不同：
- scenario 被修改（尤其是為了讓測試通過而放寬斷言）
- `.feature` 檔的 tag 被移除，追溯鏈斷掉
- 已綁定的 scenario 在 tasks.md 中失去對應

**先跑 `/kiro-validate-impl`。** 需求涵蓋缺口、設計漂移、跨 task 整合、
boundary 稽核由它負責，本 skill 不重複檢查——重複只會製造兩份可能互相矛盾
的判定。本 skill 只驗 cc-sdd 結構上沒有的那一層：Gherkin scenario。
見 [ADR-0005](../../docs/decisions/0005-cc-sdd-overlap-audit.md)。

**scenario 內容在 bind 之後被修改**是最重要的訊號。
比對 git diff，若 `.feature` 檔在實作階段有變更，逐條列出並要求使用者確認
那是合理的需求演進，而非為了讓測試過關而放水。

不要自行判讀通過與否。
