# Photo eval

Runs the app's real indexer on trip photos and scores the tags. It runs inside the Debug app
(`-photoEval`), because image input needs iOS 27 and the model doesn't run under xctest on the simulator.

The photos are personal and stay out of the repo (`Evaluation/Photos/` is ignored). `cases.json` lists
each photo with the words a good tag should contain, words no tag may contain, and the expected mood.

```
Evaluation/PhotoEval/run-device.sh <device identifier>     # iPhone: the numbers that count
OCR=1 Evaluation/PhotoEval/run-device.sh <device identifier>   # adds a run with OCRTool (device only)
Evaluation/PhotoEval/run-simulator.sh <simulator udid>     # text only: the simulator has no image model
```

A tag set scores when at least one tag contains an expected word. It's deliberately lenient: it shows
whether the model saw the right thing, not whether it picked the best word.

## Results

20 trip photos without a note, iPhone 17, iOS 27, photo only (no OCR).

| Variant | Expected tag | Mood right | No forbidden tag | Avg latency | Avg input tokens | Thermal |
|---|---|---|---|---|---|---|
| Mood always asked | 13/20 | 10/20 | 19/20 | 1.7 s | 593 | serious |
| **No note, no mood asked (shipped)** | **13/20** | **20/20** | 19/20 | 1.9 s | 514 | fair |

What it showed:
- Without a note the model still picked a mood from the scenery: every garden came out "relaxed". Leaving mood out of the schema fixed all ten, and saved about 80 input tokens.
- Without the mood to fill, it wrote more tags per photo (often 3–5 instead of 1–2).
- It reads text on labels without OCR, but keeps it in Japanese ("ウコン"), and it invents places: "tokyo" on a ticket from Odawara to Kyoto.
- A hot phone (thermal "serious") didn't change latency noticeably at this size.
