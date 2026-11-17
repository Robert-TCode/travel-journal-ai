# Travel Journal AI

A travel journal for iOS that figures out *where, when and what* from photos, text and voice notes — on device by default, with cloud models only for long-form trip stories.

> Learning project. Work in progress.

## Status

- [ ] Week 1 — Basics & photos
- [ ] Week 2 — Structured entries & tools
- [ ] Week 3 — Image understanding & grounding
- [ ] Week 4 — Audio & streaming UI
- [ ] Week 5 — Private search (local RAG)
- [ ] Week 6 — Cloud models & trip story
- [ ] Week 7 — Agentic mode & evaluations
- [ ] Week 8 — Write-up

## Requirements

- Xcode 27, iOS 27 SDK
- Apple Intelligence–capable iPhone with Apple Intelligence enabled (the simulator can't run the on-device model unless the host Mac supports Apple Intelligence)

## Structure

```
TravelJournal/                 App target — composition root only
Packages/TravelJournalKit/
  Sources/Domain/              Entities, use cases, protocols (no Apple data frameworks)
  Sources/DataLayer/           Photos, MapKit, Contacts, Spotlight, language models
  Sources/Presentation/        SwiftUI views and view models
  Tests/                       Swift Testing suites per layer
```

Dependency rule: `Presentation → Domain ← DataLayer`. Only the app target sees all three.

## Build & test

```bash
xcodebuild test -project TravelJournal.xcodeproj -scheme TravelJournal -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

## Privacy

Extraction and search run on device. Only trip-story generation may use cloud models, and the UI says so. No API keys ship in the binary.

## Measurements

_Coming in week 7._
