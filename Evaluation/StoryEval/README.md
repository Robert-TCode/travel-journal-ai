# Story eval

Writes the story of every trip on a connected iPhone with the app's on-device writer, without saving it, and reports
title, story, highlights and latency. It runs in the Debug app (`-storyEval`): in the simulator the same request failed
(`LanguageModelError -1`, `ModelManagerError 1026`) while text indexing worked.

```
Evaluation/StoryEval/run-device.sh <device identifier>
```

The report quotes the journal: `report-*.md` is ignored by git, and results below describe it without quoting.

## Results

Two trips (1 and 4 entries), iPhone 17, iOS 27, on-device model.

| Trip | Latency | Highlights | Invented facts |
|---|---|---|---|
| 1 entry | 3.6 s | 1, a real entry | none; one sentence of mood the note didn't state ("carried that quiet energy") |
| 4 entries | 3.6 s | 4, all real entries | none: rain, the view, the meal and the juice are all in the notes |

What it showed:
- Highlights are labels from a schema that lists only the trip's entries, so each one opens a real memory.
- The model keeps to the notes but colours them: it adds a feeling or a reading ("felt like home away from home" for
  a note that wishes the juice were sold at home). Fine for a retelling, worth watching on longer trips.
- With one entry, the caption repeats the note. A story needs a few memories to be worth a tap.
- These trips are tiny. The writer trims notes when a trip doesn't fit the 8k context; a real two-week trip is where
  on-device and Private Cloud Compute (32k context) will differ, once PCC is available.
