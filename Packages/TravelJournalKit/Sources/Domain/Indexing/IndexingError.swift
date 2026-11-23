/// Why indexing didn't produce tags. Indexers translate their framework's errors into this,
/// so the retry policy lives in Domain and is testable without a model.
public enum IndexingError: Error, Equatable {
    /// Worth trying again later: the model isn't ready, is busy or timed out. The entry stays pending.
    case temporarilyUnavailable
    /// Won't change on a retry: the entry is marked failed with this reason.
    case failed(IndexingFailure)
}

/// Stored with a failed entry, so the UI can say why it has no tags.
public enum IndexingFailure: String, Sendable, Equatable {
    /// The note doesn't fit in the model's context.
    case tooLong
    /// Written in a language the model doesn't support.
    case unsupportedLanguage
    /// The model's safety guardrails or a refusal stopped it.
    case declined
    /// Anything else; usually a bug on our side.
    case unexpected
}
