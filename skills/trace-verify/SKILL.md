---
name: trace-verify
description: 實作完成後比對 scenarios.lock，驗證 Gherkin scenario 是否在過程中被竄改、刪除、偷加，以及步驟是否都有 step definition。在 kiro-validate-impl 回 GO 之後、mutation-gate 之前執行。
---

執行 `${CLAUDE_SKILL_DIR}/../trace-check/scripts/trace.sh verify $ARGUMENTS`，
把輸出的 JSON 整理成人類可讀的形式呈現。

**不要自行判讀通過與否。** 判定來自 exit code：`0` 通過、`1` 有發現、`2` 執行錯誤。

## 前置

**先跑 `/kiro-validate-impl`，它回 GO 才跑這一步。**

需求涵蓋缺口、設計漂移、架構偏離、跨 task 整合、boundary 稽核全部由
`kiro-validate-impl` 負責。本 skill **不重複檢查**——兩套判定並存只會
產出互相矛盾的報告。見 [ADR-0005](../../docs/decisions/0005-cc-sdd-overlap-audit.md)。

## 基準線來自 lock，不是 git

`scenarios.lock` 由 `/trace-bind` 產生，記錄綁定當下每條 scenario 的內容雜湊。

不用 git diff 是因為它需要一個「bind 是哪個 commit」的基準線，
而 rebase 或 squash 之後那個基準線就失準了。雜湊不受歷史重寫影響。

雜湊前會正規化：逐行去除前後空白、丟棄空行。**重排版不會誤報，內容變動才會。**

## 六種發現

| JSON 欄位 | 意義 |
|---|---|
| `scenario_modified` | **最重要**。內容在 bind 之後被改，尤其是斷言被放寬 |
| `scenario_removed` | 整條不見了 |
| `scenario_added_after_bind` | 偷加了沒經過核准的 scenario |
| `tag_changed` | `@REQ` / `@BC` 被增刪，追溯鏈變動 |
| `binding_broken` | `tasks.md` 的 `_Scenarios:` 引用了已不存在的 SCN |
| `undefined_steps` | 有 scenario 但沒人實作步驟——等同不存在 |

### `scenario_modified` 要人來判斷

報告會區分兩種：

```
SCN-042「分頁匯出」內容變更
SCN-042 內容與標題皆變更：「分頁匯出」→「匯出大量訂單」
```

第二種特別值得看。**改標題是規避偵測最常見的方式**——若 scenario 的身分
是標題，這在機器眼裡會變成「一條消失、一條出現」。`@SCN-NNN` 讓身分在
內容改變後仍然存活，所以抓得到。見 [ADR-0007](../../docs/decisions/0007-scenario-id-convention.md)。

逐條呈現給使用者確認：**這是合理的需求演進，還是為了讓測試過關而放水？**

- 合理演進 → 回頭改 requirements，重跑 `/trace-check` 與 `/trace-bind`（lock 會更新）
- 放水 → 退回實作

`scenario_added_after_bind` 同理：若是合理的需求演進，重跑 `/trace-bind` 更新 lock。

## 兩層防守

`.feature` 住在 spec 樹，落在所有 task 的 `_Boundary:_` 之外，
所以 implementer 一動它，`kiro-review` 就會先報 Boundary Violation。

那句說的是「你不該碰那個檔案」。本 skill 補的是**「你把哪條驗收條件放寬了」**。
前者是權限問題，後者是語意問題——`kiro-review` 只知道檔案被動了，
不知道方向是收緊還是放寬。

## exit 2 的常見原因

- `scenarios.lock` 不存在 → 先跑 `/trace-bind`
- `toolchain.md` 未定義 `FEATURE_DRYRUN_CMD` → **缺席不等於豁免**。
  若本專案的框架沒有這個能力，明確設為 `-` 才算豁免

> ⚠️ step definition 的檢查**一律解析輸出，不看 exit code**。
> pytest 的 `--generate-missing` 在「有缺步驟」時回 `0`、「全部實作完」
> 時回 `3`——是反的。細節見 `.kiro/steering/toolchain.md`。
