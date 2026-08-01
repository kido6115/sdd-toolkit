# 完整流程

一個 feature 從頭到尾。標示出哪一步是人、哪一步是機器裁決。

假設迭代週期：數天至兩週。前置約一天，其餘時間人只在閘門出現。

---

## Phase 0 — 起手

```
/kiro-steering                              # 產出 product.md / tech.md / structure.md
cp steering-custom/*.md .kiro/steering/     # 補三份 cc-sdd 沒有的
cp -r skills/* .claude/skills/
```

`.kiro/steering/` 由 cc-sdd 當家，本 toolkit 只補它缺的那幾片：

| 檔案 | 來源 | 更新時機 |
|---|---|---|
| `product.md` `tech.md` `structure.md` | `/kiro-steering` | **持續同步**。cc-sdd 定位它是 bootstrap/sync，擴充既有系統時要重跑 |
| `acceptance-discipline.md` `gherkin-guidelines.md` `quality-gates.md` | 本 toolkit 範本 | 複製後**由該專案自行維護**，不連回上游 |

複製而非 symlink：steering 是專案記憶，一個專案的門檻調整不該波及其他專案。
見 [ADR-0006](decisions/0006-steering-follows-cc-sdd.md)。

**只有 `cp` 那兩行是每專案一次。`/kiro-steering` 不是。**

它自己分兩個模式：目錄空的走 bootstrap，三份 core 都在就走 sync——
sync 會偵測 code drift 並 additive 更新（既有的使用者修改不會被蓋掉）。

重跑時機：**接既有系統之前、或前一個 feature 明顯改動了架構之後**。
17 個 cc-sdd skill 裡有 10 個在 Step 1 讀 `product.md` / `tech.md` / `structure.md`
（discovery、requirements、design、tasks、impl、三個 validate…，
連 `kiro-impl` 派給 implementer subagent 的 prompt 都帶著）。

> ⚠️ **沒有任何 skill 會自動觸發 `/kiro-steering`。** steering 過期
> 等於接下來每個 feature 的每一步都吃到過期的 context，而且沒有閘門會抓到。
> 這是目前流程中唯一完全靠人自覺的環節。

