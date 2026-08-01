# Gherkin Guidelines

[Purpose: scenario 的寫法與 ID 慣例——trace-* 依賴此格式解析追溯關係]

本檔分兩部分：

1. **上游準則** —— AutomationPanda/gherkin-guidelines-for-ai，逐字引用
2. **本專案追加約定** —— 本 toolkit 追加。與上游衝突時**以追加約定為準**，
   衝突處在追加約定裡逐條標明

---

## 上游準則

> 來源：https://github.com/AutomationPanda/gherkin-guidelines-for-ai
> MIT License, Copyright (c) 2026 Pandy Knight
> 除移除原文 H1 標題外未作修改。

This document is a **context contract** for writing, reviewing, and maintaining Gherkin feature files that serve as
**living documentation** and **specification by example**.

The goals are:
- **Readable** by non-automation stakeholders
- **Deterministic** enough for LLMs to follow
- **Automation-ready** without leaking implementation details

This guidance assumes **Cucumber-compatible Gherkin** (the "Queen's Gherkin"). Reference: https://cucumber.io/docs/gherkin/reference/

---

## Guiding principles (apply everywhere)

- **Be behavior-driven**: describe *what* the system does, not *how* it’s implemented.
- **Write for humans first**: any engineer should understand what to do and what should happen.
- **Specification by example**: scenarios are concrete examples of behavior.
- **One behavior per scenario**: each scenario targets a single behavior.
- **Independent scenarios**: each scenario can run in isolation.

---

## Files and organization

- **MUST** save Gherkin in `*.feature` files.
- **MUST** use kebab-case file names.
- **SHOULD** keep all feature files under one main directory unless the project dictates otherwise.
- **MAY** use sub-directories; **SHOULD** organize by functional behavior area.

---

## Formatting rules (make diffs and parsing reliable)

- **MUST** use one `Feature` per file.
- **MAY** have multiple `Scenario` / `Scenario Outline` blocks under a single `Feature`.
- **MUST** indent the body of these sections by **2 spaces**:
  - `Feature`
  - `Background`
  - `Scenario`
  - `Scenario Outline`
  - `Examples`
- **SHOULD** keep lines under **120 characters**.
- **Vertical whitespace** (keep these together when editing a file):
  - **SHOULD** separate major sections with **one blank line**.
  - **SHOULD** put **one blank line** between adjacent `Scenario` / `Scenario Outline` blocks for
    readability and cleaner diffs.
  - **MUST NOT** put blank lines *between steps* within a scenario or background.
- **SHOULD** avoid comments; the scenario text should be self-explanatory.

---

## Vocabulary (ubiquitous language)

- **MUST** use one stable vocabulary for roles, domain objects, and states.
- **MUST NOT** swap synonyms for the same concept unless the product meaningfully distinguishes them
  (for example: "order" vs "purchase" vs "cart").

---

## Feature blocks

- **MUST** name `Feature:` after the behavior area it covers.
- **SHOULD** align the file name with the `Feature:` title.
- **MUST** keep the `Feature:` title to a single line.
- **SHOULD** include a short user story directly under the `Feature:` title using three lines:
  - `As a <role>`
  - `I want <goal>`
  - `So that <reason>`

---

## Background sections

- **MAY** omit `Background` entirely. `Background` is optional.
- **MUST** use `Background` only for a starting state shared by **multiple** scenarios in the file.
- **MUST NOT** have more than one `Background` section per `Feature` (and this guidance requires one
  `Feature` per file).
- **MUST NOT** use `Background` when only one scenario needs the setup.
- **SHOULD** keep backgrounds short; if a background grows, consider splitting feature files.

---

## Scenarios (structure + intent)

- **MUST** give each `Scenario:` / `Scenario Outline:` a single-line, behavior-focused title.
- **MUST** be chronologically executable step-by-step.
- **SHOULD** be declarative rather than imperative.
- **MUST** focus on behavior concerns; step definitions (automation code) handle implementation details.
- **SHOULD** keep steps at a **domain / business level of abstraction**: describe what actors do and
  what the system does in **product language**, not in framework or plumbing terms.
