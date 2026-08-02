---
name: mutation-gate
description: 對本次 diff 涉及的檔案執行 mutation testing，比對 quality-gates.md 的門檻，並把存活的 mutant 翻譯成「哪條測試不夠嚴」。在 trace-verify 通過後執行。
---

執行 `${CLAUDE_SKILL_DIR}/scripts/mutate.sh $ARGUMENTS`，
把輸出的 JSON 整理成人類可讀的形式呈現。

**不要自行判讀通過與否。** 判定來自 exit code：

- `0` = 達標（或 `verdict: SKIPPED`，本次 diff 沒有可 mutate 的檔案）
- `1` = 未達門檻
- `2` = 執行錯誤

不要為未通過的結果找理由，**不要建議調降門檻**。

## 只計 diff scope

門檻讀 `.kiro/steering/quality-gates.md`，
執行指令讀 `.kiro/steering/toolchain.md`（語言相依的只有那兩行）。

分數由腳本自己依模組前綴篩算，**不採用工具給的總分**——
mutation 工具的報表通常是資料庫的累積結果，涵蓋整個專案。

差別是實質的。實測同一個 repo：

```
全域       6 killed / 12 total = 50%
diff scope 3 killed /  7 total = 42%
```

全域分數容易靠灌水達標，diff scope 藏不住。

## 呈現

先講 `score` / `threshold` / `verdict`，再逐一處理 `survivors`。

每個存活的 mutant 要歸類：

- **測試不夠嚴**（斷言太鬆、路徑未覆蓋）→ 需補測試
- **等價 mutant**（語意上無差異）→ 記錄豁免理由

存活的 mutant 常常指向 **scenario 的缺口**而不只是單元測試的缺口。
例如邊界值的 mutant 沒被殺死，通常代表少寫了一條邊界 scenario——
那要退回 `/scenario-write`，不是只補一個 assert。

## exit 2 的常見原因

- `toolchain.md` 未定義 `MUTATION_RUN_CMD` —— 若本專案的語言沒有可用的
  mutation 工具（例如 Go），請在 `quality-gates.md` 明確標為**不適用**，
  不要留一道跑不動的閘門假裝有守
- **diff scope 內沒有任何 mutant** —— 通常是模組前綴推導錯誤
  （改到的檔案不在被 mutate 的來源目錄）。**這不算通過**，
  腳本刻意在這裡停下而不是回報「0/0 達標」
