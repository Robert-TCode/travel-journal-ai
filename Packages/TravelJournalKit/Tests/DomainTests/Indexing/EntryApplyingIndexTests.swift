import Foundation
import Testing
import Domain

@Suite("Entry applying an index")
struct EntryApplyingIndexTests {
    private let entry = Entry(tripID: UUID(), text: "Walked 20k steps.")

    @Test func addsTagsThenMoodAndMarksDone() {
        let indexed = entry.applying(EntryIndex(tags: ["walking", "steps"], mood: .tired))

        #expect(indexed.tags == ["walking", "steps", "tired"])
        #expect(indexed.indexingStatus == .done)
    }

    @Test func noMoodAddsNoMoodTag() {
        let indexed = entry.applying(EntryIndex(tags: ["bus"], mood: nil))

        #expect(indexed.tags == ["bus"])
    }

    @Test func keepsExistingTagsAndSkipsDuplicates() {
        var tagged = entry
        tagged.tags = ["hiking"]

        let indexed = tagged.applying(EntryIndex(tags: ["hiking", "view"], mood: .amazed))

        #expect(indexed.tags == ["hiking", "view", "amazed"])
    }

    @Test func normalizesTagsSoSearchTreatsThemAsOne() {
        let indexed = entry.applying(EntryIndex(tags: ["Narita", " narita ", "Lost Luggage", "", "  "], mood: nil))

        #expect(indexed.tags == ["narita", "lost luggage"])
    }

    @Test func aMoodWordAsATagIsDroppedSoOnlyTheMoodDecides() {
        let indexed = entry.applying(EntryIndex(tags: ["beach", "Happy"], mood: nil))

        #expect(indexed.tags == ["beach"])
    }

    @Test func aMoodTagTheUserAddedStays() {
        var tagged = entry
        tagged.tags = ["happy"]

        #expect(tagged.applying(EntryIndex(tags: ["beach"], mood: nil)).tags == ["happy", "beach"])
    }

    @Test func aSuccessfulRetryClearsTheOldFailure() {
        var failed = entry
        failed.indexingStatus = .failed
        failed.indexingFailure = .tooLong

        let indexed = failed.applying(EntryIndex(tags: ["steps"], mood: nil))

        #expect(indexed.indexingStatus == .done)
        #expect(indexed.indexingFailure == nil)
    }

    @Test func keepsTheLandmarkWhenItWasOneOfTheNearbyPlaces() {
        var nearOwakudani = entry
        nearOwakudani.nearbyPlaces = ["Owakudani", "Hakone Ropeway"]

        #expect(nearOwakudani.applying(EntryIndex(tags: [], mood: nil, landmark: "Owakudani")).landmark == "Owakudani")
    }

    @Test func ignoresALandmarkThatWasNeverOffered() {
        var nearOwakudani = entry
        nearOwakudani.nearbyPlaces = ["Owakudani"]

        #expect(nearOwakudani.applying(EntryIndex(tags: [], mood: nil, landmark: "Mount Fuji")).landmark == nil)
    }

    @Test func neverTouchesTheText() {
        #expect(entry.applying(EntryIndex(tags: ["x"], mood: .happy)).text == entry.text)
    }

    @Test func storesTheCategoriesForSearch() {
        let indexed = entry.applying(EntryIndex(tags: ["pineapple juice"], mood: nil, categories: [.drink]))

        #expect(indexed.categories == [.drink])
        #expect(indexed.tags == ["pineapple juice"])
    }
}
