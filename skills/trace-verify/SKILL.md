---
name: trace-verify
description: 實作完成後驗證 Gherkin scenario 是否在過程中被竄改或失去綁定。在 kiro-validate-impl 回 GO 之後、mutation-gate 之前執行。
---

執行 `${CLAUDE_SKILL_DIR}/../trace-check/scripts/trace.sh verify $ARGUMENTS`。

## 前置

**先跑 `/kiro-validate-impl`，它回 GO 才跑這一步。**

需求涵蓋缺口、設計漂移、架構偏離、跨 task 整合、boundary 稽核，
全部由 `kiro-validate-impl` 負責。本 skill 不重複檢查——兩套判定並存
只會產出互相矛盾的報告。見 [ADR-0005](../../docs/decisions/0005-cc-sdd-overlap-audit.md)。

## 職責

只驗 cc-sdd 結構上沒有的那一層。cc-sdd 的追溯單位是 requirements.md 的
章節編號，它沒有 scenario 這個概念，因此以下四項它一律抓不到：

- **scenario 內容在 bind 之後被修改**——尤其是斷言被放寬
- `.feature` 檔的 tag（`@SCN-xxx` `@EARS-xxx`）被移除，追溯鏈斷掉
- 已綁定的 scenario 在 tasks.md 中失去對應
- scenario 有 tag 但沒有對應的 step definition（等同不存在）

第一項最重要。比對 `git diff`，若 `.feature` 檔在實作階段有變更，
逐條列出並要求使用者確認那是合理的需求演進，而非為了讓測試過關而放水。

不要自行判讀通過與否。
