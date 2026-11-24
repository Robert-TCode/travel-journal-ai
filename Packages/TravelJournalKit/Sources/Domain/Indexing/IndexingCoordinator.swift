/// Lives at app level, so indexing outlives the screen that saved the entry.
/// Context is gathered as soon as an entry arrives, so it describes the moment of capture
/// even when the entry waits behind others for the model.
/// Indexing is serial on purpose: the on-device model is a single shared resource, so parallel
/// requests gain no speed and only add memory pressure.
public actor IndexingCoordinator: IndexingQueue {
    private let contextProvider: any EntryContextProvider
    private let transcriber: any Transcriber
    private let indexer: any EntryIndexer
    private let repository: any EntryRepository
    private let live: LiveIndexing
    private var queue: [Task<Entry, Never>] = []
    private var drainTask: Task<Void, Never>?

    public init(
        contextProvider: any EntryContextProvider,
        transcriber: any Transcriber,
        indexer: any EntryIndexer,
        repository: any EntryRepository,
        live: LiveIndexing
    ) {
        self.contextProvider = contextProvider
        self.transcriber = transcriber
        self.indexer = indexer
        self.repository = repository
        self.live = live
    }

    public func enqueue(_ entry: Entry) {
        append(Task { await addContext(to: entry) })
    }

    /// Indexes entries left pending by a previous run. Their context is not refetched:
    /// the moment they were captured has passed, and today's location or weather would be wrong.
    public func resumePendingEntries() async {
        let pending = (try? await repository.pendingEntries()) ?? []
        for entry in pending {
            append(Task { entry })
        }
    }

    private func append(_ entry: Task<Entry, Never>) {
        queue.append(entry)
        if drainTask == nil {
            drainTask = Task { await drain() }
        }
    }

    /// For tests; the app never needs to wait.
    public func waitUntilIdle() async {
        while let drainTask {
            await drainTask.value
        }
    }

    private func addContext(to entry: Entry) async -> Entry {
        let withContext = entry.applying(await contextProvider.currentContext())
        try? await repository.save(withContext)
        return withContext
    }

    /// Part of the serial step, so a pending voice note resumed after a relaunch is transcribed too.
    /// Rethrows only `temporarilyUnavailable`; a recording that can't be transcribed comes back without a transcript.
    private func addTranscript(to entry: Entry) async throws -> Entry {
        guard let audioName = entry.audioName, entry.transcript == nil else { return entry }
        let transcript: String
        do {
            transcript = try await transcriber.transcribe(audioNamed: audioName)
        } catch IndexingError.temporarilyUnavailable {
            throw IndexingError.temporarilyUnavailable
        } catch {
            return entry
        }
        var transcribed = entry
        transcribed.transcript = transcript
        try? await repository.save(transcribed)
        return transcribed
    }

    private func drain() async {
        while !queue.isEmpty {
            let entry = await queue.removeFirst().value
            await index(entry)
        }
        drainTask = nil
    }

    private func index(_ queued: Entry) async {
        let entry: Entry
        do {
            entry = try await addTranscript(to: queued)
        } catch {
            // Left pending, like a busy model: `resumePendingEntries()` tries again on the next launch.
            return
        }
        var updated = entry
        // Asked about nothing, the model still answers: an untranscribed voice note came back as "japan, tokyo, sakura".
        guard entry.hasWrittenNote || !entry.photoNames.isEmpty else {
            updated.indexingStatus = .failed
            updated.indexingFailure = .noContent
            try? await repository.save(updated)
            return
        }
        let live = live
        do {
            updated = entry.applying(try await indexer.index(entry) { partial in
                await live.show(entry.previewing(partial))
            })
        } catch IndexingError.temporarilyUnavailable {
            // Left pending: `resumePendingEntries()` tries again on the next launch.
            await live.clear(entry.id)
            return
        } catch IndexingError.failed(let failure) {
            updated.indexingStatus = .failed
            updated.indexingFailure = failure
        } catch {
            updated.indexingStatus = .failed
            updated.indexingFailure = .unexpected
        }
        // The original entry is already stored; if this write fails, it simply stays pending.
        try? await repository.save(updated)
        await live.clear(entry.id)
    }
}
