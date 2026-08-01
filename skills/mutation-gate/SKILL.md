---
name: mutation-gate
description: 對本次 diff 涉及的檔案執行 mutation testing，比對 steering 設定的門檻，並把存活的 mutant 翻譯成「哪條測試不夠嚴」。在 trace-verify 通過後執行。
---

<!-- TODO: 工具與語言綁定，實作前先確定技術棧。
     JS/TS → Stryker
     Python → mutmut 或 cosmic-ray
     Java   → PIT
     Go     → 生態較弱，先評估可行性

     本層的判讀邏輯是語言無關的，只有執行指令需要替換。 -->

執行 `${CLAUDE_SKILL_DIR}/scripts/mutate.sh $ARGUMENTS`。

**只計算本次 diff scope 的 mutation score，不計全域。**
全域分數容易靠灌水達標，diff scope 藏不住。

門檻讀取 `.kiro/steering/quality-gates.md`。

對每個存活的 mutant，說明它屬於哪一類：
- 測試不夠嚴（斷言太鬆、路徑未覆蓋）→ 需補測試
- 等價 mutant（語意上無差異）→ 記錄豁免理由

不要自行判讀通過與否。不要建議調降門檻。
