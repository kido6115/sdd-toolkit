# Gherkin Guidelines

[Purpose: scenario 的寫法與 ID 慣例——trace-* 依賴此格式解析追溯關係]

<!-- TODO: 貼上 AutomationPanda/gherkin-guidelines-for-ai 的 gherkin-guidelines.md
     來源：github.com/AutomationPanda/gherkin-guidelines-for-ai
     那份是設計來直接當 AI context file 用的，整份貼進來即可。 -->

## 本專案追加約定

### Scenario ID

每個 scenario 必須標註兩種 tag：自己的 ID，以及它驗證的需求。

```gherkin
@SCN-042 @REQ-3.1
Scenario: 匯出超過一萬筆時分頁處理
  Given ...
  When ...
  Then ...
```

`trace-*` 依賴這個格式解析對應關係。格式錯了追溯就斷了。

#### `@REQ-N.M` —— 直接用 cc-sdd 的編號

`N.M` 是 `requirements.md` 的驗收條件編號，**不要另外發明別名**。

cc-sdd 在四個地方強制數字 ID：`requirements-review-gate`（退回非數字標題）、
`design-principles`（「must reference the same canonical numeric ID」）、
`kiro-impl`（「do NOT invent `REQ-*` aliases」）、`implementer-prompt`
（傳給 implementer 的是 source numbering）。

自建 `EARS-003` 這類別名會讓追溯出現兩份地圖，且 `trace.sh` 在真實的
`requirements.md` 上會零命中。

#### `@SCN-NNN` —— 流水號，不含語意

三條規則：

1. **不編碼任何語意。** 不含需求編號、不含模組名、不含日期
2. **單調遞增，永不重用。** scenario 刪除後號碼作廢——git 歷史、
   `qa-results.md`、舊 `tasks.md` 裡都還有引用，重用會讓歷史指向錯的東西
3. **序號與 REQ 無關。** `SCN-042 → REQ-2.1`、`SCN-043 → REQ-7.3` 完全正常

**為什麼不從 REQ 衍生（例如 `@SCN-3.1a`）：** `N.M` 是位置性的，
`requirements.md` 插一節就會位移。衍生的 SCN ID 得跟著改，而它們散在測試檔裡。

更嚴重的是，`trace-verify` 靠 tag 判斷「這是同一條 scenario」。
為了同步編號去改 tag，在它眼裡等同 scenario 被抽換——你會自己製造竄改訊號，
而且從此變成日常噪音，真的竄改就藏在裡面了。

**ID 的作用是讓身分在內容改變時存活。** 一旦 ID 帶語意，語意變它就得變，
這個作用就沒了。

#### 一對多與多對一

一條需求通常對多條 scenario（正常路徑、邊界、失敗路徑）：

```gherkin
@SCN-042 @REQ-3.1            # 正常路徑
@SCN-043 @REQ-3.1            # 邊界：剛好 10000 筆
@SCN-044 @REQ-3.1 @REQ-5.2   # 失敗路徑，同時驗到權限需求
```

流水號天然支援兩個方向。要在中間插一條就用下一個號，不需要 `3.1b2` 這種東西。

#### 代價

`SCN-042` 看不出在講什麼。這是**報告呈現**的問題，不是 ID 設計問題——
`trace-check` 輸出時要一併印 scenario 標題。

不要為了讓 ID 好讀而把語意塞回去。那是所有「聰明編號」腐爛的起點。

### 檔案位置

<!-- TODO: 二選一，決定後刪掉另一個

  A. .kiro/specs/<feature>/features/*.feature
     優點：規格與測試同處，trace 掃描路徑單純
     缺點：與既有測試目錄分離，CI 設定要多指一個路徑

  B. 專案既有測試目錄（tests/features/ 等）
     優點：測試工具零設定，CI 天然涵蓋
     缺點：trace 需跨目錄比對，且 feature 與規格分離
-->

### 宣告式而非命令式

寫使用者意圖，不寫 UI 點擊步驟。
`When 使用者匯出訂單` 而非 `When 使用者點擊右上角的匯出按鈕`。