- **MUST NOT** leak automation or UI mechanics into steps (for example: selectors, XPath, "wait for,"
  "scroll to," "click element #foo") unless the behavior under test is truly about that mechanic.
- **MUST NOT** put HTTP endpoints, SQL, internal schema, or raw storage mechanics in step text unless
  the **behavior being specified** is inherently at that layer (for example, a service exposed only as
  an API).
- **SHOULD** prefer **state over navigation**: describe meaningful starting states (for example,
  "Given the user is signed in with role \"Editor\"") instead of imperative UI tours through every
  click and field, unless the **interaction path** is what this scenario is meant to specify.
- **SHOULD** use **minimal but sufficient** `Given` context: include only preconditions a reader needs
  to understand the behavior; omit unrelated setup that does not change the meaning of the example.
- **MUST NOT** bundle **multiple independent quality concerns** in one scenario (for example, core
  functional behavior together with performance, accessibility, or unrelated security checks) unless
  the scenario title and steps explicitly specify **one** behavior that legitimately spans those
  concerns. Otherwise split into separate scenarios.
- **SHOULD** use **concrete, realistic** example values in steps and tables (names, amounts, dates,
  realistic identifiers) so the scenario reads as a believable example.
- **SHOULD NOT** use meaningless placeholder data (`foo`, `bar`, `test`, `lorem`) unless the scenario
  is intentionally about generic, invalid, or deliberately nonsensical input.
- **SHOULD** target **< 10 steps**. If longer, consider splitting behaviors or using tables.

### Scenario Outline usage

- **MUST** use `Scenario Outline` only when the **same behavior** needs multiple input variations.
- **SHOULD** prefer `Scenario` when inputs don’t materially change the behavior being specified.

---

## Steps (language + semantics)

### Language rules

- **MUST** write steps in **third person** and **present tense**.
- **MUST** use **subject–predicate** phrasing.
- **MUST** use proper English grammar and spelling.
- **SHOULD** minimize punctuation; use it only when required for readability.
- **MUST** use double quotes (`"`) for string parameters.
- **SHOULD NOT** combine multiple actions/assertions with conjunctions inside one step; split into
  separate steps.

### Given / When / Then rules

- Treat **Given / When / Then** as **Arrange / Act / Assert**:
  - `Given` sets up context
  - `When` performs the action
  - `Then` verifies outcomes
- **MUST** maintain strict Given/When/Then order.
- **MUST NOT** repeat Given/When/Then phases inside one scenario; create separate scenarios instead.
- **MAY** use `And` to continue the same step type.
- **MAY** use `But` sparingly when a contrast improves readability.
- **MUST NOT** use `Or` as a step keyword. If choices matter, use separate scenarios or a
  `Scenario Outline`.

### Observable outcomes

- **MUST** make `Then` outcomes **observable and checkable** from the scenario text:
  what changed, what the user sees, or what the system reports.
- **MUST NOT** use vague outcomes like "it works" / "it succeeds" without stating how that is known.

### Multiline and structured payloads

- **SHOULD** use doc strings (`"""` … `"""`) for multiline or structured payloads
  (for example, JSON, XML, or an email body) instead of an enormous quoted string or many `And`s.

---

## Tables (data without step spam)

- **SHOULD** use step data tables to pass lists/sets of inputs instead of long `And` chains.
- **SHOULD** use concise, descriptive headers (often single-token with kebab-case).
- **SHOULD** keep step tables and `Examples` tables to a single screen view.
- If a table becomes large, reconsider whether the scenario is drifting into pure data-driven testing.

---

## Common anti-patterns (avoid)

- Mixing multiple behaviors into one scenario (multiple unrelated actions or assertions).
- Mixing unrelated **concerns** in one scenario (for example, happy-path functionality plus load time
  or unrelated accessibility rules) when they deserve separate specifications.
