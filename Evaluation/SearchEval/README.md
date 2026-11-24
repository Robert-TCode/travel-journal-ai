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
| One word, singular, plus related words | 6/9 | 0 | 4/4 | 1.3 s |
| `.dynamic` guide with similarity matching | 0/9 | 0 | 4/4 | 0.8 s |
| + 11 categories and weather words in the index | 8/9 | 0 | 4/4 | 1.3 s |
| + 38 categories, same description | 7/9 | 0 | 4/4 | 1.4 s |
| **+ 38 categories, description names what counts as drink (shipped), run twice** | 8/9, 8/9 | 0, 0 | 4/4, 4/4 | 1.7 s, 1.3 s |

What it showed:
- With `.focused()`, the tool's only argument is `keywords`, matched literally: "views" misses "view", "rainy day" misses
  "rain", "drink" misses "juice". Asking for single singular words fixed the first two.
- Asked to try related words, the small model still runs one search and stops: "what did I drink" never became "juice".
  Meaning has to be in the index, not in the query.
- With a `.dynamic` guide the model never called the tool (about 110 input tokens: the tool wasn't in the prompt).
- Selection never chose a wrong entry, and every unanswerable question came back empty: grounding by schema holds.
- Retrieval with a hit costs about 950 input tokens, a miss about 450. Selection adds about 0.35 s.

### Meaning in the index

Indexing also picks up to four categories from a fixed list of 38 (food, drink, beach, animal, people, train, hotel…),
and the Spotlight item gets the weather and time of day as plain words (rain, rainy, sunset) from the device.
Categories are words a traveller would search: singular, everyday, one word each.

- "what did I drink" found the juice through `drink`, "rainy day" found both rainy entries through the device's weather.
- Growing the list from 11 to 38 first made the juice "food, nightlife" (it was tagged "night"): more choices, worse
  picks. Saying in the description that anything drunk is drink, and that time and mood are not categories, fixed it
  in both following runs.
- The model still over-assigns ("nightlife" on a dinner, "water" on a rainy day). Retrieval then returns more, and
  selection throws the extra away: "a calm city" retrieved two entries and chose the one that answers it.
  Retrieval buys recall, selection keeps precision; neither step could do both.
- The one miss, "something sweet", has no dessert in the journal: whether a juice counts is a judgement call.
- The full list is part of the indexing schema, so it costs tokens on every indexing call.
