---
name: trace-bind
description: 把 tasks.md 中的每個 task 綁定到它要點亮的 Gherkin scenario，並將完成定義改寫為「指定 scenario 由紅轉綠」。在 kiro-spec-tasks 之後執行。這是寫入操作，會修改 tasks.md。
---

執行 `${CLAUDE_SKILL_DIR}/../trace-check/scripts/trace.sh bind $ARGUMENTS`。

這是**寫入**操作：
1. 讀取 tasks.md 與 features/*.feature
2. 為每個 task 標註它負責的 scenario ID
3. 將 task 的 DoD 改寫為「SCN-xxx, SCN-yyy 由紅轉綠」

修改前先確認使用者同意。修改後呈現綁定結果供核對。

未能綁定任何 scenario 的 task 要特別標出——那通常代表
該 task 不該存在，或需求有缺口。
