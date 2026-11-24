# Search eval

Runs the app's real search (`SpotlightSearchTool` retrieval, then grounded selection) on the iPhone, against that
phone's own journal, for each question in `queries.txt`. It runs in the Debug app (`-searchEval`) because the search
tool's model assets aren't in the simulator.

```
Evaluation/SearchEval/run-device.sh <device identifier>
```

The report lists the journal's entries so each answer can be judged by hand. It is personal: `report-*.md` is ignored
by git, and results below describe behaviour without quoting entries.

## Results

5 entries, 13 questions (9 the journal can answer, 4 it can't), iPhone 17, iOS 27, on-device model.

| Retrieval instructions | Answerable questions found | Wrong entries chosen | "Nothing found" when right | Avg latency |
|---|---|---|---|---|
| Copy the question's words | 4/9 | 0 | 4/4 | 1.2 s |
| **One word, singular, plus related words (shipped)** | 6/9 | 0 | 4/4 | 1.3 s |
| `.dynamic` guide with similarity matching | 0/9 | 0 | 4/4 | 0.8 s |

What it showed:
- With `.focused()`, the tool's only argument is `keywords`, matched literally: "views" misses "view", "rainy day" misses
  "rain", "drink" misses "juice". Asking for single singular words fixed the first two.
- Asked to try related words, the small model still runs one search and stops: "what did I drink" never became "juice".
  Meaning has to be in the index, not in the query.
- With a `.dynamic` guide the model never called the tool (about 110 input tokens: the tool wasn't in the prompt).
- Selection never chose a wrong entry, and every unanswerable question came back empty: grounding by schema holds.
- Retrieval with a hit costs about 950 input tokens, a miss about 450. Selection adds about 0.35 s.
