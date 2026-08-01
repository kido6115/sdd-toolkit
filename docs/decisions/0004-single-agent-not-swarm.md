# ADR-0004: 採 SwarmForge 精神但以單 agent 實作

狀態：已決定，**推理已於 ADR-0005 修訂**

> ⚠️ 本 ADR 的核心前提「本流程是單 agent」在 cc-sdd 3.0.2 下不成立。
> `kiro-impl` 的 autonomous 模式每個 task 派發 fresh implementer subagent、
> 獨立 reviewer subagent，失敗時再派 fresh debugger subagent——它本身就是
> 多 agent 編排，且 reviewer 明令不信任 implementer 的回報、自行跑 git diff。
>
> 結論（不自建 tmux/worktree 協調層）仍然成立，但理由變了：
> 不是「不需要第二個 agent」，而是「第二個 agent 已經由 cc-sdd 提供，
> 不必再疊一層」。下方「理由」段落請對照 [ADR-0005](0005-cc-sdd-overlap-audit.md) 閱讀。

## 脈絡

SwarmForge（unclebob/swarm-forge）以 tmux + git worktree 協調多 agent：
specifier 寫 Gherkin 與人工 QA 程序、coder 寫碼、cleaner 重構、
architect 管相依、hardener 跑 mutation test、QA 執行驗收程序。

紀律來自四件事：角色分離、Gherkin 可執行、mutation testing、活的 constitution。

## 決策

採用其紀律來源，但以單 agent 實作。不引入 tmux / worktree 協調。

## 理由

單 agent 的致命弱點是「自己宣稱通過」。但本流程選用的兩道閘門
——mutation score 與 Gherkin 綠燈——**都是機器裁決，不需要第二個 agent**。

把「獨立的 agent」換成「獨立的機器裁決」，紀律的來源沒有丟失。

實務紅利：Windows 環境下省去整層 tmux/worktree 麻煩。
SwarmForge 作者自己也指出，難的不是生出多個角色，
而是讓它們有用地分歧而不把 repo 變成委員會產物。

## 代價

- 人工 QA 程序無法交給獨立 agent 執行，必須由人跑。**這一步不能省。**
- 沒有 architect 角色持續看管模組相依，需靠 steering 的 constitution 約束。

## 何時重新評估

若單 agent 的自我驗證被證實不可信（例如 manual-qa 反覆抓到機器全綠但功能不可用），
再考慮上 SwarmForge 的 four-pack。
