# Travel Journal AI

A travel journal for iPhone that understands your memories on device.

You capture a moment in a tap or two: a note, a photo, a voice message. The app saves it right away. Then Apple's
on-device model quietly tags it, so later you can find it by asking in plain words: *"the black ice cream"*,
*"best views from my Norway trip"*.

> A learning project about AI inside iOS apps: on-device, cloud and the line between them.
> Work in progress. The numbers below are real measurements, not claims.

## Principles

- **Save first, enrich after.** Saving never waits for a model. Tags arrive afterwards. If the model fails, the
  memory is still there, and indexing is retried on the next launch.
- **Capture silently, answer on demand.** The app never replies to what you write. AI only speaks when you ask.
- **Facts come from code, judgement from the model.** Date, place, weather and nearby landmarks are looked up by code
  and given to the model as context. The model only picks from what it sees and what it was given.
- **On device by default.** Nothing goes to a cloud model unless you ask for it, and the UI says so.

## How an entry gets indexed

```mermaid
flowchart LR
    A[Save<br/>note · photo · voice] --> B[(SwiftData<br/>status: pending)]
    B --> C[Context from code<br/>place · weather · day phase<br/>nearby landmarks]
    C --> D[On-device model<br/>guided generation]
    D --> E[(Entry<br/>tags · mood · landmark)]
    D -. busy or not ready .-> B
```

- **Guided generation with a dynamic schema.** The output schema is built per entry. The landmark is an `anyOf` of
  the places MapKit actually found nearby (plus `none`), so the model can't invent one. Mood is only asked for when
  there is a written note.
- **Voice notes** are transcribed on device with Speech. The audio is the memory; the transcript is for search.
- **Errors are translated into a retry policy** in the Domain layer: "the model is busy" leaves the entry pending,
  "this note is too long" or "unsupported language" marks it failed and the UI says why.

## What I measured

Photos: 20 of my own travel photos on an iPhone 17 with iOS 27. Notes: 13 notes × 3 runs on the Mac. Details, raw
tables and what each run taught me: [photo eval](Evaluation/PhotoEval/README.md) · [prompt lab](Evaluation/PromptLab/README.md).

| Question | Answer |
|---|---|
| How long does indexing a photo take? | ~2 s, ~550 input tokens |
| Does the model get the mood right without a note? | 10/20 when asked. 20/20 once mood is simply not asked for |
| Does telling it "name things only when sure" stop invented names? | No. It can't tell when it's sure |
| Does writing tags in English help search? | Yes, the one clear gain: labels in Japanese became searchable words |
| Is `OCRTool` worth it for photos? | No: 3.4× slower, timeouts on photos without text, no better tags |
| How noisy is a 20-photo eval? | ±1–2 points between identical runs. Most prompt tweaks are inside that |

## Status

- [x] Foundations: model availability, trips, save without AI
- [x] Silent indexing of text: guided generation, mood, error handling
- [x] Photos and context: image input, weather, nearby landmarks with a dynamic schema, OCR experiment
- [x] Voice notes with on-device transcription
- [ ] Live tags while you watch, editable tags, trip mosaic
- [ ] Search across memories (Core Spotlight, local RAG)
- [ ] Ask about a memory and trip story (Private Cloud Compute)
- [ ] Evaluation across models

## Architecture

```
TravelJournal/                 App target: composition root, debug photo eval
Packages/TravelJournalKit/
  Sources/Domain/              Entities, use cases, protocols. No Apple data frameworks
  Sources/DataLayer/           SwiftData, location, weather, MapKit, Speech, Foundation Models
  Sources/Presentation/        SwiftUI views and view models
  Tests/                       Swift Testing suites per layer
Packages/DesignSystem/         Tokens and components ("sky by hour" colours)
Evaluation/
  PromptLab/                   Scores prompt changes against the real model on the Mac
  PhotoEval/                   Runs the app's indexer on photos on a real iPhone
```

Dependencies point inwards: `Presentation → Domain ← DataLayer`. Foundation Models types never leave DataLayer, so
the indexing and retry logic is tested without a model.

## Running it

Requirements: Xcode 27 with the iOS 27 SDK, and an iPhone with Apple Intelligence turned on. The simulator runs the
app and text indexing, but has no image model.

1. Copy `Config/Signing.local.example.xcconfig` to `Config/Signing.local.xcconfig` and set your team ID and bundle ID.
2. Open `TravelJournal.xcodeproj` and run the `TravelJournal` scheme.

Tests:

```bash
xcodebuild test -project TravelJournal.xcodeproj -scheme TravelJournal -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

## Privacy

Indexing runs on the phone. Notes, photos, transcripts and tags never leave it. No API keys ship in the app.

What does leave the phone when you save an entry, only if location is allowed and there is a network:

| Data | Sent to | Why |
|---|---|---|
| Coordinates | Apple Maps (MapKit) | Place name, and landmarks within 300 m |
| Coordinates | [Open-Meteo](https://open-meteo.com) (no account, no key) | Weather, sunrise and sunset at that moment |

Nothing else is sent: no text, no tags, no identifiers.

The test photos used in the evaluations are personal and are not in this repository.

## License

[MIT](LICENSE)
