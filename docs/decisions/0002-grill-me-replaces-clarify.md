# ADR-0002: 以 grill-me 取代 Spec Kit 的 clarify

狀態：已決定

## 脈絡

cc-sdd 的 requirements 階段傾向直接從一句話產出 requirements.md，
中間缺乏反詰機制。需要在需求成形前把意圖挖乾淨。

候選：抄 Spec Kit 的 `clarify` prompt，或引入 mattpocock 的 grill-me skill。

## 決策

採用 grill-me，不抄 clarify。

## 理由

| | Spec Kit clarify | grill-me |
|---|---|---|
| 對象 | 已寫好的 spec 檔 | 你腦中的計畫 |
| 時機 | specify 之後 | specify 之前 |
| 深度 | 掃描未明確處 | 走完整棵決策樹 |
| 追問 | 弱 | 回答引出新問題會繼續挖 |

關鍵差異是**時機**。在 spec 寫出來之後才 clarify，等於在已經成形的錯誤上修補。
grill-me 在 spec 之前介入，產出的是更清楚的意圖，不是另一份要 review 的文件。

副作用（正面）：grill-me 逼出來的邊界條件直接就是 Gherkin scenario 的素材。

## 代價

- grill 過程中不能 `/clear`，與 cc-sdd 每階段核准的節奏略有衝突
- 需自行約定落檔規則（grill-notes.md），否則 context 一清就沒了
