# ADR-0004: 取 SwarmForge 的驗收紀律，不取其協調架構

狀態：已決定（原標題為「以單 agent 實作」，經 ADR-0005 重寫）

## 脈絡

SwarmForge（unclebob/swarm-forge）以 tmux + git worktree 協調多 agent：
specifier 寫 Gherkin 與人工 QA 程序、coder 寫碼、cleaner 重構、
architect 管相依、hardener 跑 mutation test、QA 執行驗收程序。

原本的問法是「要不要跟著做多 agent」。**那是錯的問題。**

cc-sdd 的 `kiro-impl` autonomous 模式本身就是多 agent 編排：每個 task
派 fresh implementer subagent、獨立 reviewer subagent（自跑 git diff，
不信 implementer 回報），失敗兩輪再派 fresh debugger subagent。
agent 數量不是本 repo 的決策軸，是 cc-sdd 的實作細節。

## 決策

取 SwarmForge 的**驗收紀律**，不取其**協調架構**。

具體是三件事：

1. **Gherkin 是可執行的驗收**——scenario 由人核准，實作者不能挑測試
2. **mutation testing**——測試強度要被量化，不能靠「測試都過了」自稱
3. **人工 QA 不可省**——機器全綠不代表東西能用

不自建 tmux / worktree / 角色分派。

## 理由

SwarmForge 的角色分離，目的是讓「寫的人」和「驗的人」不是同一個。
這件事 cc-sdd 已經做了（`kiro-review` 明令不信任 implementer 的回報）。
再疊一層自己的協調只會有兩套互相不知道對方存在的編排。

但 cc-sdd 的驗收軸是空的：它驗的是 implementer 自己寫的測試會不會過，
不驗那些測試是否對應到你核准的驗收條件，也不驗那些測試夠不夠嚴。
SwarmForge 的 specifier / hardener / QA 三個角色補的正是這一段——
而這三件事**都不需要另一個 agent 來做**，只需要獨立的機器裁決加一次人工。

## 代價

- 人工 QA 程序必須由人跑。**這一步不能省。**
  cc-sdd 的 `MANUAL_VERIFY_REQUIRED` 只是「機器測不了」的逃生口，不是驗收程序
- 沒有 architect 角色持續看管模組相依。
  部分由 cc-sdd 的 `kiro-validate-impl` G.5 Boundary Audit 覆蓋，
  但它管的是 spec 宣告的 boundary，不管 Clean Code 層級的相依方向

## 何時重新評估

若 manual-qa 反覆抓到「機器全綠但功能不可用」，代表 cc-sdd 的 reviewer
不夠嚴。那時該做的是**加嚴閘門**，不是再加 agent。
