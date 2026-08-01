---
name: trace-bind
description: 把 tasks.md 中的每個子任務綁定到它要點亮的 Gherkin scenario，並寫入 _DoD: SCN-xxx 由紅轉綠_。在 kiro-spec-tasks 之後執行。這是寫入操作，會修改 tasks.md。
---

## 先 dry-run，取得同意再寫

```
${CLAUDE_SKILL_DIR}/../trace-check/scripts/trace.sh bind --dry-run $ARGUMENTS
```

呈現綁定計畫給使用者，**取得同意後**才跑不帶 `--dry-run` 的版本。

`--dry-run` 保證不碰檔案。

## 映射是機械的，不是語意判斷

cc-sdd 的每個子任務都帶 `_Requirements: X.X_`（`tasks-generation.md`
的 Checkbox Format）。綁定就是跟 scenario 的 `@REQ` 取交集：

```
task 2.1  _Requirements: 3.1, 3.2_
          ∩  SCN-042 @REQ-3.1
          ∩  SCN-051 @REQ-3.2
          →  _DoD: SCN-042, SCN-051 由紅轉綠_
```

所以本 skill **不做判斷**，跟其餘 trace skill 一樣只轉述腳本輸出。

寫入位置：每個子任務的 `_Requirements:_` 行下方，縮排比照。
**冪等**——既有的 `_DoD:_` 行會被重算後取代，重跑不會累積。
scenario 增修之後重跑一次即可同步。

只有 `X.Y` 編號的子任務會被綁定。`- [ ] 4.` 這種主任務是分組標頭，
不是執行單位，跳過。

## 這一步是整套的樞紐

`kiro-impl` 的 Feature Flag Protocol 本來就會做 RED→GREEN，
但紅燈的對象是 implementer 自己挑的測試——它自己寫的、自己知道能過的。

綁定之後紅燈對象變成你核准的 scenario，實作者不能挑。
**差別在紅燈的定義權在誰手上。**

## 兩種缺口

exit code：`0` 全部綁定成功、`1` 有缺口、`2` 執行錯誤。

| JSON 欄位 | 意義 | 通常代表 |
|---|---|---|
| `task_without_requirements` | 子任務沒有 `_Requirements:_` 標註 | cc-sdd 該補；或這個 task 不該存在 |
| `task_without_scenario` | 有需求，但沒有 scenario 涵蓋那些需求 | **需求有缺口**，退回 `/scenario-write` |

第二種要特別看。它表示有人要實作一件**沒有驗收條件**的事。

`trace-check` 問的是「需求有沒有被測到」，這一關問的是
「要動工的東西有沒有被測到」——角度不同，會抓到不一樣的洞。

不要為了讓數字好看而放過任何一種。
