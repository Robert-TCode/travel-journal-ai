import Testing
@testable import DesignSystem

@Suite("Contrast")
struct ContrastTests {
    /// 3:1 is WCAG's minimum for large text; titles and trip names on skies are large and bold.
    @Test(arguments: Sky.all)
    func textIsReadableOnEveryPartOfTheSky(_ sky: Sky) {
        for stop in sky.stops {
            #expect(sky.foregroundRGB.contrast(with: stop) >= 3, "\(sky) fails on one of its stops")
        }
    }

    /// The primary button on a sky uses the sky's text color as fill and its first stop as label.
    @Test(arguments: Sky.all)
    func primaryButtonOnASkyIsReadable(_ sky: Sky) {
        #expect(sky.foregroundRGB.contrast(with: sky.stops[0]) >= 3)
    }

    @Test func neutralTextMeetsBodyTextContrast() {
        #expect(Palette.Light.ink.contrast(with: Palette.Light.background) >= 7)
        #expect(Palette.Light.secondaryInk.contrast(with: Palette.Light.background) >= 4.5)
        #expect(Palette.Light.secondaryInk.contrast(with: Palette.Light.surface) >= 4.5)
        #expect(Palette.Light.onInk.contrast(with: Palette.Light.ink) >= 7)
        #expect(Palette.Light.accent.contrast(with: Palette.Light.background) >= 4.5)
    }
}

@Suite("Sky")
struct SkyTests {
    @Test func everyPhaseAndConditionHasItsOwnSky() {
        #expect(Sky.all.count == Sky.Phase.allCases.count * Sky.Condition.allCases.count + 1)
        #expect(Set(Sky.all.map(\.stops)).count == Sky.all.count)
    }

    @Test func nightSkiesAreDarkAndDaySkiesAreLight() {
        #expect(Sky(phase: .night, condition: .clear).isDark)
        #expect(!Sky(phase: .day, condition: .clear).isDark)
        #expect(!Sky.unknown.isDark)
    }
}
