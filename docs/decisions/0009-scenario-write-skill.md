# ADR-0009: 新增 scenario-write，本 repo 不再只做驗收

狀態：已決定

## 脈絡

稽核發現一個結構性缺口：**沒有任何一步產生 `.feature` 檔。**

- cc-sdd 零 Gherkin（17 個 skill 全文檢索無命中，見 ADR-0005）
- 本 repo 五個 skill 全是驗證性的：`trace-check` 檢查它、`trace-bind` 綁定它、
  `trace-verify` 驗證它、`mutation-gate` 間接依賴它、`manual-qa` 引用它

整條閘門鏈建立在一個沒人生產的成品上。

`docs/workflow.md` 原本把 `features/*.feature` 列為 `/kiro-spec-requirements`
的產出，那是錯的——cc-sdd 不會產生它。

## 決策

新增 `scenario-write` skill，附可執行的 `scripts/scn-alloc.sh`。

在 `/kiro-spec-requirements` 之後、`/trace-check` 之前執行。

## 理由

### 為什麼是 skill，不是 steering 裡的一段 prose

考慮過靠 steering 讓 `/kiro-spec-requirements` 順手產出 scenario，成本為零。
但 ADR-0007 給 `@SCN-NNN` 訂了硬性要求：**單調遞增、永不重用**。

這件事需要**讀取既有檔案再決定號碼**，而且「永不重用」還要求記住已刪除的號碼。
prose 保證不了，agent 每次都得自己掃、容易撞號，刪掉的號碼還會被回收。

`scn-alloc.sh` 用 `.kiro/scn-highwater` 保證這件事，並在水位檔遺失時
以掃描值自我修復。這是本 repo 第一支非 stub 的腳本。

### 定位的改變

README 原本把本 repo 定義為「驗收與追溯層」，全部是驗證性 skill。
加一個會**寫** `.feature` 的 skill 等於承認它也要管產出。

這條線其實早就跨過了——`trace-bind` 一直在寫 `tasks.md`。
差別只是 `scenario-write` 產出的是主要成品而非標註。

接受這個定位改變。理由是：**驗收成品的產生權必須留在核准鏈上。**
如果 `.feature` 由 `kiro-impl` 或任何實作端產生，紅燈對象就又回到
「實作者自己挑的測試」，整套設計的前提就沒了。

## 職責邊界

`scenario-write` **不做**三件事，維持與其餘 skill 一致的紀律：

1. **不改寫既有 scenario。** 只新增。要改既有內容是需求變更，走 requirements 流程
2. **不發明需求。** 驗收條件若寫得無法測，回報它，不硬寫 scenario 充數——
   那會讓閘門 1 顯示綠燈而實際沒驗到
3. **不自行判定涵蓋度。** 寫完交給 `/trace-check` 的 exit code 認定

第 2 點是最容易被違反的：agent 傾向於為每條需求生出一條 scenario 好讓數字好看。

## 代價

- 多一步人工觸發。無法併進 `/kiro-spec-requirements`，因為那是 cc-sdd 的 skill
- `.kiro/scn-highwater` 是一個必須進版控的狀態檔。遺失會導致號碼回收——
  腳本的自我修復只能救回「仍存在於 `.feature` 中」的號碼，
  已刪除 scenario 的號碼救不回來
