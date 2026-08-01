---
name: grill-capture
description: 把 grill-me 的盤問結果落檔成結構化的 grill-notes.md，為每條邊界條件與失敗路徑配發 BC 編號。在 grill-me 結束後、kiro-spec-requirements 之前執行。這是寫入操作。
---

`/grill-me` 預設只是對話，context 一清就沒了。本 skill 把它落檔，
並把「邊界條件」變成**可被閘門檢查的東西**。

## 為什麼要結構化

grill-me 挖出來的邊界條件與失敗路徑，是整條流程裡最容易在實作中被簡化掉的部分。
若只寫成散文，沒有任何機制能檢查它們有沒有變成 scenario——
跳過 grill-me 整條流程照跑，五道閘門一道都不會叫。

配上 BC 編號之後，`trace-check` 就能驗「每條 BC 都有 scenario 覆蓋」。

## 輸出

`.kiro/specs/<feature>/grill-notes.md`

```md
# grill-notes: <feature>

## 決策

<散文。這次盤問確定下來的事。>

## 被否決的替代方案

<散文。**這節比上一節重要**——它記錄的是「為什麼不那樣做」，
 是六個月後最難重建、也最容易被推翻重來的東西。>

## 邊界條件與失敗路徑

- [BC-01] 匯出筆數剛好等於單頁上限
- [BC-02] 匯出過程中 session 過期
- [BC-03] 匯出過程中使用者被降權
- [BC-04] 目標儲存空間不足

## 規模上限

<散文。量級假設：資料筆數、併發、時間窗。>

## 權限邊界

<散文。誰能做什麼、誰不能。>
```

## BC 編號規則

- **每個 feature 從 `BC-01` 重新開始。** 與 `@SCN-NNN` 不同，BC 只在自己的
  feature 內被引用，不會出現在 `tasks.md`、`qa-results.md` 或跨 feature 的地方，
  因此不需要全域唯一
- 只追加，不重編。既有的 BC 編號在後續補充時保持不變
- 一條 BC 只描述**一個**情境。「session 過期或權限變更」要拆成兩條

## 規則

1. **只記錄盤問中實際出現的內容。** 不要為了讓清單看起來完整而補上
   grill-me 沒問到的邊界。那會產生沒有依據的驗收條件。

2. **被否決的替代方案不可省略。** 若這次盤問沒有否決任何方案，
   明確寫「無」，不要留白——留白讀起來像忘了寫。

3. **不要在這一步寫 EARS 或 Gherkin。** BC 是自然語言的情境描述，
   轉成需求是 `/kiro-spec-requirements` 的事，轉成 scenario 是
   `/scenario-write` 的事。

## 下一步

告知使用者：`grill-notes.md` 會被 `/kiro-spec-requirements`、
`/scenario-write`、`/manual-qa` 三處讀取，且每條 BC 都必須在
`/trace-check` 時有對應的 scenario。
