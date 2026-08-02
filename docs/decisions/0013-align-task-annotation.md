# ADR-0013: 綁定標註對齊 cc-sdd 的家族，不自創 `_DoD:`

狀態：已決定

## 脈絡

`trace-bind` 原本在 `tasks.md` 寫入自創欄位：

```
- _DoD: SCN-042, SCN-043 由紅轉綠_
```

稽核時發現 `DoD` 在整個 repo 出現十餘次，**沒有任何一處展開它是什麼**。
而它會出現在 `tasks.md` 裡，是 implementer subagent 會讀到的內容。

cc-sdd 的標註家族長這樣：

```
_Requirements: 3.1, 3.2_
_Boundary: ExportService_
_Depends: 2.1, 2.2_
```

底線斜體、名詞複數、列 ID。`_DoD:` 不屬於這個家族——它是縮寫、是新概念名，
implementer 讀到只能從「由紅轉綠」四個字猜。

更重要的是，cc-sdd 本來就有一個放完成條件的位置。
`tasks-generation.md:127`：

> Every executable sub-task must include at least one detail bullet that states
> the **observable completion condition**.

那就是 cc-sdd 語彙裡的 DoD，而且是普通的 detail bullet，不是特殊標註。

## 決策

寫入兩行，各自用 cc-sdd 既有的形式：

```diff
  - [ ] 2.1 (P) 實作分頁匯出
    - 讀取訂單並依上限切頁
+   - 驗收條件：SCN-042, SCN-043 由紅轉綠（實作前先跑，必須是紅）
    - _Requirements: 3.1, 3.2_
+   - _Scenarios: SCN-042, SCN-043_
    - _Boundary: ExportService_
```

| 行 | 對應 cc-sdd 的什麼 |
|---|---|
| `- 驗收條件：…` | detail bullet，即它要求的 observable completion condition |
| `- _Scenarios: …_` | 標註，與 `_Requirements:` / `_Boundary:` / `_Depends:` 同一家族 |

detail bullet 在 annotation 之前，照 cc-sdd 範本的排列。

## 理由

**`_Scenarios:` 不需要解釋。** 與 `_Requirements:` 並排時語意自明——
「這個 task 涵蓋哪幾條需求 / 哪幾條 scenario」。它也不宣稱重新定義「完成」，
只是列出對應關係，跟旁邊兩個標註同性質。

**完成條件的語意放回 cc-sdd 指定的位置。** 「由紅轉綠、實作前先跑確認為紅」
是 observable completion condition，寫成 detail bullet 而非塞進標註裡。
`implementer-prompt.md` 明列 implementer 會拿到 task 內文，不需要新機制。

兩者不是重複：cc-sdd 原有的 bullet 說的是**功能**完成條件
（「匯出 25000 筆產生 3 個檔案」），本 skill 加的是**驗收**完成條件
（「SCN-042 由紅轉綠」）。這個 repo 的整個論點就是那兩件事不同。

這是延續 ADR-0007 的同一個判斷：**能用 cc-sdd 既有的東西就不要自創。**
當時是 ID（`EARS-003` → `REQ-3.1`），這次是欄位名。

## 遷移

`_DoD:` 行在重跑 `trace-bind` 時會自動清除並改寫，不需要手動處理。
`trace-verify` 的 `binding_broken` 改讀 `_Scenarios:`。

## 保留的問題

`_Scenarios:` 終究還是 cc-sdd 沒有的欄位——它結構上沒有 scenario 這一層
（ADR-0005 已確認）。差別只在形式上寄生得乾不乾淨：
原本是外來語，現在是同一家族的成員。

## 未解決

**`_Scenarios:` 與驗收條件那一行是否真的傳達到 implementer subagent，仍未驗證。**

`implementer-prompt.md` 列出的 Inputs 是「task identifier/text」，
沒有明說自訂的 detail bullet 與標註會不會原樣傳下去。cc-sdd 自己的
`_Boundary:` / `_Depends:` 是 `kiro-impl` 主動解析的，我們這兩行它不認得。

只能實跑一輪才知道。若不傳達，第 4 條紀律的交付機制要重想
（見 [#2](https://github.com/kido6115/sdd-toolkit/issues/2)）。
