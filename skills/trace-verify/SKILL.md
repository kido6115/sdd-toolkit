---
name: trace-verify
description: 實作完成後驗證 EARS、scenario、design、task 四方對應是否仍完整，抓出實作過程中的漂移。在所有 task 完成後、mutation-gate 之前執行。
---

執行 `${CLAUDE_SKILL_DIR}/../trace-check/scripts/trace.sh verify $ARGUMENTS`。

這一步抓的是**過程中的漂移**，與 trace-check 不同：
- task 在實作中被拆分或合併，綁定失效
- scenario 被修改（尤其是為了讓測試通過而放寬斷言）
- 出現了沒有對應需求的新功能
- `.feature` 檔的 tag 被移除

**scenario 內容在 bind 之後被修改**是最重要的訊號。
比對 git diff，若 `.feature` 檔在實作階段有變更，逐條列出並要求使用者確認
那是合理的需求演進，而非為了讓測試過關而放水。

不要自行判讀通過與否。
