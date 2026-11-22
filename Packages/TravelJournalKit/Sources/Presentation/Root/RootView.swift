import SwiftUI
import Domain

public struct RootView: View {
    private let availabilityService: any AIModelAvailabilityService
    private let repository: any EntryRepository
    private let indexingQueue: any IndexingQueue
    private let currentTripID: UUID

    public init(
        availabilityService: any AIModelAvailabilityService,
        repository: any EntryRepository,
        indexingQueue: any IndexingQueue,
        currentTripID: UUID
    ) {
        self.availabilityService = availabilityService
        self.repository = repository
        self.indexingQueue = indexingQueue
        self.currentTripID = currentTripID
    }

    public var body: some View {
        TabView {
            Tab("Trips", systemImage: "map") {
                TripsView()
            }
            Tab("Capture", systemImage: "plus.circle") {
                CaptureView(
                    availabilityService: availabilityService,
                    repository: repository,
                    indexingQueue: indexingQueue,
                    tripID: currentTripID
                )
            }
        }
    }
}

#Preview {
    RootView(
        availabilityService: PreviewAvailabilityService(.available),
        repository: PreviewEntryRepository(),
        indexingQueue: PreviewIndexingQueue(),
        currentTripID: UUID()
    )
}
