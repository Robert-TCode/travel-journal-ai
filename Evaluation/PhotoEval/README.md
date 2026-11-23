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
