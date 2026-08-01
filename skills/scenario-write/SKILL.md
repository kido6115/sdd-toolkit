---
name: scenario-write
description: 從 requirements.md 的驗收條件與 grill-notes.md 產出 Gherkin scenario，配發 @SCN 流水號並標註 @REQ 對應。在 kiro-spec-requirements 之後、trace-check 之前執行。這是寫入操作，會建立或追加 .feature 檔。
---

cc-sdd 沒有 Gherkin——它的追溯單位是 `requirements.md` 的章節編號，
結構上不存在 scenario 這一層。`.feature` 檔沒有任何 cc-sdd skill 會產生，
本 skill 補的就是這一步。

## 輸入

- `.kiro/specs/<feature>/requirements.md` —— 驗收條件（`N.M`）
- `.kiro/specs/<feature>/grill-notes.md` —— `[BC-nn]` 邊界條件與失敗路徑，
  以及被否決的替代方案

**`grill-notes.md` 不存在就停下來**，請使用者先跑 `/grill-me` 與
`/grill-capture`。不要在沒有 BC 清單的情況下硬產 scenario——
那等於把整條流程最容易被簡化掉的部分直接跳過。

## 輸出

`.kiro/specs/<feature>/features/*.feature`

檔名 kebab-case，與 `Feature:` 標題對齊，一個 `Feature` 一個檔。
其餘寫法一律遵照 `.kiro/steering/gherkin-guidelines.md`——那份是準則，本檔不重述。

## 編號配發

**不要自己編號。** 執行：

```
${CLAUDE_SKILL_DIR}/scripts/scn-alloc.sh peek        # 查目前水位
${CLAUDE_SKILL_DIR}/scripts/scn-alloc.sh next <n>    # 配發 n 個
```

`@SCN-NNN` 必須單調遞增、永不重用。腳本用 `.kiro/scn-highwater` 保證這件事——
scenario 刪掉之後號碼不會被回收，因為 git 歷史、`qa-results.md`、
舊 `tasks.md` 裡都還有引用。

先數好這次要寫幾條，一次配發，不要邊寫邊要號。

## 規則

1. **只新增，不改寫既有 scenario。**
   已存在的 `@SCN` 區塊原封不動。要改既有 scenario 的內容，
   那是需求變更，走 requirements 流程，不在本 skill 的職責內。

2. **不得發明需求。**
   每條 scenario 都必須掛得上至少一個 `@REQ-N.M`。
   若某條驗收條件寫得無法測（觸發條件不明確、結果不可觀察），
   **回報它，不要硬寫一條 scenario 充數**——那會讓閘門 1 顯示綠燈而實際沒驗到。

3. **不得自行判定涵蓋度。**
   寫完之後告知使用者執行 `/trace-check`，由它的 exit code 認定。
   不要在報告裡宣稱「已涵蓋所有需求」。

4. 一條驗收條件通常需要多條 scenario：正常路徑、邊界、失敗路徑。
   只寫正常路徑是最常見的偷懶。

5. **每條 `[BC-nn]` 都必須有 scenario 覆蓋，並以 `@BC-nn` 標註。**
   一條 scenario 可同時覆蓋多條 BC，一條 BC 也可由多條 scenario 覆蓋。
   涵蓋不到的 BC 逐條回報——通常代表需求漏寫了它，該退回 requirements，
   而不是在這裡放掉。

## 情節探討

草稿完成後、跑 `/trace-check` 之前，對著 scenario 再跑一次 `/grill-me`。

第一次盤問（Phase 1）問的是「你想做什麼」，這一次問的是
**「這些情節漏了什麼」**——同樣的手法，對象換成具體的 Given/When/Then。

盤問中冒出的新邊界，回頭補進 `grill-notes.md` 的 BC 清單（走
`/grill-capture`，只追加不重編），再回來補 scenario。

## 收尾

呈現：

- 本次新增的 scenario 清單（`@SCN` / `@REQ` / `@BC` / 標題）
- 沒有掛上任何 scenario 的驗收條件，逐條列出並說明原因
- **沒有被任何 scenario 覆蓋的 BC**，逐條列出
- 判定為無法測的驗收條件，逐條列出

然後告訴使用者跑 `/trace-check`。
