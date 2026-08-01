# Constitution

> 單一治理真相來源。不要在專案內另外保留 Spec Kit 的 constitution
> 或其他來源的規則檔——多份治理文件會讓 agent 不知道聽誰的。

## 驗收紀律

1. 每一條 EARS 驗收條件**至少**對應一個 Gherkin scenario。
   沒有對應的需求視為未完成，不得進入 design 階段。
2. Gherkin 是可執行的測試，不是文件。`.feature` 檔若沒有對應的 step
   definition，等同不存在。
3. 實作採 acceptance-first：先跑 scenario 確認為紅，才開始寫實作。
   紅燈的判定機制沿用 cc-sdd `kiro-impl` 的 Feature Flag Protocol，
   但**紅燈的對象是綁定的 Gherkin scenario**，不是 implementer 自選的單元測試。
4. task 的完成定義是「綁定的 scenario 由紅轉綠」。
   cc-sdd 的 `kiro-review` APPROVED 與 `kiro-verify-completion` 是必要條件，
   不是充分條件——它們驗的是 task 自己的測試，不驗 scenario。

## 測試強度

5. mutation score 只計算本次 diff scope，不計全域。
6. 門檻見 quality-gates.md。未達門檻不得進入 manual-qa。
7. 存活的 mutant 必須逐一說明：是測試不夠嚴，還是該 mutant 等價。

## 程式碼

<!-- TODO: 依 SwarmForge 的 Clean Code constitution 補齊。
     建議涵蓋：函式長度、命名、相依方向、重複、註解政策。
     參考 github.com/unclebob/swarm-forge 各 runnable branch 的 constitution 條文。 -->

## 不可自我圓場

8. 閘門 skill 的判定結果來自腳本輸出。agent 負責轉述，
   **不得自行判讀通過與否**，不得為未通過的結果找理由。

   一般性的「不實完成宣稱」防護沿用 cc-sdd 的 `kiro-verify-completion`
   （含其 Common Rationalizations 對照表），本條不重述。
   本條額外要求的是：**`trace-*` 與 `mutation-gate` 的 exit code 不可被詮釋**。
