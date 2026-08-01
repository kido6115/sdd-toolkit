# ADR-0003: 將 Spec Kit 的 analyze 併入 trace，不單獨抄

狀態：已決定

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