- Encoding UI implementation details (selectors, DOM structure) into step text.
- Over-specifying navigation and clicks when **state** would communicate the same precondition more
  clearly.
- Bloated `Given` chains that set up context the scenario never needs.
- Vague assertions ("it works", "it succeeds", "the user is logged in" without an observable signal).
- Placeholder example data (`foo` / `bar`) that does not read like a real specification example.
- Overusing `Scenario Outline` to generate many rows without distinct behavioral value.
- Extremely long scenarios or tables that no human will read or will seem like a [wall of text](https://en.wikipedia.org/wiki/Wikipedia:Wall_of_text).

---

## Quick checklist (for humans and LLMs)

Before finalizing a scenario, verify:
- [ ] One behavior only; can run independently
- [ ] No unrelated concerns bundled (split functional vs performance, a11y, etc. when separate)
- [ ] Stable vocabulary (no synonym swapping)
- [ ] Domain-level abstraction; no unnecessary UI/API/DB plumbing in steps
- [ ] State over navigation where it keeps the scenario clearer
- [ ] Minimal but sufficient `Given` context
- [ ] Concrete, realistic example data (not generic placeholders)
- [ ] Steps are third-person, present tense, subject–predicate
- [ ] Strict Given → When → Then order; `Then` outcomes are observable
- [ ] No UI/automation mechanics leaked into steps
- [ ] Blank line between scenarios in the same file
- [ ] Scenario is short (ideally < 10 steps); tables fit on one screen

---

## Recommended template

Use this as a starting point:

```gherkin
Feature: <behavior area>
  As a <role>
  I want <goal>
  So that <reason>

  Background:
    Given <shared starting state>

  Scenario: <single behavior>
    Given <context>
    And <additional context>
    When <action>
    And <continued action>
    Then <observable outcome>
    And <additional observable outcome>

  Scenario: <single behavior using a step data table>
    Given the following <domain entities> exist:
      | <column-a> | <column-b> |
      | <value 1>  | <value 2>  |
      | <value 3>  | <value 4>  |
    When <action>
    Then <observable outcome>

  Scenario Outline: <same behavior, varying inputs>
    Given <context>
    When <action> with "<input>"
    Then the outcome is "<outcome>"

    Examples:
      | input   | outcome   |
      | <case1> | <result1> |
      | <case2> | <result2> |
```

---

# 本專案追加約定

以下與上游衝突時，**以本節為準**。衝突處逐條標明。

## Scenario ID

每個 scenario 必須標註兩種 tag：自己的 ID，以及它驗證的需求。

```gherkin
@SCN-042 @REQ-3.1
Scenario: 匯出超過一萬筆時分頁處理
  Given ...
  When ...
  Then ...
```

`trace-*` 依賴這個格式解析對應關係。格式錯了追溯就斷了。

### `@REQ-N.M` —— 直接用 cc-sdd 的編號

`N.M` 是 `requirements.md` 的驗收條件編號，**不要另外發明別名**。

cc-sdd 在四個地方強制數字 ID：`requirements-review-gate`（退回非數字標題）、
`design-principles`（「must reference the same canonical numeric ID」）、
`kiro-impl`（「do NOT invent `REQ-*` aliases」）、`implementer-prompt`
（傳給 implementer 的是 source numbering）。

自建 `EARS-003` 這類別名會讓追溯出現兩份地圖，且 `trace.sh` 在真實的
`requirements.md` 上會零命中。見 [ADR-0007](../docs/decisions/0007-scenario-id-convention.md)。

### `@SCN-NNN` —— 流水號，不含語意

三條規則：

1. **不編碼任何語意。** 不含需求編號、不含模組名、不含日期
2. **單調遞增，永不重用。** scenario 刪除後號碼作廢——git 歷史、
   `qa-results.md`、舊 `tasks.md` 裡都還有引用，重用會讓歷史指向錯的東西
3. **序號與 REQ 無關。** `SCN-042 → REQ-2.1`、`SCN-043 → REQ-7.3` 完全正常

**為什麼不從 REQ 衍生（例如 `@SCN-3.1a`）：** `N.M` 是位置性的，
`requirements.md` 插一節就會位移。衍生的 SCN ID 得跟著改，而它們散在測試檔裡。

更嚴重的是，`trace-verify` 靠 tag 判斷「這是同一條 scenario」。
為了同步編號去改 tag，在它眼裡等同 scenario 被抽換——你會自己製造竄改訊號，
而且從此變成日常噪音，真的竄改就藏在裡面了。

**ID 的作用是讓身分在內容改變時存活。** 一旦 ID 帶語意，語意變它就得變，
這個作用就沒了。

### 一對多與多對一

一條需求通常對多條 scenario（正常路徑、邊界、失敗路徑）：

```gherkin
@SCN-042 @REQ-3.1            # 正常路徑
@SCN-043 @REQ-3.1            # 邊界：剛好 10000 筆
@SCN-044 @REQ-3.1 @REQ-5.2   # 失敗路徑，同時驗到權限需求
```

流水號天然支援兩個方向。要在中間插一條就用下一個號，不需要 `3.1b2` 這種東西。

### 代價

`SCN-042` 看不出在講什麼。這是**報告呈現**的問題，不是 ID 設計問題——
`trace-check` 輸出時要一併印 scenario 標題。

不要為了讓 ID 好讀而把語意塞回去。那是所有「聰明編號」腐爛的起點。

## 檔案位置

> ⚠️ **偏離上游 Files and organization：**上游 SHOULD 把所有 feature 檔
> 放同一個主目錄。本專案按 spec 分目錄——上游該條寫了
> 「unless the project dictates otherwise」，本節即為 dictate。

**契約與實作分開放。**

```
.kiro/specs/<feature>/features/*.feature   ← 驗收契約
tests/steps/…（依框架慣例）                 ← step definition
```

| | `.feature` | step definition |
|---|---|---|
| 性質 | 你核准的驗收條件 | 實作產物 |
| 實作期 | **唯讀** | 正常撰寫 |
| 位置 | spec 樹 | 專案測試目錄 |

`.feature` 放在 spec 樹的理由不是整齊，是**它會落在所有 task 的
`_Boundary:_` 之外**。implementer 去動它本身就是 boundary violation，
`kiro-review` 與 `kiro-validate-impl` 的 G.5 Boundary Audit 會抓。
等於 cc-sdd 免費幫 `trace-verify` 站了第二道崗。

step definition 是實作，本來就該由 implementer 寫，放專案測試目錄照常演進。

檔名仍照上游規定用 kebab-case，並與 `Feature:` 標題對齊。

## 測試框架設定

features 與 step def 分家需要一行設定：

```
cucumber-js     paths 指 .kiro/specs/*/features/，--import 指 step def
pytest-bdd      scenarios("<repo根>/.kiro/specs/<feature>/features/x.feature")
Cucumber-JVM    @CucumberOptions(features = "...", glue = "...")
godog           Options.Paths
```

> ⚠️ behave 要求 `steps/` 貼著 features 目錄，Reqnroll / SpecFlow 要求
> `.feature` 是專案項目並跑 code-behind 產生器。這兩者用本慣例要繞。
> 已知取捨，見 [ADR-0008](../docs/decisions/0008-feature-file-location.md)。

## 追加的檢查項

上游 Quick checklist 之外，本專案另外要求：

- [ ] 每個 scenario 都有 `@SCN-NNN` 且未與既有號碼重複
- [ ] 每個 scenario 至少帶一個 `@REQ-N.M`
- [ ] `@REQ-N.M` 在 `requirements.md` 中確實存在
- [ ] 每個 step 都有對應的 step definition（沒有的話這條 scenario 等同不存在）
