# ADR-0005: 與 cc-sdd 3.0.2 的重疊稽核

狀態：已決定（部分待定，見文末）

## 脈絡

ADR-0001 決定以 cc-sdd 為主體，理由之一是「cc-sdd 的品質閘門比 Spec Kit 弱，
需自行補齊（本 repo 的存在理由）」。

該判斷基於較早的 cc-sdd 版本。實際拆解 npm 上的 `cc-sdd@3.0.2` 後，
發現它已內建 17 個 skill，本 repo 的多項設計前提失效。

以下為逐項比對結果。

## cc-sdd 3.0.2 的 17 個 skill

主線六步：`kiro-discovery` → `kiro-spec-init` → `kiro-spec-requirements`
→ `kiro-spec-design` → `kiro-spec-tasks` → `kiro-impl`

| Skill | 用途 |
|---|---|
| `kiro-steering` | 維護 `.kiro/steering/` 的 product / tech / structure。定位是 **bootstrap/sync**，不是一次性 |
| `kiro-steering-custom` | 產出領域專屬的 steering 檔 |
| `kiro-discovery` | 入口分流：擴充既有 spec / 開新 spec / 拆解 / 不需要 spec |
| `kiro-spec-init` | 建立 spec.json 與目錄骨架 |
| `kiro-spec-requirements` | 產出 EARS 需求，內建 `requirements-review-gate` |
| `kiro-spec-design` | 產出架構、Mermaid、File Structure Plan、Boundary Commitments |
| `kiro-spec-tasks` | 產出 task，附 `_Boundary:_` `_Depends:_` 標註 |
| `kiro-spec-batch` | roadmap 平行展開成多份 spec，依相依波次 |
| `kiro-spec-quick` | 精簡版 spec 生成 |
| `kiro-spec-status` | 顯示 spec 進度 |
| `kiro-impl` | TDD 實作。autonomous 模式派發 subagent |
| `kiro-review` | 對抗式 task-local review，自己跑 git diff，不信 implementer 回報 |
| `kiro-debug` | 乾淨 context 的根因調查，避免無限重試 |
| `kiro-verify-completion` | 阻擋不實的完成宣稱，要求 fresh evidence |
| `kiro-validate-impl` | feature 層 GO / NO-GO 閘門 |
| `kiro-validate-design` | 設計品質互動式 review |
| `kiro-validate-gap` | 需求與既有 codebase 的缺口分析 |

## 重疊項

### 1. `ears-checklist` — 完全重複，建議廢除

cc-sdd 的 `requirements-review-gate.md` 在**寫檔之前**執行，涵蓋：
EARS 語法（對照 `ears-format.md` 的五種模式）、可測性、數字 ID、
實作細節外洩、涵蓋度（核心旅程／邊界／錯誤路徑／邊緣條件）、
矛盾與模糊語言正規化。最多兩輪自我修復，不過就升級問使用者。

本 toolkit 的 `ears-checklist` 是**事後**檢查，項目是上述的子集，
且原始設計就是「抄自 Spec Kit 的 checklist」——現在等於抄了第三份。

**事前阻擋優於事後檢查。** 這個 skill 沒有存在理由。

### 2. `trace-verify` — 大幅重疊，需縮減職責

`kiro-validate-impl` 已經做了 `trace-verify` 宣稱要做的多數事情：

| trace-verify 宣稱抓的 | kiro-validate-impl 對應項 |
|---|---|
| 出現沒有對應需求的新功能 | F. Requirements Coverage Gaps |
| 設計漂移 | G. Design End-to-End Alignment |
| task 被拆分或合併 | G.5 Boundary Audit + H. Blocked Tasks |

`trace-verify` 唯一不重疊的是 **Gherkin 那一層**：`.feature` 檔的 tag 是否被移除、
scenario 是否在 bind 之後被竄改（尤其是為了讓測試過而放寬斷言）。
cc-sdd 完全沒有 Gherkin 概念，抓不到這件事。

**縮減為只驗 Gherkin 層，其餘讓 `kiro-validate-impl` 做。**

### 3. `constitution.md` 三條 — 重複，改為指向 cc-sdd 機制

| 條文 | cc-sdd 對應 |
|---|---|
| 3. acceptance-first，先跑紅燈 | `kiro-impl` 的 Feature Flag Protocol：旗標 OFF 時測試必須紅，會過就退回重寫 |
| 4. DoD 不是 agent 自我宣稱 | `kiro-review` 回 APPROVED + `kiro-verify-completion` 才准打勾 |
| 8. 不可自我圓場 | `kiro-verify-completion` 整份，含 Common Rationalizations 對照表 |

依「單一治理真相來源」原則，重述等於製造第二份。改為指名 cc-sdd 的機制。

## 未重疊項 — 本 repo 真正的增量

對整包 `cc-sdd@3.0.2` 做全文檢索，以下**零命中**：

- **Gherkin** —— 沒有任何 `.feature`、scenario、Given/When/Then 的概念
- **mutation testing** —— 沒有 mutant、沒有測試強度的量化
- **人工驗收** —— 沒有 manual QA，`MANUAL_VERIFY_REQUIRED` 只是「機器測不了」的逃生口，不是驗收程序

另有一項結構性差異：cc-sdd 的追溯單位是 **requirements.md 的章節編號**，
而且 `kiro-impl` 明令「do NOT invent `REQ-*` aliases」。它沒有 scenario 這一層，
因此不存在 EARS ↔ scenario 的雙向 ID 對應。`trace-check` / `trace-bind` 建立的
是 cc-sdd 結構上沒有的東西。

**結論：`trace-check`、`trace-bind`、`mutation-gate`、`manual-qa` 站得住，
`ears-checklist` 不成立，`trace-verify` 需縮減。**

## 對 ADR-0001 與 ADR-0004 的影響

**ADR-0001**「cc-sdd 的品質閘門比 Spec Kit 弱」——對 3.0.2 已不成立。
決策結論（採 cc-sdd 為主體）不變，但理由要換：不是「弱所以要補」，
而是「強，但只強在單元測試軸；驗收軸與測試強度軸仍是空的」。

**ADR-0004**「單 agent，不引入多 agent 協調成本」——**前提失效**。
`kiro-impl` 的 autonomous 模式本身就是多 agent：每 task 一個 fresh implementer
subagent、一個獨立 reviewer subagent、失敗時一個 fresh debugger subagent。
選項從來不是「單 agent vs SwarmForge」，而是「cc-sdd 已有的 subagent 編排
vs 再疊一層自己的」。ADR-0004 的**結論**仍成立（不自建協調層），但推理需重寫。

## 待定

1. `ears-checklist` 直接刪除，或保留為薄殼只做 `requirements-review-gate`
   未涵蓋的部分（目前看不出有哪部分）
2. `trace-verify` 縮減後，`quality-gates.md` 的四項追溯門檻中
   「scenario → design」「scenario → task」是否轉由 `kiro-validate-impl` 認定
