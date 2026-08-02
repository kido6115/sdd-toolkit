# ADR-0006: steering 以 cc-sdd 的設計為主，移除 install.sh

狀態：已決定

## 脈絡

原本 `install.sh` 把本 repo 的 `steering/` symlink 進目標專案的 `.kiro/steering/`，
理由是「改一次，所有專案生效」。

這個做法有三個問題：

1. **繞過 cc-sdd 的機制。** cc-sdd 有 `kiro-steering`（維護 product / tech /
   structure）與 `kiro-steering-custom`（產出領域專屬 steering）。
   symlink 是從側面塞檔進它管理的目錄，它不知道那些檔案存在。

2. **symlink 的「全專案同時生效」是負債不是資產。** steering 是**專案記憶**
   （cc-sdd `steering-principles.md` 的定義），不是共用設定。
   一個專案的 mutation 門檻調整不該波及其他專案。

3. **`.kiro/steering/` 本來就不會被 Claude Code 自動載入。**
   那是 Kiro IDE 靠 front-matter `inclusion: always` 做的事。
   symlink 進去只是讓檔案存在，不代表 agent 讀得到——見 ADR-0005。

## 決策

- **移除 `install.sh`。** 不再自動注入任何東西
- `steering/` 更名為 `steering-custom/`，定位改為**範本**：
  複製進專案後由該專案自行維護，不再連回本 repo
- 檔案格式對齊 cc-sdd `templates/steering-custom/` 的慣例：
  `# Title` + `[Purpose: ...]`、一檔一主題、專案記憶而非規格書
- `constitution.md` 更名為 `acceptance-discipline.md`。
  cc-sdd 的 steering 模型沒有「憲法」這個層級，一檔一主題才是它的形狀。
  同時刪去與 `kiro-impl` / `kiro-review` / `kiro-verify-completion` 重複的條文

## 理由

「單一治理真相來源」這條原則沒變，但**真相來源應該是 cc-sdd 的
`.kiro/steering/`，本 repo 只提供它缺的那幾片**。

側面 symlink 進去等於在 cc-sdd 的目錄裡放它不認識的檔案，
是製造第二個來源，不是統一來源。

## 代價

- 失去「改一次全專案生效」。這是刻意的——見上方理由 2
- 安裝變成手動：把 `skills/` 複製或 symlink 進 `.claude/skills/`，
  把 `steering-custom/` 的檔案複製進 `.kiro/steering/`（或用
  `/kiro-steering-custom` 產出後貼入內容）
- 沒有任何機制保證 `acceptance-discipline.md` 會被 agent 讀到。
  這是 ADR-0005 指出的既有問題，本 ADR 不解決，但也不再假裝 symlink 解決了它

## 未解決 → 已解決（ADR-0011）

> 原文：「`.kiro/steering/` 在 Claude Code 底下的載入路徑仍然缺失。
> `quality-gates.md` 靠 `mutation-gate/SKILL.md` 明確指名而被讀到，
> `acceptance-discipline.md` 與 `gherkin-guidelines.md` 目前沒有對應的指名者。」

`gherkin-guidelines.md` 已由 `scenario-write/SKILL.md` 指名（ADR-0009）。
`acceptance-discipline.md` 移出 steering 改為 `docs/` 的設計說明
（[ADR-0011](0011-acceptance-discipline-to-docs.md)）——逐條稽核後發現
它沒有一條非得靠 steering 載入才能生效。

由此得到的判準：**steering 只放「有 skill 指名、且內容不重複腳本行為」的東西。**
