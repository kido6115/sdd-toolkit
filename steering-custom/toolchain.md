# Toolchain

[Purpose: 三個與技術棧綁定的指令。判定邏輯語言無關，只有這裡要換]

本檔的預設值是 **Python（pytest-bdd + mutmut）**。
其他語言的對應寫在下方，換掉這三個變數即可，其餘 skill 與腳本不用動。

`mutation-gate` 與 `trace-verify` 會讀本檔。

---

## 三個指令

```ini
# 依 tag 跑指定 scenario。{TAGS} 由呼叫端代入，格式為 "SCN-042 or SCN-043"
FEATURE_TEST_CMD=python -m pytest -m "{TAGS}"

# 找出沒有 step definition 的步驟
FEATURE_DRYRUN_CMD=python -m pytest --generate-missing --feature .kiro/specs/{FEATURE}/features/

# mutation testing。{MODULES} 由呼叫端代入，格式為 "pkg.mod.*" 的空白分隔清單
MUTATION_RUN_CMD=mutmut run {MODULES}
MUTATION_RESULT_CMD=mutmut results --all true
```

---

## Python（預設）

### 為什麼 tag 用 `-m` 而不是 `--tags`

pytest-bdd 把 Gherkin tag 轉成 pytest marker，用 pytest 原生的 `-m` 選取。

**含連字號的 tag 可用**，已在 pytest 9.1.1 + pytest-bdd 8.1.0 實測：
`-m "SCN-042"`、`-m "SCN-042 or SCN-043"`、`-m "BC-01"` 選取都正確。
所以 [ADR-0007](../docs/decisions/0007-scenario-id-convention.md) 的
`@SCN-NNN` 慣例不需要為 Python 讓步。

會出現 `PytestUnknownMarkWarning`。在 `conftest.py` 動態註冊即可消除：

```python
# conftest.py
import re, pathlib

def pytest_configure(config):
    tags = set()
    for f in pathlib.Path(".kiro/specs").rglob("*.feature"):
        tags |= set(re.findall(r"@([A-Z]+-[0-9.]+)", f.read_text(encoding="utf-8")))
    for t in sorted(tags):
        config.addinivalue_line("markers", f"{t}: sdd-toolkit trace tag")
```

### ⚠️ `--generate-missing` 的 exit code 不可用

實測結果是**反的**：

| 情況 | exit code |
|---|---|
| 有 undefined step | **0** |
| 全部都有實作 | **3**（pytest 的 NO_TESTS_COLLECTED） |

所以**必須解析輸出**，抓 `is not defined` 的行數，不可用 `&&` 串接。
`cmd && echo OK` 這種寫法會在有缺步驟時報成功——正是本 repo 最忌諱的
「靜默放行」。`trace-verify` 的實作要注意這點。

**dry-run 自己炸掉時也一樣不能信。** `.feature` 語法錯會讓 pytest 回
`INTERNALERROR` 且 exit `3`——與「全部實作完」同碼，輸出裡也沒有
`is not defined`。`trace.sh verify` 會偵測錯誤訊號並 `exit 2`。
為其他語言加設定時要一併考慮這種情況。

輸出範例：

```
Step Given "一個沒人實作的前置" is not defined in the scenario "沒有實作步驟的情節"
  in the feature "訂單匯出" in the file .../export.feature:15
```

含 scenario 名稱與 `檔案:行號`，可直接歸因。

### mutmut 的兩個坑

1. **設定檔必填。** `setup.cfg` 要有 `[mutmut] source_paths=<pkg>/`，
   否則連 `--help` 都會拋 `FileNotFoundError`
2. **`src/` layout 會失敗。** mutmut 3.7 會在 trampoline 斷言
   「module name starts with `src.`」。用一般的套件目錄名，不要用 `src/`

`mutmut run` 接受 mutant name 的 glob（`mutmut run "pkg.mod.*"`），
這是 diff scope 的作法。但**報表不會跟著縮**——`mutmut results` 與
`export-cicd-stats` 給的是資料庫裡的全部累積結果。
所以 diff scope 的分數要由 `mutate.sh` 自己從 `results --all true` 篩出來算。

---

## 其他語言

只換這三個變數，判定邏輯不動。

### JavaScript / TypeScript

```ini
FEATURE_TEST_CMD=npx cucumber-js --tags "@{TAGS}"
FEATURE_DRYRUN_CMD=npx cucumber-js --dry-run
MUTATION_RUN_CMD=npx stryker run --mutate {FILES}
MUTATION_RESULT_CMD=cat reports/mutation/mutation.json
```

Stryker 有 `--since` 可做增量，但語意是「相對於 git base」，
與本 toolkit 自行算 diff scope 的作法二選一。

### Java

```ini
FEATURE_TEST_CMD=mvn test -Dcucumber.filter.tags="@{TAGS}"
FEATURE_DRYRUN_CMD=mvn test -Dcucumber.execution.dry-run=true
MUTATION_RUN_CMD=mvn org.pitest:pitest-maven:mutationCoverage -DtargetClasses={CLASSES}
```

PIT 另有 `scmMutationCoverage` goal，直接以版控變更決定範圍。

### Go

```ini
FEATURE_TEST_CMD=go test ./... -godog.tags="@{TAGS}"
FEATURE_DRYRUN_CMD=go test ./...      # godog 預設就回報 undefined steps 並給 snippet
MUTATION_RUN_CMD=                     # 生態較弱，見下
```

**Go 的 mutation testing 沒有成熟選項**（go-mutesting、ooze 皆維護不積極）。
若專案主體是 Go，`quality-gates.md` 的 mutation 門檻應明確標為不適用，
而不是留著一道跑不動的閘門假裝有守。

---

## 加新語言時

只需要回答三個問題：

1. 怎麼依 tag 跑單條 scenario？
2. 怎麼找出沒有 step definition 的步驟？**並確認 exit code 可不可信**
3. mutation 工具能不能限定範圍？

第 2 點的 exit code 一定要實測。Python 那個是反的，別假設別家是對的。
