# ADR-0008: `.feature` 放 spec 樹，step definition 放測試目錄

狀態：已決定

## 脈絡

`.feature` 檔要放哪，原本掛在 `gherkin-guidelines.md` 的 TODO，
並擋著 `trace.sh` 的 `FEATURE_GLOB`。

原始的二選一是：

- A. `.kiro/specs/<feature>/features/` —— 規格與測試同處，trace 掃描單純
- B. 專案既有測試目錄 —— 測試工具零設定，CI 天然涵蓋

這個框架把它當成配置便利性問題。實際上它決定三件更重要的事：
step definition 放哪、生命週期是否匹配、以及**檔案會不會落在 task boundary 內**。

## 決策

拆開：

```
.kiro/specs/<feature>/features/*.feature   ← 驗收契約，實作期唯讀
tests/steps/…（依框架慣例）                 ← step definition，正常實作產物
```

`FEATURE_GLOB="$SPEC_PATH/features"`。step definition 不在 `trace.sh` 的掃描範圍。

## 理由

### 主因：免費換到第二道防線

cc-sdd 的 task 帶 `_Boundary:_` 標註。`kiro-review` 明確會 reject
`Boundary Violations`，`kiro-validate-impl` 還有 G.5 Boundary Audit。

`.feature` 放在 spec 樹 → 落在**所有 task boundary 之外** → implementer
去動它本身就是 boundary violation，cc-sdd 自己的兩道閘門會抓。

放進 `tests/` 就沒有這層——那是 implementer 的正常工作範圍，它想改就改。

閘門 3 因此從單點防守變成雙重：`trace-verify` 抓「哪條驗收條件被放寬」，
cc-sdd 抓「你不該碰那個檔案」。

### 次因：生命週期

| | spec 目錄 | 測試 |
|---|---|---|
| 範圍 | 單一 feature | 累積 |
| 完成後 | 凍結，是當時意圖的快照 | 永遠活著，跟著重構 |

`.feature` 是**契約**，屬於前者：它記錄「這個 feature 當時同意了什麼」。
step definition 是**實作**，屬於後者：它要跟著程式碼演進、去重、重構。

兩者放同一處必然有一邊生命週期錯位。拆開就沒有這個問題。

### 為什麼不是把 step def 也放 spec 樹

那等於在規格目錄裡放可執行原始碼。spec 目錄是規格產物，不是 source tree。
而且 step def 需要被 implementer 撰寫——它不能唯讀。

## 代價

**三個生態要繞：**

| 框架 | 問題 |
|---|---|
| behave | 認 `features/` 底下要有 `steps/`，step def 必須貼著 features |
| Reqnroll / SpecFlow | `.feature` 要是專案項目並跑 code-behind 產生器 |
| cucumber-ruby | 可設定，但慣例強推 `features/step_definitions/` |

**這是明知的取捨。** 曾評估過改放測試目錄以求全語言零設定，
但那會丟掉 boundary 保護——而 boundary 保護正是閘門 3 的第二道崗。
決定保留保護，接受這三個生態要多繞。

cucumber-js / pytest-bdd / Cucumber-JVM / godog 皆可乾淨分家，
只需一行路徑設定。

**另一個代價：** `.feature` 在 spec 樹，測試框架與 CI 都要多指一個路徑。
慣例寫在 `gherkin-guidelines.md` 的「測試框架設定」段。

## 未解決

`trace-verify` 目前的做法是「比對 git diff 看 `.feature` 在實作階段有無變更」，
這需要一個基準線 commit（bind 是哪一次），rebase 或 squash 之後會失準。

評估過的替代方案是 `scenarios.lock`：`trace-bind` 產生，記錄每條 scenario
的 ID 與內容雜湊，`trace-verify` 重算比對。優點是不依賴 git 歷史、
訊號更精確（直接得到「SCN-042 內容變了」）。

本 ADR 不納入——先讓 boundary 保護跑一輪，看 git diff 的基準線問題
實際上有多痛再決定。
