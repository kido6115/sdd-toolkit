# 閘門範例：一條需求走完五道

用同一條需求貫穿全程，看每道閘門實際攔到什麼。

功能：**訂單匯出**。

---

## 閘門的定義

**判定來自腳本 exit code 或人，且不通過有明確的退回點。**

| | 檢查 | 閘門 |
|---|---|---|
| 判定來源 | agent 讀報告後判斷 | `exit 0/1/2` 或人 |
| agent 角色 | 判讀 | **只轉述** |
| 不通過 | 通常繼續 | 停，退回指定階段 |

`exit 0` 通過、`1` 有缺口、`2` 執行錯誤。**`2` 也是不通過**——
腳本壞掉、設定缺失、掃出空集合，都不等於檢查通過。
例如 `trace.sh` 在 `requirements.md` 抓不到任何 `N.M` 編號時回 `2` 並說明
pattern 可能不符排版，而不是回報「覆蓋率 0/0 通過」。

---

## 素材

`requirements.md`：

```
### 需求 3：大量匯出

3.1 When 匯出筆數超過 10000，the 匯出服務 shall 分頁處理，每頁 10000 筆
3.2 If 匯出過程中 session 過期，the 匯出服務 shall 中止並保留已完成的頁
```

`grill-notes.md`：

```md
## 邊界條件與失敗路徑
- [BC-01] 匯出筆數剛好等於單頁上限
- [BC-04] 目標儲存空間不足
```

`features/export.feature`：

```gherkin
@SCN-042 @REQ-3.1
Scenario: 匯出超過一萬筆時分頁處理
  Given 帳戶有 25000 筆訂單
  When 使用者匯出訂單
  Then 匯出完成
  And 產生 3 個檔案，前兩個各 10000 筆

@SCN-043 @REQ-3.1 @BC-01
Scenario: 匯出剛好一萬筆時不分頁
  Given 帳戶有 10000 筆訂單
  When 使用者匯出訂單
  Then 匯出完成
  And 產生 1 個檔案
```

三種 tag 的來歷不同：

- `@REQ-3.1` —— **直接引用** cc-sdd `requirements.md` 的編號，不另設別名
- `@SCN-042` —— 流水號，不含語意。與 REQ 的序號無關（`SCN-042 → REQ-3.1`、
  `SCN-043 → REQ-7.2` 都正常），比對是集合運算，順序不參與
- `@BC-01` —— grill-me 挖出的邊界條件，每個 feature 從 01 重新編號。
  沒有這層，盤問結果只是散文，跳過整個 Phase 1 不會有閘門發現

`.feature` 的 tag 是整條追溯鏈的支點。格式錯了，五道閘門有三道失效。
慣例見 `.kiro/steering/gherkin-guidelines.md`。

---

## 閘門 1 — `trace-check`（requirements 之後）

問：**每條需求都有 scenario 嗎？每條 scenario 都有需求嗎？**

不通過：

```
REQ-3.2「若 session 過期，中止並保留已完成的頁」
  → 無對應 scenario                    ❌
SCN-051「匯出時網路中斷」
  → 無對應 REQ（孤兒）                  ❌
BC-04「目標儲存空間不足」
  → 無 scenario 覆蓋                    ❌
覆蓋率 8/10
exit 1
```

兩種缺口的意義不同：

- **需求沒 scenario** → 這條不會被測到，寫了等於沒寫
- **孤兒 scenario** → 測了一件沒人要求的事。通常代表**需求漏寫**，
  不是 scenario 多餘。刪 scenario 是最常見的錯誤修法

退回 requirements 補。不往下走。

---

## 閘門 2 — `trace-check --include-design`（design 之後）

問：**每條 scenario 在設計裡有著落嗎？**

```
SCN-042 分頁匯出
  → design.md 無對應章節               ❌
exit 1
```

`design.md` 寫了匯出流程，但沒提分頁怎麼切、檔案怎麼命名、
第 3 個檔案不滿 10000 筆怎麼處理。

這道閘門抓的是**設計時把需求想簡單了**。等到實作階段才發現，
成本高一個數量級。

> 「需求 ↔ 設計」整體的一致性不由這道管，那是 `kiro-validate-design`
> 和 `kiro-validate-impl` 的事。這裡只問 scenario 這一層有沒有被遺漏。

---

## 綁定 — `trace-bind`（tasks 之後，不是閘門）

這步是**寫入**。改寫 `tasks.md`：

```diff
  - [ ] 4.1 實作分頁匯出
    - 讀取訂單並依上限切頁
+   - 驗收條件：SCN-042 由紅轉綠（實作前先跑，必須是紅）
    - _Requirements: 3.1_
+   - _Scenarios: SCN-042_
    - _Boundary: ExportService_
```

寫入的兩行都用 cc-sdd 既有的形式：detail bullet 對應它要求的
「observable completion condition」，`_Scenarios:` 與 `_Requirements:` 同一家族。

**這是整套的樞紐。**

`kiro-impl` 的 Feature Flag Protocol 本來就會做 RED→GREEN，但紅燈的對象是
implementer 自己挑的測試——它自己寫的、自己知道能過的。綁定之後紅燈對象
變成你核准的 scenario，實作者不能挑。

沒綁定的 task 要特別標出。通常代表該 task 不該存在，或需求有缺口。

---

## 閘門 3 — `trace-verify`（實作之後）

前置：先跑 `/kiro-validate-impl`，它回 GO 才跑這道。

問：**scenario 在實作過程中被動過手腳嗎？**

這道有兩層。`.feature` 住在 spec 樹，落在所有 task 的 `_Boundary:_` 之外，
所以 implementer 一動它，**cc-sdd 自己就會先報**：

