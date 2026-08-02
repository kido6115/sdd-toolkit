# sdd-toolkit

在 cc-sdd 之上補齊「驗收與追溯」層的 skill 集合。

## 這是什麼

cc-sdd 3.x 的實作紀律其實不弱——它有 TDD 的 RED→GREEN 強制、獨立 reviewer、
不實完成宣稱的防護、feature 層的 GO/NO-GO 閘門。

但它驗的是**實作者自己寫的測試會不會過**。它不驗那些測試是否對應到你核准的
驗收條件，也不驗那些測試夠不夠嚴。這個 repo 補的就是那兩件事。

取自 Uncle Bob 的 SwarmForge 的是**驗收紀律**——Gherkin 可執行、
mutation testing、人工 QA 不可省——不是它的多 agent 協調架構。
agent 數量是 cc-sdd 的實作細節，不是這裡的決策軸。見 [ADR-0004](docs/decisions/0004-single-agent-not-swarm.md)。

## 組成

| 層 | 來源 | 說明 |
|---|---|---|
| 主體流程 | cc-sdd (17 skills) | steering / discovery / spec / impl / review / validate |
| 意圖對齊 | grill-me (mattpocock) | 需求探討與情節探討各盤問一次 |
| **盤問落檔** | grill-capture | 本 repo。配發 `[BC-nn]`，讓盤問結果進入驗證鏈 |
| Gherkin 品質 | gherkin-guidelines-for-ai | 掛進 steering |
| **驗收成品** | scenario-write | 本 repo |
| **追溯** | trace-check / trace-bind / trace-verify | 本 repo |
| **測試強度** | mutation-gate | 本 repo。Python 用 mutmut，語言相依只在 `toolchain.md` |
| **人工驗收** | manual-qa | 本 repo |

粗體是這個 repo 真正原創的部分，其餘是接線。

對 `cc-sdd@3.0.2` 全部 17 個 skill 做過逐項稽核：**Gherkin、mutation testing、
人工驗收三軸零命中**。cc-sdd 的追溯單位是 `requirements.md` 的章節編號，
結構上沒有 scenario 這一層，所以 `trace-*` 建立的不是重複的輪子。
完整比對見 [ADR-0005](docs/decisions/0005-cc-sdd-overlap-audit.md)。

追溯的 tag 慣例是 `@SCN-042 @REQ-3.1`——需求直接引用 cc-sdd 的編號，
scenario 用不含語意的流水號。見 [ADR-0007](docs/decisions/0007-scenario-id-convention.md)。

### 已刪除

- `ears-checklist` —— 與 cc-sdd 內建的 `requirements-review-gate` 完全重複，
  且對方在寫檔前阻擋，更強
- `install.sh` —— 見 [ADR-0006](docs/decisions/0006-steering-follows-cc-sdd.md)

## 職責邊界

不重複做 cc-sdd 已經做的事。兩套判定並存只會產出互相矛盾的報告。

| 事項 | 由誰負責 |
|---|---|
| EARS 需求品質 | cc-sdd `requirements-review-gate` |
| RED → GREEN 機制 | cc-sdd `kiro-impl` Feature Flag Protocol |
| task 獨立審查 | cc-sdd `kiro-review` |
| 不實完成宣稱 | cc-sdd `kiro-verify-completion` |
| 需求涵蓋、設計漂移、跨 task 整合 | cc-sdd `kiro-validate-impl` |
| **盤問結果結構化** | 本 repo `grill-capture` |
| **產出 Gherkin scenario** | 本 repo `scenario-write` |
| **需求 ↔ scenario 雙向對應** | 本 repo `trace-check` |
| **task 的 DoD 綁定 scenario** | 本 repo `trace-bind` |
| **scenario 被竄改 / 偷加 / 缺步驟實作** | 本 repo `trace-verify` |
| **測試強度量化** | 本 repo `mutation-gate` |
| **人工驗收** | 本 repo `manual-qa` |

## 安裝

沒有安裝腳本，手動接線：

```bash
# skills
cp -r skills/* /path/to/project/.claude/skills/

# steering（複製後由該專案自行維護，不要 symlink 回來）
cp steering-custom/*.md /path/to/project/.kiro/steering/
```

steering 三份：`gherkin-guidelines.md`（`scenario-write` 指名）、
`quality-gates.md` 與 `toolchain.md`（`mutation-gate` 指名）。
驗收紀律本身不進 steering，
它由腳本與結構保證——說明見
[docs/acceptance-discipline.md](docs/acceptance-discipline.md)。

> ⚠️ `.kiro/steering/` **不會**被 Claude Code 自動載入——那是 Kiro IDE 靠
> front-matter `inclusion: always` 做的事。在 Claude Code 底下只有 `CLAUDE.md`
> 自動進 context。所以放進 steering 的東西必須有 skill 明確指名，
> 否則寫了沒人讀。見 [ADR-0011](docs/decisions/0011-acceptance-discipline-to-docs.md)。

不用 symlink 是刻意的：steering 是**專案記憶**，一個專案的門檻調整
不該波及其他專案。

## 文件

- [docs/workflow.md](docs/workflow.md) — 一個 feature 從頭到尾的完整路徑
- [docs/example-walkthrough.md](docs/example-walkthrough.md) — 同一條需求走完五道閘門的實例
- [docs/acceptance-discipline.md](docs/acceptance-discipline.md) — 七條紀律各由什麼機制保證，以及還有哪幾處裸露
- [docs/decisions/](docs/decisions/) — 設計取捨的紀錄

## 狀態

🚧 骨架階段。

| 元件 | 狀態 |
|---|---|
| `scenario-write/scripts/scn-alloc.sh` | ✅ 可用 |
| `scenario-write/SKILL.md` | ✅ 可用 |
| `grill-capture/SKILL.md` | ✅ 可用 |
| `trace-check/scripts/trace.sh` — `check` | ✅ 可用（六種缺口偵測，`--include-design` 走 REQ） |
| `trace-check/scripts/trace.sh` — `bind` | ✅ 可用（`--dry-run`、冪等） |
| `trace-check/scripts/trace.sh` — `verify` | ✅ 可用（`scenarios.lock` 雜湊比對 + 步驟檢查） |

| `mutation-gate/scripts/mutate.sh` | ✅ 可用（diff scope 自算，Python/mutmut 實測） |

建議實作順序（不要一次全開）：

1. `grill-capture` + `scenario-write` — 跑 2–3 個 feature，確認 agent 真的把 scenario 當測試寫
2. `trace-check` → `trace-bind` → `trace-verify` — 追溯鏈完整跑一輪
3. `mutation-gate` — 門檻從 60% 開始往上調
4. `manual-qa`

`.kiro/scn-highwater` 與各 feature 的 `scenarios.lock` **要進版控**。
前者保證 `@SCN` 永不重用，後者是 `trace-verify` 的基準線。
