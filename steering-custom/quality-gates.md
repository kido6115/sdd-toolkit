# Quality Gates

[Purpose: 本專案各道閘門的量化門檻，供 mutation-gate 與 trace-* 讀取]

## mutation score

| 階段 | 門檻 | 備註 |
|---|---|---|
| 導入期（前 4 週） | 60% | 先建立習慣 |
| 穩定期 | <!-- TODO --> | 依實測調整，建議逐步上調 |

計分範圍：**本次 diff 涉及的檔案**，非全域。

> 一開始就設 80% 會讓你整個週期都在跟工具吵架。從低開始。

## trace 覆蓋率

| 檢查 | 門檻 | 由誰判定 |
|---|---|---|
| REQ → scenario | 100%（無例外） | `trace-check` |
| scenario → REQ | 100%（不允許孤兒 scenario） | `trace-check` |
| scenario → task | 100% | `trace-bind` |
| scenario 未被竄改 | 100% | `trace-verify` |

追溯沒有「大致上」，缺一條就是缺口。

> 「需求 → 設計」「需求 → task」的涵蓋度**不在此表**，由 cc-sdd 的
> `kiro-validate-impl`（F. Requirements Coverage / G. Design Alignment）認定。
> 兩套並存只會產出互相矛盾的報告。見 ADR-0005。

## manual-qa

無量化門檻。由人判定。任何一項不通過即退回。
