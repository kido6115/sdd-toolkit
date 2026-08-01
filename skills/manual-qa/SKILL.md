---
name: manual-qa
description: 從 requirements.md 產出使用者導向的人工驗收程序，並記錄執行結果。在 mutation-gate 通過後執行，由人實際操作，不自動化。
---

從 `.kiro/specs/<feature>/requirements.md` 與 grill-notes.md 產出人工驗收程序。

**這一步刻意不自動化。** 機器全綠不代表東西能用——這是整條流程
最後的現實錨點，也是單 agent 架構下唯一無法由機器裁決的閘門。

產出格式：以使用者的語言描述，不用技術術語。
每一項包含：操作步驟、預期結果、實際結果（留空待填）。

特別涵蓋 grill-notes.md 中記錄的邊界條件與失敗路徑——
那些是 grill-me 挖出來的，最容易在實作中被簡化掉。

結果寫入 `.kiro/specs/<feature>/qa-results.md`。

若使用者回報任何一項不通過，退回實作，不得以「機器測試都過了」為由略過。
