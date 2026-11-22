# Travel Journal AI

A travel journal for iOS. You capture memories in a second: a note, a photo, a voice message. The app quietly understands them on device (place, weather, tags, mood) so you can find them later by asking in plain words, like *"the black ice cream"* or *"best views from my Norway trip"*.

> Learning project. Work in progress.

## How it uses AI

- **Capture is instant and silent.** Saving never waits for or depends on a model.
- **Silent indexing, on device.** After saving, the on-device model adds tags and a mood; code adds place, date, weather and trip.
- **AI answers only when you ask:** search across memories (on device), or ask about a single memory, where world knowledge may need a cloud model. The UI says when data leaves the phone.

## Status

- [ ] Week 1 — Foundations: availability, save without AI
- [ ] Week 2 — Silent indexing of text entries
- [ ] Week 3 — Photos, video and tools
- [ ] Week 4 — Voice and trip screens
- [ ] Week 5 — Search across memories (local RAG)
- [ ] Week 6 — Ask about a memory, trip highlights (cloud)
- [ ] Week 7 — Evaluations
- [ ] Week 8 — Write-up

## Requirements

- Xcode 27, iOS 27 SDK
- Apple Intelligence–capable iPhone with Apple Intelligence enabled (the simulator can't run the on-device model unless the host Mac supports Apple Intelligence)

## Structure

```
TravelJournal/                 App target — composition root only
Packages/TravelJournalKit/
  Sources/Domain/              Entities and protocols (no Apple data frameworks)
  Sources/DataLayer/           Persistence, location, weather, Spotlight, language models
  Sources/Presentation/        SwiftUI views and view models
  Tests/                       Swift Testing suites per layer
```

Dependency rule: `Presentation → Domain ← DataLayer`. Only the app target sees all three.

## Build & test

```bash
xcodebuild test -project TravelJournal.xcodeproj -scheme TravelJournal -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

## Privacy

Indexing and search run on device. Your notes never leave the phone unless you explicitly ask a question that needs a cloud model, and the UI says so. No API keys ship in the binary.

What does leave the phone when you save an entry, and why:

| Data | Sent to | Why |
|---|---|---|
| Coordinates | Apple Maps (MapKit reverse geocoding) | Turn a location into a place name |
| Coordinates | [Open-Meteo](https://open-meteo.com) (no account, no key) | Weather and day/night at that moment |

Nothing else is sent: no note text, no tags, no identifiers. Without location permission, nothing is sent at all.

## Measurements

_Coming in week 7._
