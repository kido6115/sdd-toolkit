# ADR-0011: 驗收紀律移出 steering，改為 docs 的設計說明

狀態：已決定

## 脈絡

ADR-0005 指出 `.kiro/steering/` 在 Claude Code 底下沒有自動載入機制
（那是 Kiro IDE 靠 front-matter `inclusion: always` 做的事）。
steering 檔案要被讀到，唯一的路徑是某個會被觸發的 skill 在內文明確指名它。

當時三份檔案裡只有一份有指名者。後續兩次改動各解掉一份：

| 檔案 | 指名者 |
|---|---|
| `quality-gates.md` | `mutation-gate/SKILL.md:19` |
| `gherkin-guidelines.md` | `scenario-write/SKILL.md:25`（ADR-0009 新增 `scenario-write` 時順帶接上） |
| `acceptance-discipline.md` | 無 |

剩下那份要補指名者很便宜——在 `trace-bind` / `trace-verify` 的 SKILL.md
加一行就好。但先逐條檢查了它到底約束了什麼。

## 逐條稽核

> 本表是**決策當時的快照**，不隨實作更新——`verify` 與 `mutate.sh` 其後已實作
> （ADR-0012），綁定的欄位名也已從 `_DoD:` 改為驗收條件 bullet + `_Scenarios:`
> （ADR-0013）。當前狀態見 [docs/acceptance-discipline.md](../acceptance-discipline.md)。
>
> 本決策的論點不受影響：重點是「這些條文都不靠 steering 載入生效」，
> 而不是各由哪支腳本保證。

| 條 | 實際由誰保證 |
|---|---|
| 1. 每條驗收條件至少一個 scenario | `trace.sh check` 的差集，exit 1 |
| 2. `.feature` 沒 step definition 等同不存在 | `trace.sh verify`（未實作） |
| 3. `.feature` 實作期唯讀 | **結構**——檔案落在所有 `_Boundary:_` 之外，`kiro-review` 判 violation |
| 4. 紅燈對象必須是綁定的 scenario | `trace-bind` 寫入的 `_DoD:` 行 |
| 5. task 完成定義 = scenario 由紅轉綠 | 同上 |
| 6. mutation 只計 diff scope | `mutation-gate/SKILL.md` 自己就寫了 |
| 7. exit code 不可被詮釋 | 每個 `trace-*` SKILL.md 自己都寫了 |

**沒有一條是「非得靠 steering 載入才能生效」的。**

## 決策

`steering-custom/acceptance-discipline.md` → `docs/acceptance-discipline.md`，
定位改為**寫給人看的設計說明**：每條紀律由什麼機制保證、若失效會怎樣、
以及目前還有哪幾處裸露。

`.kiro/steering/` 只保留 `gherkin-guidelines.md` 與 `quality-gates.md`。

## 理由

補指名者（選項 B）會製造**第二份可能不同步的說法**，而且那份說法會進
agent 的 context。腳本改了行為，散文不會跟著改——屆時 agent 讀到的是舊的。

這正是 ADR-0005 已經處理過一次的模式：constitution 的條 3/4/8 重述了
`kiro-impl` / `kiro-review` / `kiro-verify-completion` 已經在做的事，
當時的處置是改成指向那些機制而非重述。這次是同一個判斷再往前一步——
連指向都不必留在 steering，因為指向的對象就在 skill 自己的內文裡。

ADR-0006 已確立「單一治理真相來源應該是 cc-sdd 的 `.kiro/steering/`，
本 repo 只提供它缺的那幾片」。逐條看下來，**缺的那幾片是腳本，不是條文。**

## 由此得到的判準

**steering 只放「有 skill 指名、且內容不重複腳本行為」的東西。**

- `gherkin-guidelines.md` —— `scenario-write` 要照它寫 scenario，
  `trace.sh` 的 parser 也依賴它的 tag 單行約束。內容是**慣例**，腳本無法自證
- `quality-gates.md` —— `mutation-gate` 要讀門檻數字。內容是**參數**，本來就該外置

兩份都通過。條文式的紀律沒有通過。

## 代價

- 移出 steering 後，`acceptance-discipline.md` 的 Code Quality TODO
  變成寫了 agent 也讀不到。該段已加註：真要約束程式碼風格應寫進
  cc-sdd 產出的 `tech.md` / `structure.md`（那兩份有 10 個 skill 在讀）
- 少了一份「一次讀完所有紀律」的 agent context。
  接受這個代價——那份 context 的價值建立在它與腳本行為一致，
  而那個一致性沒有任何機制維護

## 相關

- [#1](https://github.com/kido6115/sdd-toolkit/issues/1) 本決策的來源
- ADR-0005（首次指出載入問題）、ADR-0006（steering 定位）、ADR-0009（`scenario-write`）
