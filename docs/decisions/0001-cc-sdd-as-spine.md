# ADR-0001: 以 cc-sdd 為主體，而非 Spec Kit

狀態：已決定

## 脈絡

評估過 Spec Kit、cc-sdd、BMAD、OpenSpec、Superpowers、GSD。
迭代週期為數天至兩週。環境為 Windows/WSL + Claude Code + GitLab。

## 決策

主體採用 cc-sdd。

## 理由

- 兩週的工作區塊正中 cc-sdd 的設計靶心（它明確不適合小的迭代改動）
- steering 的專案記憶跨 feature 累積，週期越長價值越高
- 已核准 spec 轉自主實作的路徑，對得上 ticket-to-PR 的目標
- 既有的 EARS ticket template 幾乎零成本接上
- 入門摩擦最低（一行 npx，內建 zh-TW，Windows 明確支援）

## 未採用 Spec Kit 的理由

- `/speckit.specify` 一定開新 branch 加新 artifact，沒有就地更新既有 spec 的指令
- 官方定位偏向端到端的獨立 feature build，對增量修改效果較差
- 產物量與 review 負擔較重

Spec Kit 的**閘門設計**仍值得參考，見 ADR-0002、ADR-0003。

## 代價

- cc-sdd 的品質閘門比 Spec Kit 弱，需自行補齊（本 repo 的存在理由）
- 單一維護者專案，bus factor 較低
