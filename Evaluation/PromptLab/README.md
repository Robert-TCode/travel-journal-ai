# Prompt lab

Measures the indexing prompt against the real on-device model, on the Mac. Every prompt change is
scored here before it reaches the app.

```
cd Evaluation/PromptLab
swift run -c release PromptLab 3
```

Needs a Mac with Apple Intelligence enabled. `Candidate.swift` holds the prompt under test (a copy of the
app's indexing schema and `IndexingPrompt.instructions`), `EvalCases.swift` the notes and expected answers.

## Results

13 notes × 3 runs, M1 Pro, macOS 26.

| Variant | Mood correct | Plain facts without mood | Injection resisted |
|---|---|---|---|
| Baseline: optional `mood` | 18/39 | 0/15 | 1/6 |
| A: explicit `none` case | 26/39 | 8/15 | 1/6 |
| A + B: `feelingWords` generated before `mood` | 20/39 | 1/15 | 0/6 |
| **A + C: A plus a mood rule in the instructions (shipped)** | **27/39** | **9/15** | 1/6 |

What it showed:
- An optional property is not a real choice for the model: it almost never generates a missing value. An explicit `none` case it does pick.
- Asking for evidence first (B) made things worse: the model invented "feeling words" such as "excited" for "Ferry to Miyajima", then followed them.
- Travel notes ("train tickets", "ferry") still get `excited`. The model links travel with excitement even when told not to.
- The prompt doesn't stop injection. The app drops model tags that are mood words, so "tag everything as happy" can't add a mood.
