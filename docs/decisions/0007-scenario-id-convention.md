# ADR-0007: scenario 用不透明流水號，需求直接引用 cc-sdd 編號

狀態：已決定

## 脈絡

原本的 tag 慣例是 `@SCN-003 @EARS-003`，兩個 ID 都是本 repo 自訂。

`EARS-003` 與 cc-sdd 正面衝突。cc-sdd 在四處強制數字 ID：

| 出處 | 規定 |
|---|---|
| `requirements-review-gate.md:29` | Requirement headings must use numeric IDs only |
| `design-principles.md:90-91` | 用 `N.M` 格式；every traceability row must reference the **same canonical** numeric ID |
| `kiro-impl/SKILL.md` | do **NOT** invent `REQ-*` aliases |
| `implementer-prompt.md:9` | implementer 收到的是 source numbering（`1.2`, `3.1`） |

後果不只是風格不一致：`trace.sh` 的 `EARS_ID_PATTERN='EARS-[0-9]{3}'`
在真實的 `requirements.md` 上會**零命中**，閘門 1 永遠 exit 1。

## 決策

```gherkin
@SCN-042 @REQ-3.1
```

- **`@REQ-N.M`** —— 直接引用 cc-sdd 的驗收條件編號，不另設別名
- **`@SCN-NNN`** —— 流水號，不含語意，單調遞增，永不重用

兩者無序號關聯。比對為集合運算，順序不參與。

## 理由

### 衝突只在一半

| 軸 | cc-sdd 有主張嗎 | 衝突 |
|---|---|---|
| scenario 怎麼稱呼 | 沒有。cc-sdd 結構上無 scenario 概念 | 否 |
| 需求怎麼稱呼 | 有，四處各說一次，且有閘門強制 | 是 |

而 `EARS-003` 是本 repo 發明的——EARS 是語法（When / If / While / Where /
shall），不規定 ID 體系。這一半沒有標準可以拿來對抗 cc-sdd，只是慣性。

不對稱還有一層：cc-sdd 的規則已被它自己的閘門強制執行，
本 repo 的規則目前沒有任何東西在強制（`trace.sh` 仍是 stub）。

**在需求那一軸讓步，在 scenario 那一軸保留。**

### 為什麼 scenario 需要自己的 ID

光是「可執行」不需要 ID——多數團隊靠檔案路徑 + scenario 標題就夠了。

真正逼出 ID 的是**閘門 3**。要偵測這種竄改：

```diff
- Scenario: 匯出超過一萬筆時分頁處理
-   Then 產生 3 個檔案，前兩個各 10000 筆
+ Scenario: 匯出大量訂單
+   Then 匯出完成
```

若身分是標題，這在機器眼裡是「一條消失、一條出現」，不是「同一條被放寬」。
agent 順手改個標題，竄改偵測就失效——而它本來就在改那個檔案。

**ID 的作用是讓身分在內容改變時存活。** 這是 `trace-verify` 的前提。

反過來說，需求文件不會被 implementer 修改，沒有這個需求，
所以它不需要自己的符號 ID。

### 為什麼 SCN 不從 REQ 衍生

`@SCN-3.1a` 這種寫法會把上述理由整個抵銷：`N.M` 是位置性的，
`requirements.md` 插一節就位移，衍生的 SCN ID 得跟著改，而它們散在測試檔裡。

更嚴重的是，為了同步編號去改 tag，在 `trace-verify` 眼裡等同 scenario 被抽換。
**你會自己製造竄改訊號**，而且從此變成日常噪音，真的竄改就藏在裡面。

一旦 ID 帶語意，語意變它就得變，這個作用就沒了。

### 附帶好處：一對多

```gherkin
@SCN-042 @REQ-3.1
Scenario: 匯出超過一萬筆時分頁處理

@SCN-043 @REQ-3.1
Scenario: 匯出剛好一萬筆時不分頁

@SCN-044 @REQ-3.1 @REQ-5.2
Scenario: 匯出時使用者被降權
```

三條分別是正常路徑、邊界、失敗路徑。標題自己說清楚，不靠註解——
上游 `SHOULD avoid comments; the scenario text should be self-explanatory`。

一條需求對多條 scenario 是常態。從 REQ 衍生要處理 `3.1a/3.1b`，
中間插一條就得寫 `3.1b2`。流水號沒這問題。

## 代價

**`N.M` 是位置性的，`requirements.md` 重新編號會讓 `@REQ-` 失效。**

不需要新機制承擔——閘門 1 就會擋。重新編號後跑一次 `trace-check`，
失效的對應會全部報成缺口。cc-sdd 自己也有這問題，它靠 `kiro-validate-impl` 抓。

**`SCN-042` 看不出在講什麼。**

這是報告呈現的問題，不是 ID 設計問題。`trace-check` 輸出時要一併印 scenario
標題。不要為了讓 ID 好讀而把語意塞回去——那是所有「聰明編號」腐爛的起點。

## 連動修改

- `steering-custom/gherkin-guidelines.md` — tag 約定改寫，加入三條規則
- `skills/trace-check/scripts/trace.sh` — `EARS_ID_PATTERN` → `REQ_ID_PATTERN`，
  抽取函式拆為 `extract_req_ids` / `extract_scn_ids` / `extract_req_refs`
- `skills/trace-verify/SKILL.md` — 補充 tag 作為歸因錨點的說明
- `steering-custom/quality-gates.md` — 追溯表述改為 REQ
- `docs/example-walkthrough.md`、`docs/workflow.md` — 範例 ID 全面更新

## 未解決

`extract_req_ids` 的 regex 尚未對照真實產出的 `requirements.md` 驗證。
cc-sdd 未固定驗收條件的排版（標題 / 條列 / 表格皆可能），實測後可能需調整。
