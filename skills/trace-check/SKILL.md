---
name: trace-check
description: 檢查 requirements.md 的驗收條件（N.M）、grill-notes.md 的邊界條件（BC）與 Gherkin scenario 的 tag 對應是否完整，找出沒有測試的需求、沒有需求的孤兒 scenario、未覆蓋的邊界條件。在 kiro-spec-requirements 與 scenario-write 之後、進入 design 之前執行。加上 --include-design 時一併檢查被引用的需求是否出現在 design.md。
---

執行 `${CLAUDE_SKILL_DIR}/scripts/trace.sh check $ARGUMENTS`，
把輸出的 JSON 報告整理成人類可讀的形式呈現。

**不要自行判讀通過與否。** 判定結果來自腳本的 exit code：

- `0` = 通過
- `1` = 有缺口，呈現缺口清單並告知使用者退回補齊
- `2` = 執行錯誤，呈現 `error` 欄位的訊息

不要為未通過的結果找理由，不要建議使用者略過。

## 六種缺口

| JSON 欄位 | 意義 | 退回哪裡 |
|---|---|---|
| `req_without_scenario` | 需求沒有 scenario 測它 | `/scenario-write` 補 |
| `scenario_without_req` | 孤兒 scenario，沒掛 `@REQ` | **通常是需求漏寫**，退回 requirements |
| `scenario_without_scn_tag` | scenario 沒有 `@SCN` | `/scenario-write` 補配號 |
| `duplicate_scn` | 同一個 `@SCN` 用在多條 scenario | 違反「永不重用」，補配新號 |
| `bc_without_scenario` | grill-me 挖出的邊界沒有著落 | 通常是需求漏寫了它 |
| `req_not_in_design` | 需求沒出現在 design.md | 退回 design |

**孤兒 scenario 最容易被錯誤處理。** 它代表測了一件沒人要求的事——
正確的修法幾乎都是「補需求」，不是「刪 scenario」。

## 呈現

`counts` 與 `coverage` 先講，再逐項列缺口。

`@SCN-042` 本身不可讀，**報告必須帶 scenario 標題**——
`scenario_without_req` 與 `scenario_without_scn_tag` 兩個欄位的字串
已經是「標題 [檔名]」的形式，直接用。

## exit 2 的三種常見原因

- `grill-notes.md` 不存在 → 先跑 `/grill-me` 與 `/grill-capture`
- `features/` 下沒有 `.feature` → 先跑 `/scenario-write`
- **在 `requirements.md` 找不到任何 `N.M` 編號** → 這不是「沒有需求」，
  是 `REQ_ID_PATTERN` 不符實際排版。腳本刻意在這裡停下，
  而不是回報「覆蓋率 0/0 通過」。請確認 `requirements.md` 的排版後調整 pattern
