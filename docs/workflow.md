# 完整流程

一個 feature 從頭到尾。標示出哪一步是人、哪一步是機器裁決。

假設迭代週期：數天至兩週。前置約一天，其餘時間人只在閘門出現。

---

## Phase 0 — 起手（每專案一次）

```
/kiro-steering
```

產出 `.kiro/steering/` 下的規則：constitution、gherkin 準則、mutation 門檻。
之後不再動。三份治理文件必須是**單一真相來源**——不要同時保留 Spec Kit 的
constitution 和 SwarmForge 的 constitution，會讓 agent 不知道聽誰的。

---

## Phase 1 — 意圖對齊

```
/kiro-discovery "<一句話描述>"
/grill-me
```

grill-me 逐題盤問，你逐題回答。會挖出邊界條件、失敗路徑、權限邊界、規模上限。

**結束後必須落檔**（預設它只是對話，context 一清就沒了）：

```
.kiro/specs/<feature>/grill-notes.md
```

記錄：做的決策、**被否決的替代方案與否決理由**。第二項比第一項重要。

> ⚠️ 這個階段不要 `/clear`。grill-me 會回頭引用你先前的詮釋。

**人的時間：20–40 分鐘。這是整條流程唯一大量消耗你時間的地方。**

---

## Phase 2 — 需求

```
/kiro-spec-requirements     # 讀 grill-notes.md
```

產出：
- `requirements.md` — EARS 格式
- `features/*.feature` — Gherkin

```
/ears-checklist             # 驗 EARS 本身的品質
/trace-check                # 驗 EARS ↔ Gherkin 對應
```

trace-check 輸出範例：

```
EARS-003「當匯出超過 10000 筆時，系統應分頁處理」
  → 無對應 scenario          ❌
SCN-007「匯出時 session 過期」
  → 無對應 EARS（孤兒）      ❌
覆蓋率 8/10
```

**閘門 1：有孤兒就退回補，不往下走。**

---

## Phase 3 — 設計

```
/kiro-spec-design
/trace-check --include-design
```

檢查每條 scenario 是否都有對應的設計決策。

> 註：這一層原本考慮抄 Spec Kit 的 `analyze`，後改為併入 trace。
> 見 [ADR-0003](decisions/0003-fold-analyze-into-trace.md)。

---

## Phase 4 — 任務

```
/kiro-spec-tasks
/trace-bind
```

trace-bind 是**寫入**不是檢查——把每個 task 綁上它要點亮的 scenario：

```
TASK-04  實作分頁匯出   → SCN-003, SCN-004
TASK-07  session 續期   → SCN-007
```

綁定後，每個 task 的 DoD 從「agent 說寫完了」變成
「這兩條 scenario 由紅轉綠」——機器裁決，不是自我宣稱。

---

## Phase 5 — 實作（迴圈）

每個 task 重複：

```
/kiro-spec-impl TASK-04
  1. 先跑 SCN-003, SCN-004 → 必須是紅
  2. 實作
  3. 再跑 → 必須是綠
```

步驟 1 不能省。acceptance-first 要寫進 steering 強制，cc-sdd 預設不管這件事。

**這一段可以整包放手**，因為完成判定是機器的。

---

## Phase 6 — 收尾閘門

```
/trace-verify        # 三方對應是否仍完整
/mutation-gate       # 只計本次 diff 的 mutation score
/manual-qa           # 產出人工程序，由人執行
```

**依序跑，fail-fast。** 不要串在同一則訊息裡——trace 失敗時不該已經燒掉
mutation test 的時間與 token。

`trace-verify` 抓的是實作過程中的漂移：task 被拆了、scenario 被改了、
出現了沒有對應需求的功能。

---

## trace 的三次介入

| 時機 | 動作 | 抓什麼 |
|---|---|---|
| requirements 後 | check | 需求沒測到 / 測了沒需求 |
| tasks 後 | bind | 建立綁定，定義 DoD |
| impl 後 | verify | 過程中的漂移 |

**只做第一次是最常見的偷懶**，那樣它就退化成一次性檢查。

第三次才是真正防止「文件裝飾」的那一次——前面對得好好的，
實作時 agent 為了讓測試過而改了 scenario，只有 verify 抓得到。

---

## 人的決策點

整條流程你只需要出現四次：

1. 回答 grill-me（20–40 分鐘）
2. 核准 requirements（含看 trace-check 報告）
3. 核准 design
4. 執行 manual-qa

---

## 已知風險

**agent 會為了讓 mutation score 過關而寫廢測試**——斷言鬆散、只為殺 mutant。

對策：mutation score 只計 **diff scope**，不計全域。全域分數容易靠灌水達標，
diff scope 藏不住。

**機器全綠不代表東西能用。** manual-qa 是最後的現實錨點，刻意不自動化。
