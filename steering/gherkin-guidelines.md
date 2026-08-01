# Gherkin 準則

<!-- TODO: 貼上 AutomationPanda/gherkin-guidelines-for-ai 的 gherkin-guidelines.md
     來源：github.com/AutomationPanda/gherkin-guidelines-for-ai
     那份是設計來直接當 AI context file 用的，整份貼進來即可。 -->

## 本專案追加約定

### Scenario ID

每個 scenario 必須以 tag 標註 ID 與其對應的 EARS 需求：

```gherkin
@SCN-003 @EARS-003
Scenario: 匯出超過一萬筆時分頁處理
  Given ...
  When ...
  Then ...
```

trace skill 依賴這個 tag 格式解析對應關係。格式錯了追溯就斷了。

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
