import DesignSystem
import Domain
import Foundation
import SwiftUI

struct RecentEntryRow: View {
    let entry: Entry
    var photoURL: URL?

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            if let photoURL {
                PhotoThumbnail(url: photoURL)
            } else {
                SkyThumbnail(sky: Sky(entry: entry), size: PhotoThumbnail.defaultSize)
                    .overlay {
                        if entry.audioName != nil {
                            Image(systemName: "waveform")
                                .font(.dsTitle)
                                .foregroundStyle(Sky(entry: entry).foreground)
                        }
                    }
            }
            details
            Spacer(minLength: 0)
        }
        .padding(Spacing.m)
        .dsSurface()
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.dsBody)
                    .foregroundStyle(Palette.ink)
                    .lineLimit(3)
            }
            if entry.audioName != nil {
                voiceNote
            }
            meta
            indexing
        }
    }

    @ViewBuilder
    private var voiceNote: some View {
        if let transcript = entry.transcript, !transcript.isEmpty {
            Text("“\(transcript)”")
                .font(.dsBody)
                .foregroundStyle(Palette.ink)
                .lineLimit(3)
        } else {
            StatusLabel("Voice note", systemImage: "waveform")
        }
    }

    private var meta: some View {
        HStack(spacing: Spacing.s) {
            Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
            if let place {
                Text(place)
                    .lineLimit(1)
            }
            if let mood {
                MoodLabel(mood)
            }
        }
        .font(.dsMeta)
        .foregroundStyle(Palette.secondaryInk)
    }

    @ViewBuilder
    private var indexing: some View {
        switch entry.indexingStatus {
        case .pending:
            StatusLabel("Tagging…", systemImage: "sparkles")
        case .failed:
            StatusLabel(failureText, systemImage: "tag.slash")
        case .done:
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.xs) {
                        ForEach(tags, id: \.self) { TagChip($0) }
                    }
                }
            }
        }
    }

    /// "Owakudani · Hakone, Kanagawa": the landmark is what the memory is about, the city is where to find it.
    private var place: String? {
        let parts = [entry.landmark, entry.placeName].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var failureText: String {
        switch entry.indexingFailure {
        case .tooLong: "Too long to tag"
        case .unsupportedLanguage: "Not tagged: only English is supported"
        case .declined: "Not tagged automatically"
        case .unexpected, nil: "Not tagged"
        }
    }

    /// Mood is stored as a tag from a fixed vocabulary; it's shown apart so it doesn't read like a topic.
    private var mood: String? {
        entry.tags.first { Mood(rawValue: $0) != nil }
    }

    private var tags: [String] {
        entry.tags.filter { Mood(rawValue: $0) == nil }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.s) {
            RecentEntryRow(entry: Entry(tripID: UUID(), text: "Walked 20k steps today, my feet hurt.", weather: .clear, dayPhase: .night, tags: ["walking", "steps", "tired"], indexingStatus: .done))
            RecentEntryRow(entry: Entry(tripID: UUID(), text: "Black ice cream!", placeName: "Hakone, Kanagawa", weather: .cloudy, dayPhase: .day, nearbyPlaces: ["Owakudani"], landmark: "Owakudani"))
            RecentEntryRow(entry: Entry(tripID: UUID(), text: "", audioName: "a.m4a", transcript: "Ferry to Miyajima, windy but sunny.", dayPhase: .day, tags: ["ferry"], indexingStatus: .done))
            RecentEntryRow(entry: Entry(tripID: UUID(), text: "Fahrt nach Hallstatt.", indexingStatus: .failed, indexingFailure: .unsupportedLanguage))
        }
        .padding()
    }
    .dsScreenBackground()
}
