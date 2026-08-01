# ADR-0010: grill-notes 結構化並納入閘門，grill-me 用兩次

狀態：已決定

## 脈絡

四根柱子的對齊檢查發現：grill-me 在意圖上是柱子，在結構上是可選裝飾。

- ADR-0002 決定用它取代 Spec Kit 的 `clarify`
- `workflow.md` Phase 1 呼叫它，並以散文要求「結束後必須落檔」
- `scenario-write` 與 `manual-qa` 都讀 `grill-notes.md`

但：

- `grill-notes.md` 是自由格式，落檔與否沒有任何閘門檢查
- **沒有任何機制檢查「盤問挖出來的邊界條件有沒有變成 scenario」**
- 跳過 `/grill-me` 整條流程照跑，五道閘門一道都不會叫

ADR-0002 自己就寫了「副作用（正面）：grill-me 逼出來的邊界條件直接就是
Gherkin scenario 的素材」。那條線從一開始就是設計意圖，但從來沒接上。

## 決策

### 1. `grill-notes.md` 結構化

新增 `grill-capture` skill，把盤問結果落檔成固定結構，
並為每條邊界條件與失敗路徑配發 `[BC-nn]` 編號。

### 2. scenario 以 `@BC-nn` 標註覆蓋關係

```gherkin
@SCN-043 @REQ-3.1 @BC-01
Scenario: 匯出剛好一萬筆時不分頁
```

### 3. `trace-check` 驗 BC 覆蓋

`quality-gates.md` 新增一列：BC → scenario 100%。
`grill-notes.md` 不存在時 `exit 2`，不得當作通過。

### 4. grill-me 用兩次

| 時機 | 問什麼 |
|---|---|
| Phase 1（需求探討） | 你想做什麼。挖邊界、失敗路徑、權限邊界、規模上限 |
| Phase 2（情節探討） | 這些情節漏了什麼。對象換成具體的 Given/When/Then |

第二次通常比第一次便宜（你已經想清楚了），但抓到的東西更具體。
新冒出的邊界追加成 BC（只追加不重編），回頭補 scenario。

## 理由

**盤問的價值在於它挖出你原本沒想到的東西——而那正是最容易在後續流程中
被靜默丟掉的東西。** 需求會被寫進 `requirements.md` 受 cc-sdd 的
review gate 保護，設計會被 `kiro-validate-design` 檢查，
只有盤問結果沒有任何下游保護。

BC 編號是把它接進機器裁決鏈的最小改動：不需要新閘門，
沿用既有的 `trace-check` 加一組差集就夠了。

## 為什麼 BC 是每個 feature 從 01 重編

與全域遞增、永不重用的 `@SCN-NNN` 不同（見 ADR-0007）。

理由是引用範圍：`@SCN` 會出現在 `tasks.md`、`qa-results.md` 與 git 歷史，
跨 feature、跨時間被引用，必須全域唯一。`BC` 只在自己 feature 的
scenario tag 裡出現，`trace.sh` 也只在單一 `$SPEC_PATH` 內比對，
不需要全域唯一，也就不需要 high-water 檔的複雜度。

## 代價

- 人的決策點從四個變五個。第二次盤問是新增的時間成本
- `grill-capture` 是又一個「本 repo 產出東西」的 skill，
  延續 ADR-0009 的定位改變
- BC 是自由文字的情境描述，`trace-check` 只能驗**編號有沒有被引用**，
  驗不了「這條 scenario 是否真的涵蓋了那個情境」。
  語意層仍然靠人在核准 requirements 時看

最後一項是本決策的已知上限：它把「完全沒接」變成「編號層接上了」，
不是把語意也自動化了。

## 未解決

`grill-me` 的實際安裝指令尚未確認（npm 上找不到 `grill-me`、
`@mattpocock/grill-me`、`grillme`）。`workflow.md` Phase 1 目前是佔位符。