```
kiro-review  VERDICT: REJECTED
  Boundary Violation: 修改了 .kiro/specs/export/features/export.feature
  該檔案不屬於 task 2.1 的 _Boundary: ExportService_
```

那句話說的是「你不該碰那個檔案」。`trace-verify` 補的是另一句——
**「你把哪條驗收條件放寬了」**。前者是權限問題，後者是語意問題。

基準線是 `trace-bind` 產生的 `scenarios.lock`：

```
SCN-042	a79e2e428afd	REQ-3.1	-	export.feature	分頁匯出
```

實作時 agent 把 `Then 產生 3 個檔案，前兩個各 10000 筆` 拿掉，重算雜湊就對不上：

```json
{
  "baseline": ".kiro/specs/export/scenarios.lock",
  "findings": {
    "scenario_modified": ["SCN-042「分頁匯出」內容變更"],
    "scenario_removed": [],
    "scenario_added_after_bind": [],
    "tag_changed": [],
    "binding_broken": [],
    "undefined_steps": []
  },
  "verdict": "FAIL"
}
```

前面對得好好的：REQ 有 scenario、scenario 有設計、task 有綁定。
斷言拿掉之後——**測試綠了，追溯鏈完整，覆蓋率 100%**，前面每一道都會放行。

**不用 git diff 是刻意的。** git 需要一個「bind 是哪個 commit」的基準線，
rebase 或 squash 之後就失準。雜湊不受歷史重寫影響。
雜湊前會逐行去空白、丟空行，所以重排版不誤報，內容變動才報。

### 改標題規避不了

若 agent 順手把標題也改掉：

```json
"scenario_modified": ["SCN-042 內容與標題皆變更：「分頁匯出」→「匯出大量訂單」"]
```

若 scenario 的身分是標題，這在機器眼裡會是「一條消失、一條出現」，
看起來像重構。`@SCN-042` 讓身分在內容改變後存活——這就是
[ADR-0007](decisions/0007-scenario-id-convention.md) 堅持給 scenario
一個不含語意 ID 的理由。

你要判斷：這是合理的需求演進（回頭改 requirements，重跑 `/trace-bind` 更新 lock），
還是為了讓測試過關而放水（退回實作）。

### 另外四種發現

| 欄位 | 意義 |
|---|---|
| `scenario_removed` | 整條不見了 |
| `scenario_added_after_bind` | 偷加了沒經核准的 scenario |
| `tag_changed` | `@REQ` / `@BC` 被增刪 |
| `undefined_steps` | 有 scenario 但沒人實作步驟——等同不存在 |

最後一項靠測試框架的 dry-run（指令在 `toolchain.md`），
且**一律解析輸出不看 exit code**——pytest 的 `--generate-missing`
在有缺步驟時回 `0`、全部實作完回 `3`，是反的。

---

## 閘門 4 — `mutation-gate`

問：**測試夠嚴嗎？**

只計本次 diff 涉及的檔案。

```json
{
  "scope": "diff",
  "counts": { "killed": 3, "survived": 4, "total": 7 },
  "score": 42,
  "threshold": 60,
  "survivors": ["exporter.paginator.x_page_count__mutmut_1", "..."],
  "verdict": "FAIL"
}
```

分數由腳本自己依模組前綴篩算，**不採用工具給的總分**——
mutation 工具的報表通常是資料庫累積結果。實測同一個 repo
全域 50%、diff scope 42%，全域分數容易靠灌水達標。

存活的 mutant 裡若有 `total > size` → `total >= size` 這種，
代表邊界值 `total == size` 沒有測試涵蓋。
SCN-042 用 25000 筆，測不到邊界。SCN-043 才是那條邊界 scenario。

每個存活的 mutant 要歸類：

- **測試不夠嚴** → 補測試（這個屬於這類，應該補一條 10000 整的 scenario）
- **等價 mutant** → 語意上無差異，記錄豁免理由

不要自行判讀通過與否，不要建議調降門檻。

---

## 閘門 5 — `manual-qa`

**刻意不自動化。** 前面四道全綠不代表東西能用。

從 `requirements.md` 與 `grill-notes.md` 產出程序，用使用者的語言：

```md
### 3. 匯出兩萬五千筆訂單

步驟：
  1. 用有 25000 筆訂單的帳號登入
  2. 訂單列表 → 匯出全部
預期：
  收到 3 個檔案，前兩個各 10000 筆，第 3 個 5000 筆
  匯出期間頁面可正常操作
實際：（待填）
```

特別涵蓋 `grill-notes.md` 裡的邊界條件與失敗路徑——那些是 grill-me
挖出來的，最容易在實作中被簡化掉。

結果寫入 `qa-results.md`。任何一項不通過即退回實作，
**不得以「機器測試都過了」為由略過**。

---

## 為什麼是這個順序

依序跑，fail-fast，不要串在同一則訊息裡。

trace 失敗時不該已經燒掉 mutation test 的時間與 token——
mutation testing 是整條流程最貴的一步，把它放在最後一道機器閘門。

`manual-qa` 在最後，因為它燒的是**你的時間**，比 token 貴。

| 閘門 | 判定 | 退回 |
|---|---|---|
| 1 `trace-check` | exit code | requirements |
| 2 `trace-check --include-design` | exit code | design |
| 3 `trace-verify` | exit code + 人確認變更 | 實作 |
| 4 `mutation-gate` | 分數 vs `quality-gates.md` | 補測試 |
| 5 `manual-qa` | **人** | 實作 |

cc-sdd 另有三道，不用你管：`requirements-review-gate`（寫檔前阻擋）、
`kiro-review`（APPROVED / REJECTED）、`kiro-validate-impl`（GO / NO-GO）。