> ⚠️ `.kiro/steering/` **不會**被 Claude Code 自動載入。那是 Kiro IDE 靠
> front-matter `inclusion: always` 做的事。在 Claude Code 底下，只有 `CLAUDE.md`
> 會自動進 context；steering 必須由 skill 內文明確指名才會被讀到。
> 目前只有 `quality-gates.md` 有載入路徑（`mutation-gate` 指名它）。
> 見 [ADR-0005](decisions/0005-cc-sdd-overlap-audit.md)。

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
/kiro-spec-init "<描述>"    # 建立 spec.json 與目錄骨架（不可略過，後續 skill 都讀 spec.json）
/kiro-spec-requirements     # 讀 grill-notes.md
```

產出：
- `requirements.md` — EARS 格式
- `features/*.feature` — Gherkin，**住在 spec 樹裡**

`.feature` 放 `.kiro/specs/<feature>/features/`，step definition 放專案測試目錄。
理由不是整齊——契約落在所有 task `_Boundary:_` 之外，implementer 動它就是
boundary violation，cc-sdd 的 `kiro-review` 會抓。
見 [ADR-0008](decisions/0008-feature-file-location.md)。

```
/trace-check                # 驗需求 ↔ scenario 雙向對應
```

> EARS 本身的品質**不用另外驗**。`/kiro-spec-requirements` 內部已跑過
> `requirements-review-gate.md`：EARS 語法、可測性、數字 ID、實作細節外洩、
> 涵蓋度，全部檢過才寫檔，最多兩輪自我修復。
> 本 toolkit 原有的 `ears-checklist` 因此已刪除，見 [ADR-0005](decisions/0005-cc-sdd-overlap-audit.md)。
>
> `trace-check` 驗的是它管不到的那一軸：EARS 與 scenario 的雙向對應。

trace-check 輸出範例：

```
REQ-3.1「當匯出超過 10000 筆時，系統應分頁處理」
  → 無對應 scenario          ❌
SCN-051「匯出時 session 過期」
  → 無對應 REQ（孤兒）       ❌
覆蓋率 8/10
```

**閘門 1：有孤兒就退回補，不往下走。**

---

## Phase 3 — 設計

```
/kiro-validate-gap          # 選用：接既有系統時先做缺口分析
/kiro-spec-design
/kiro-validate-design       # cc-sdd 內建的設計品質互動式 review
/trace-check --include-design
```

檢查每條 scenario 是否都有對應的設計決策。

> 「需求 ↔ 設計」的一致性分析**不由 trace 做**——那是 `kiro-validate-design`
> 與 Phase 6 的 `kiro-validate-impl` 的職責。`--include-design` 只問一件事：
> scenario 這一層有沒有被設計遺漏。
>
> 原本計畫抄 Spec Kit 的 `analyze` 併進 trace，該決策已修訂，
> 見 [ADR-0003](decisions/0003-fold-analyze-into-trace.md)。

---

## Phase 4 — 任務

```
/kiro-spec-tasks
/trace-bind
```

trace-bind 是**寫入**不是檢查——把每個 task 綁上它要點亮的 scenario：

```
4.1  實作分頁匯出   → SCN-042, SCN-043
7.2  session 續期   → SCN-051
```

綁定後，每個 task 的 DoD 從「agent 說寫完了」變成
「這兩條 scenario 由紅轉綠」——機器裁決，不是自我宣稱。

---

## Phase 5 — 實作（迴圈）

```
/kiro-impl <feature>        # autonomous：全部 pending task
/kiro-impl <feature> 1.1    # manual：指定 task
```

autonomous 模式下，cc-sdd 每個 task 跑一輪：

```
fresh implementer subagent
  → kiro-review（獨立 reviewer subagent，自己跑 git diff，不信 implementer 回報）
  → APPROVED 才套 kiro-verify-completion
  → 才打勾、才 commit
REJECTED 兩輪 → fresh debugger subagent（乾淨 context，避免無限重試）
```

acceptance-first 由 cc-sdd 的 **Feature Flag Protocol** 強制：加旗標（預設 OFF）
→ 寫測試，旗標 OFF 時**必須紅**（會過就是測錯東西，退回重寫）→ 開旗標實作
→ 綠 → 移除旗標 → 仍須綠。

本 toolkit 在這一段的增量只剩一件事，但它是關鍵的一件：
**cc-sdd 的紅燈是 implementer 自己寫的測試**——它自己挑的、自己知道能過的。
`trace-bind` 把 DoD 換成「指定 scenario 由紅轉綠」，
差別在紅燈的定義權在誰手上。見 `acceptance-discipline.md` 第 4 條。

這一段 implementer 該寫的是 **step definition**（在專案測試目錄），
不是 `.feature`。後者唯讀，而且落在 boundary 之外——它去改就會被
`kiro-review` 判為 violation。

**這一段可以整包放手**，因為完成判定是機器的。

---

## Phase 6 — 收尾閘門

```
/kiro-validate-impl  # cc-sdd 的 GO / NO-GO 閘門（autonomous 模式會自動跑）
/trace-verify        # scenario 有沒有被竄改
/mutation-gate       # 只計本次 diff 的 mutation score
/manual-qa           # 產出人工程序，由人執行
```

**依序跑，fail-fast。** 不要串在同一則訊息裡——前一道失敗時不該已經燒掉
mutation test 的時間與 token。

`/kiro-validate-impl` 負責：全測試套件、smoke boot、需求涵蓋矩陣、
設計端到端對齊與架構漂移、跨 task 整合、boundary 稽核、殘留 TODO 與硬編密鑰。
**這些 `trace-verify` 一律不重複做。**

`trace-verify` 只抓 cc-sdd 結構上看不見的那一層：scenario 在 bind 之後被修改
（尤其是斷言被放寬）、`.feature` 的 tag 被移除、綁定失效、scenario 沒有
對應的 step definition。

---

## trace 的三次介入

| 時機 | 動作 | 抓什麼 |
|---|---|---|
| requirements 後 | check | 需求沒測到 / 測了沒需求 |
| tasks 後 | bind | 建立綁定，定義 DoD |
| impl 後 | verify | scenario 被竄改 / tag 遺失 / 綁定失效 |

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
