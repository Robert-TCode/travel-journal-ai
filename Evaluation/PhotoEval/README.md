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

### Tag wording

Same 20 photos, one change at a time. The forbidden list grew during this round (names the model invented),
so rows after the line are scored more strictly than the ones above it.

| Tags guide | Expected tag | No forbidden tag | Declined |
|---|---|---|---|
| Before | 13/20 | 19/20 | 0 |
| + "Always in English: translate text you read" | 15/20 | 19/20 | 0 |
| + "Name the exact dish, model or character only when you are sure" | 16/20 | 19/20 | 0 |
| *stricter forbidden list from here* | | | |
| Same as above, run twice (**shipped**) | 15/20, 14/20 | 17/20, 15/20 | 0, 2 |
| + "A place only if written or given; never prices, dates, numbers or codes", run twice | 14/20, 14/20 | 14/20, 15/20 | 2, 2 |

What it showed:
- With 20 photos, two runs of the same prompt differ by one or two points. Most wording changes are inside that noise.
- English tags were the one clear gain: text on labels became searchable ("pokka sapporo", "vitamin c").
- Telling a small model to name things "only when sure" doesn't stop guessing; it invented anime and car names in every run.
  It can't tell when it is sure.
- The guardrails sometimes decline the museum panel and the turmeric drink, once the model reads and translates their text.

### Reading text with OCRTool

Same 20 photos, the shipped prompt, without and with `OCRTool` in the session. Each call is cut off after 60 s.

| Variant | Expected tag | Timeouts | Declined | Tool calls | Avg latency | Avg input tokens |
|---|---|---|---|---|---|---|
| Photo only (**shipped**) | 14/20 | 0 | 2 | 0 | 2.2 s | 549 |
| Photo + `OCRTool` | 5/20 | 14 | 0 | 6 | 7.4 s | 1016 |

What it showed:
- The model called the tool exactly on the six photos with text (the step count, museum panel, two drinks, the soup can,
  the receipt) and never on the others.
- Every photo without text timed out: with the tool available but unused, the request didn't finish in 60 s.
- Where it worked, it cost 3.4× the time and almost twice the input tokens, and the tags weren't better: the model
  already reads labels from the image. It added ingredients from the small print ("coenzyme q10") and kept Japanese text.
- So `readsTextInPhotos` stays off. The one case it might pay for is dense small print, which a travel journal rarely needs.
