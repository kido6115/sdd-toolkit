---
name: ears-checklist
description: 驗證 EARS 需求本身的完整性、清晰度與一致性——像是「需求的單元測試」。在 kiro-spec-requirements 產出 requirements.md 之後、trace-check 之前執行。
---

<!-- TODO: 抄自 GitHub Spec Kit 的 speckit.checklist prompt。
     來源：github.com/github/spec-kit 的 templates 目錄
     （不需要真的 specify init，直接讀 repo 即可）

     抄過來後需修改：
     1. 檔案路徑 → .kiro/specs/<feature>/requirements.md
     2. 輸出格式 → 結構化缺口清單，不要散文
     3. 移除與 trace-check 重疊的對應關係檢查（那是 trace 的職責）

     見 docs/decisions/0003-fold-analyze-into-trace.md -->

檢查 requirements.md 中每一條 EARS 敘述：

- 語法是否符合 EARS 五種模式之一
- 觸發條件是否明確且可判定
- 系統回應是否可觀察、可測量
- 是否存在互相矛盾的需求
- 是否有隱含假設未被寫出

這一層**只驗需求本身的品質**，不驗它與 Gherkin/design/task 的對應——
那是 trace-check 的職責。
