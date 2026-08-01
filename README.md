# sdd-toolkit

在 cc-sdd 之上補齊「驗證與追溯」層的 skill 集合。

## 這是什麼

cc-sdd 把需求變成文件的部分做得很好，但幾乎不驗證文件是否變成了正確的程式。
這個 repo 補的就是那一段：讓 Gherkin 是可執行的驗收，而不是文件裝飾。

設計精神取自 Uncle Bob 的 SwarmForge——嚴格測試、機器裁決、驗收與實作分離——
但以**單 agent** 實現，不引入 tmux / worktree 的多 agent 協調成本。

## 組成

| 層 | 來源 | 說明 |
|---|---|---|
| 主體流程 | cc-sdd | steering / discovery / requirements / design / tasks / impl |
| 意圖對齊 | grill-me (mattpocock) | 在 requirements 之前反覆盤問，產出 grill-notes.md |
| Gherkin 品質 | gherkin-guidelines-for-ai | 掛進 steering |
| ~~需求品質~~ | ~~ears-checklist~~ | ⚠️ 與 cc-sdd 內建的 `requirements-review-gate` 重複，待廢除 |
| **追溯** | trace-check / trace-bind / ~~trace-verify~~ | 本 repo（verify 需縮減，見下） |
| **測試強度** | mutation-gate | 本 repo |
| **人工驗收** | manual-qa | 本 repo |

粗體是這個 repo 真正原創的部分，其餘是接線。

> 對 `cc-sdd@3.0.2` 做過完整重疊稽核：Gherkin、mutation testing、人工驗收
> 三軸在 cc-sdd 中**零命中**，是真正的增量；但 `ears-checklist` 完全重複，
> `trace-verify` 與 `kiro-validate-impl` 大幅重疊。
> 見 [ADR-0005](docs/decisions/0005-cc-sdd-overlap-audit.md)。

## 為什麼不自建協調層

SwarmForge 用 hardener 和 QA 兩個獨立 agent 做驗收。本 toolkit 不自建這層，
因為兩個來源已經覆蓋：

- **獨立 agent** —— cc-sdd 的 `kiro-impl` autonomous 模式已內建。每個 task
  一個 fresh implementer、一個獨立 reviewer（自己跑 `git diff`，不信 implementer
  的回報），失敗時再派 fresh debugger
- **獨立機器裁決** —— mutation score 與 Gherkin 綠燈都不需要第二個 agent 判定

代價是 manual-qa 那一步必須由人執行，不能省。cc-sdd 的 `MANUAL_VERIFY_REQUIRED`
只是「機器測不了」的逃生口，不是驗收程序。

## 安裝

```bash
./install.sh /path/to/your/project
```

會把 `skills/` symlink 進目標專案的 `.claude/skills/`，
`steering/` symlink 進 `.kiro/steering/`。

symlink 而非複製：改一次，所有專案生效。

## 文件

- [docs/workflow.md](docs/workflow.md) — 一個 feature 從頭到尾的完整路徑
- [docs/decisions/](docs/decisions/) — 設計取捨的紀錄

## 狀態

🚧 骨架階段。skill 內容為待填模板，見各 SKILL.md 的 TODO。

建議實作順序（不要一次全開）：

1. Gherkin 層 + trace-check — 跑 2–3 個 feature，確認 agent 真的把 scenario 當測試寫
2. mutation-gate — 門檻從 60% 開始往上調
3. trace-verify + manual-qa
