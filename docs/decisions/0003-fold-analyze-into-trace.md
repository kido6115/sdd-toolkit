# ADR-0003: 將 Spec Kit 的 analyze 併入 trace，不單獨抄

狀態：已決定，**兩項結論經 ADR-0005 修訂**

> ⚠️ 本 ADR 的兩個結論都被 cc-sdd 3.0.2 的實況推翻：
>
> - **`checklist` — 抄** → 不抄。`kiro-spec-requirements` 內建的
>   `requirements-review-gate` 已完整涵蓋，且在寫檔前阻擋。`ears-checklist` 已刪除。
> - **`analyze` 併入 trace 變四方對應** → 不併。跨產出一致性分析
>   （需求 ↔ 設計 ↔ task）由 `kiro-validate-impl` 負責，trace 只保留
>   cc-sdd 沒有的 EARS ↔ scenario 那一軸。
>
> **「不要兩個功能重疊的檢查器」這條原則沒有變，變的是誰該退讓。**
> 當時假設 cc-sdd 那邊是空的，實際不是。

## 脈絡

原計畫抄三份 Spec Kit prompt：clarify、checklist、analyze。
ADR-0002 已用 grill-me 取代 clarify。剩下 checklist 與 analyze。

`analyze` 做的是跨產出一致性檢查（spec ↔ plan ↔ tasks）。
但本 repo 的 trace skill 本來就在做 ID 對應，功能高度重疊。

## 決策

- `checklist` — 抄。驗 EARS 本身的品質，與 trace 不重疊。
- `analyze` — 不抄。把 design 層併入 trace，變成四方對應
  （EARS ↔ scenario ↔ design ↔ task）。

## 理由

每多一份抄來的 prompt，就多一份會跟上游脫節、又沒人維護的東西。
兩個功能重疊的檢查器只會製造矛盾報告。

另外，直接裝 Spec Kit 也不可行：它讀 `.specify/` 下的 spec.md / plan.md，
路徑與檔名跟 `.kiro/specs/<feature>/` 都對不上。

## 代價

trace skill 的職責變重。若日後 design 層檢查的邏輯明顯膨脹，再拆出來。
