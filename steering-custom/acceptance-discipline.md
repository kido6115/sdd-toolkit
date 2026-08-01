# Acceptance Discipline

[Purpose: 定義本專案「做完」的判準——Gherkin 是可執行的驗收，不是文件]

## Philosophy

- 驗收條件的權威來自**你核准的 scenario**，不是實作者自選的測試
- 追溯沒有「大致上」，缺一條就是缺口
- 閘門的判定來自腳本 exit code，不來自敘述

## 與 cc-sdd 的分工

cc-sdd 已負責的，本檔不重述：

| 事項 | 由誰保證 |
|---|---|
| RED → GREEN 的機制 | `kiro-impl` 的 Feature Flag Protocol |
| task 的獨立審查 | `kiro-review`（自跑 git diff，不信 implementer 回報） |
| 不實的完成宣稱 | `kiro-verify-completion` |
| 需求涵蓋、設計漂移、跨 task 整合 | `kiro-validate-impl` |

本檔只補 cc-sdd 結構上沒有的那一層。

## Rules

1. `requirements.md` 的每一條驗收條件（`N.M`）**至少**對應一個
   Gherkin scenario，以 `@REQ-N.M` 標註。
   沒有對應的需求視為未完成，不得進入 design 階段。

2. Gherkin 是可執行的測試，不是文件。`.feature` 檔若沒有對應的
   step definition，等同不存在。

3. **`.feature` 在實作期唯讀。** 它住在 `.kiro/specs/<feature>/features/`，
   落在所有 task 的 `_Boundary:_` 之外——implementer 修改它即為
   boundary violation。step definition 是實作產物，放專案測試目錄，正常撰寫。

   要改 scenario，退回 requirements 走正式流程，不要在實作中就地改。

4. `kiro-impl` 的紅燈對象**必須包含**該 task 綁定的 scenario。
   cc-sdd 預設讓 implementer 自選測試——那是它自己寫的、自己知道能過的測試。
   綁定的 scenario 是你核准的，實作者不能挑。

5. task 的完成定義是「綁定的 scenario 由紅轉綠」。
   `kiro-review` 的 APPROVED 是必要條件，不是充分條件。

6. mutation score 只計算本次 diff scope，不計全域。
   存活的 mutant 必須逐一說明：測試不夠嚴，還是該 mutant 等價。
   門檻見 `quality-gates.md`，未達門檻不得進入 manual-qa。

7. `trace-*` 與 `mutation-gate` 的 exit code 不可被詮釋。
   agent 負責轉述，不得自行判讀通過與否，不得為未通過的結果找理由。

## Code Quality

<!-- TODO: 依 SwarmForge 的 Clean Code constitution 補齊。
     建議涵蓋：函式長度、命名、相依方向、重複、註解政策。
     參考 github.com/unclebob/swarm-forge 各 runnable branch 的 constitution 條文。

     補之前先查 cc-sdd 產出的 tech.md / structure.md 是否已涵蓋——
     重複的規則會讓 agent 不知道聽誰的。 -->
