# Quality Gates

[Purpose: 本專案各道閘門的量化門檻，供 mutation-gate 與 trace-* 讀取]

## mutation score

| 階段 | 門檻 | 備註 |
|---|---|---|
| 導入期（前 4 週） | 60% | 先建立習慣 |
| 穩定期 | <!-- TODO --> | 依實測調整，建議逐步上調 |

計分範圍：**本次 diff 涉及的檔案**，非全域。

> 一開始就設 80% 會讓你整個週期都在跟工具吵架。從低開始。

若本專案的語言沒有可用的 mutation 工具（例如 Go），把上表整段改成
**不適用**並寫明理由。留一道跑不動的閘門比沒有閘門更糟——
它會讓人以為測試強度有人在守。

執行指令見 `toolchain.md`。

## trace 覆蓋率

| 檢查 | 門檻 | 由誰判定 |
|---|---|---|
| REQ → scenario | 100%（無例外） | `trace-check` |
| scenario → REQ | 100%（不允許孤兒 scenario） | `trace-check` |
| BC → scenario | 100%（grill-notes 的每條邊界都要有著落） | `trace-check` |
| scenario → task 綁定完整 | 100% | `trace-verify` |
| scenario 未被竄改 / 刪除 / 偷加 | 100% | `trace-verify` |
| 每個步驟都有 step definition | 100% | `trace-verify` |

追溯沒有「大致上」，缺一條就是缺口。

> `trace-bind` **不在此表**——它是寫入操作，負責**建立**綁定，不負責判定。
> 綁定是否仍完整由 `trace-verify` 在收尾時認定。
> 一個會改檔案的步驟不該同時當自己的閘門。

> 「需求 → 設計」「需求 → task」的涵蓋度**不在此表**，由 cc-sdd 的
> `kiro-validate-impl`（F. Requirements Coverage / G. Design Alignment）認定。
> 兩套並存只會產出互相矛盾的報告。見 ADR-0005。

## manual-qa

無量化門檻。由人判定。任何一項不通過即退回。
