# 驗收紀律：每一條由什麼機制保證

> 這份文件**不是 steering**，不進 agent 的 context。
>
> 它原本是 `constitution.md`，後來是 `.kiro/steering/acceptance-discipline.md`。
> 逐條稽核後發現沒有一條是「非得靠 steering 載入才能生效」的——它們要嘛
> 被腳本強制、要嘛被結構強制、要嘛已在需要它的 skill 裡重述。
> 留在 steering 只會製造第二份可能不同步的說法。
> 見 [ADR-0011](decisions/0011-acceptance-discipline-to-docs.md)。
>
> 所以它改成寫給**人**看的：這套紀律為什麼長這樣，以及每一條實際靠什麼撐著。

---

## 核心命題

cc-sdd 的 `kiro-impl` 會做 RED → GREEN，但**紅燈的對象是 implementer
自己挑的測試**——它自己寫的、自己知道能過的。

這個 toolkit 存在的理由就一句話：**把紅燈的定義權從實作者手上拿回來。**

其餘七條都是在保護這句話不被繞過。

---

## 七條紀律與它們的支撐點

### 1. 每條驗收條件至少對應一個 scenario

**由誰保證：** `trace.sh check` 的 `req_without_scenario` 差集，exit 1。

沒有對應的需求視為未完成，不得進入 design 階段。

**若失效：** 需求寫了等於沒寫。這是最基本的一條，也是唯一從第一天就有機器裁決的。

---

### 2. `.feature` 沒有 step definition 等同不存在

**由誰保證：** `trace.sh verify`——**尚未實作**。

需要跑測試框架的 dry-run 找 undefined steps，而那綁技術棧。

**目前是裸露的。若失效：** `.feature` 退化成文件裝飾，
整套追溯鏈驗的是一堆不會執行的文字。**這是最大的裸露面。**

---

### 3. `.feature` 在實作期唯讀

**由誰保證：結構，不是規則。**

檔案住在 `.kiro/specs/<feature>/features/`，物理上落在所有 task 的
`_Boundary:_` 之外。implementer 一動它，`kiro-review` 就判為
Boundary Violation，`kiro-validate-impl` 的 G.5 Boundary Audit 也會抓。

這是 [ADR-0008](decisions/0008-feature-file-location.md) 刻意換來的：
接受 behave / SpecFlow / cucumber-ruby 三個生態要多繞一步，
換 cc-sdd 免費站一班崗。

step definition 是實作產物，放專案測試目錄，正常撰寫。

**若失效：** agent 改斷言讓測試過關，而且沒人知道。

---

### 4. `kiro-impl` 的紅燈對象必須包含綁定的 scenario

**由誰保證：** `trace-bind` 寫入 `tasks.md` 的 `_DoD:` 行。

```
- [ ] 2.1 (P) 實作分頁匯出
  - _Requirements: 3.1, 3.2_
  - _DoD: SCN-042, SCN-043 由紅轉綠_
```

交付機制選 `tasks.md` 而非 steering，是因為 implementer subagent
一定會讀 `tasks.md`——不依賴任何 steering 載入機制。

**目前只做到一半。** `_DoD:` 說了「點亮哪兩條」，沒說「怎麼單獨跑那兩條」。
`kiro-impl` 推導出的是跑整套的指令，紅燈訊號會被既有的綠燈稀釋。

**若失效：核心命題就沒了。** 這條是整套的樞紐。

---

### 5. task 的完成定義是「綁定的 scenario 由紅轉綠」

**由誰保證：** 同第 4 條。

`kiro-review` 的 APPROVED 與 `kiro-verify-completion` 是**必要條件，
不是充分條件**——它們驗的是 task 自己的測試，不驗 scenario。

---

### 6. mutation score 只計本次 diff scope

**由誰保證：** `mutation-gate/SKILL.md` 自己就寫了，門檻明確指名
`.kiro/steering/quality-gates.md`（那份留在 steering，因為真的會被讀）。

**目前是裸露的：** `scripts/mutate.sh` **檔案不存在**，SKILL.md 卻呼叫它。

全域分數容易靠灌水達標，diff scope 藏不住。存活的 mutant 必須逐一說明：
測試不夠嚴，還是該 mutant 等價。

---

### 7. exit code 不可被詮釋

**由誰保證：** 每個 `trace-*` 與 `mutation-gate` 的 SKILL.md 自己都寫了
「不要自行判讀通過與否」。

腳本這邊也配合：`trace.sh` 在抓不到任何 `N.M` 編號時 `exit 2` 並說明
pattern 可能不符排版，而**不是**回報「覆蓋率 0/0 通過」。
最危險的失敗模式是掃出空集合然後放行。

一般性的「不實完成宣稱」防護沿用 cc-sdd 的 `kiro-verify-completion`，
本 repo 不重述。

---

## 現在還裸露的三處

| 紀律 | 缺什麼 |
|---|---|
| 2 | step definition 存在性檢查（需框架 dry-run） |
| 4 | scenario 的單獨執行指令（需 tag filter） |
| 6 | `mutate.sh` 根本不存在 |

三個共用同一個依賴：**技術棧未定**。
追蹤於 [#2](https://github.com/kido6115/sdd-toolkit/issues/2)。

在那之前，這套的實際保護力是：需求 ↔ scenario 的追溯完整（1）、
契約不被偷改（3）、DoD 有寫下來（4 的一半）。
**測試強度與可執行性完全沒有保障。**

---

## Code Quality

<!-- TODO: 依 SwarmForge 的 Clean Code constitution 補齊。
     建議涵蓋：函式長度、命名、相依方向、重複、註解政策。
     參考 github.com/unclebob/swarm-forge 各 runnable branch 的 constitution 條文。

     ⚠️ 本檔已不是 steering——寫在這裡的 Clean Code 條文 agent 讀不到。
     若真要約束程式碼風格，該寫進 cc-sdd 產出的 .kiro/steering/tech.md
     或 structure.md（那兩份有 10 個 skill 在讀），並先確認不與既有內容重複。 -->
