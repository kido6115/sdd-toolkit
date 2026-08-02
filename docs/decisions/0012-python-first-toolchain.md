# ADR-0012: 技術棧以 Python 為主，三個指令外置為 toolchain.md

狀態：已決定

## 脈絡

三件事共用同一個依賴「技術棧未定」，見 [#2](https://github.com/kido6115/sdd-toolkit/issues/2)：

1. `mutate.sh` 檔案不存在，`mutation-gate/SKILL.md` 卻呼叫它
2. `_DoD:` 綁定的 scenario 無法被單獨執行
3. `trace.sh verify` 的「缺 step definition」檢查

## 決策

**主力 Python（pytest-bdd + mutmut），設計上相容 Java / JavaScript / Go。**

語言相依的部分收斂成 `.kiro/steering/toolchain.md` 的三個指令，
判定邏輯（分數計算、門檻比對、缺口差集）全部語言無關。

## 實測結果

### `@SCN-042` 的連字號在 pytest 可用——tag 慣例不必改

原本擔心 pytest-bdd 把 Gherkin tag 轉成 pytest marker 時，
連字號不合 Python 識別字規則，會逼 [ADR-0007](0007-scenario-id-convention.md)
改用 `@SCN_042`。

實測 pytest 9.1.1 + pytest-bdd 8.1.0：

```
-m "SCN-042"                → 精確選中該條
-m "SCN-042 or SCN-043"     → 兩條都選中
-m "BC-01"                  → 正確
```

只會出現 `PytestUnknownMarkWarning`，用 `conftest.py` 動態註冊即可消除
（範本寫在 `toolchain.md`）。**`@SCN-NNN` 慣例維持不變。**

### ⚠️ `--generate-missing` 的 exit code 是反的

pytest-bdd 找 undefined step 的指令是
`pytest --generate-missing --feature <dir>`。實測：

| 情況 | exit code |
|---|---|
| 有 undefined step | **0** |
| 全部都有實作 | **3**（pytest 的 NO_TESTS_COLLECTED） |

**必須解析輸出**抓 `is not defined`，不可用 exit code，不可用 `&&` 串接。
`cmd && echo OK` 會在有缺步驟時報成功——正是本 repo 最忌諱的靜默放行。

這條寫進 `toolchain.md` 的警示，並要求為其他語言加設定時**一定要實測
exit code**，別假設別家是對的。

### mutmut 的兩個坑與 diff scope 的作法

- `setup.cfg` 必須有 `[mutmut] source_paths=`，否則連 `--help` 都會拋例外
- `src/` layout 會在 trampoline 斷言失敗，要用一般套件目錄名

`mutmut run "pkg.mod.*"` 可以限定執行範圍，但**報表不會跟著縮**——
`mutmut results` 與 `export-cicd-stats` 給的是資料庫累積結果。

所以 `mutate.sh` **自己算 diff scope 的分數**：從 `git diff --name-only`
推導模組前綴，篩 `mutmut results --all true` 的逐 mutant 狀態。

實測差距是實質的：

```
全域       6 killed / 12 total = 50%
diff scope 3 killed /  7 total = 42%
```

門檻 60% 時，全域分數看起來比較接近，diff scope 藏不住。

## `mutate.sh` 的三個不放行

延續 `trace.sh` 的原則：寧可擋住，不可誤判為通過。

| 情況 | 行為 |
|---|---|
| `MUTATION_RUN_CMD` 未定義 | `exit 2`，並提示若語言無工具應在 `quality-gates.md` 標為不適用 |
| diff scope 內沒有任何 mutant | `exit 2`——通常是模組前綴推導錯誤，**不當作 0/0 達標** |
| diff 未涉及可 mutate 的檔案 | `exit 0` + `verdict: SKIPPED`，明確標示範圍為空而非通過 |

第三種與前兩種不同：範圍真的空是正常情況，不該擋住流程，
但也不能報成 PASS 讓人以為驗過了。

## Go 的例外

Go 的 mutation testing 生態不成熟（go-mutesting、ooze 維護皆不積極）。
`quality-gates.md` 已加註：若語言無可用工具，把 mutation 門檻整段標為
**不適用**並寫明理由。

**留一道跑不動的閘門比沒有閘門更糟**——它會讓人以為測試強度有人在守。

## 代價

- `toolchain.md` 是第三份進 steering 的檔案。它通過 ADR-0011 的收錄判準：
  有指名者（`mutation-gate`）、內容是參數而非重述腳本行為
- Python 以外的三組設定**未經實測**，僅依各框架文件寫出。
  實際採用時要先驗，特別是 dry-run 的 exit code
