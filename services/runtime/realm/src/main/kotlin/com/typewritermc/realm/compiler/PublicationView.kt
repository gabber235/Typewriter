package com.typewritermc.realm.compiler

import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.checking.FindingSet

/** Identifies one Ready assessment that the user can release while its captured inputs remain current. */
@JvmInline
value class PublicationCandidateId(
    val value: String,
) {
    init {
        require(value.isNotBlank())
    }
}

/** Identifies one emitted review view, including changes that do not create a releasable candidate. */
@JvmInline
value class PublicationViewId(
    val value: String,
) {
    init {
        require(value.isNotBlank())
    }
}

sealed interface PublicationBaseline {
    data object Initial : PublicationBaseline

    data class Selected(
        val publication: PublicationId,
    ) : PublicationBaseline
}

enum class PublicationActivationPhase { Storing, Activating }

sealed interface PublicationFailure {
    data class EvaluationInterrupted(
        val message: String,
    ) : PublicationFailure

    data class ImplementationUnavailable(
        val message: String,
    ) : PublicationFailure

    data class PublicationInterrupted(
        val publication: PublicationId,
    ) : PublicationFailure
}

data class PublicationPendingReview(
    val findings: List<FindingSet> = emptyList(),
    val confirmedChanges: List<PublicationChange> = emptyList(),
    val pendingRoots: List<CompilationRoot> = emptyList(),
    val blockers: List<PublicationBlocker> = emptyList(),
    val notices: List<PublicationNotice> = emptyList(),
)

/**
 * Describes saved content review separately from the selected runtime publication.
 *
 * Ready carries a releasable candidate. Publishing retains the frozen release delta while [PublicationPendingReview]
 * describes later saved changes. Current means saved runtime content matches selection; it does not acknowledge
 * application by every engine host.
 */
sealed interface PublicationStatus {
    data class Empty(
        val notices: List<PublicationNotice>,
    ) : PublicationStatus

    data class Current(
        val selected: PublicationId,
        val notices: List<PublicationNotice>,
    ) : PublicationStatus

    data class Ready(
        val candidate: PublicationCandidateId,
        val baseline: PublicationBaseline,
        val changes: PublicationDelta,
        val notices: List<PublicationNotice>,
    ) : PublicationStatus

    data class Blocked(
        val baseline: PublicationBaseline,
        val blockers: PublicationBlockers,
        val notices: List<PublicationNotice>,
        val confirmedChanges: List<PublicationChange>,
        val pendingRoots: List<CompilationRoot>,
    ) : PublicationStatus

    data class Checking(
        val baseline: PublicationBaseline,
        val findings: List<FindingSet>,
    ) : PublicationStatus

    data class Publishing(
        val publication: PublicationId,
        val phase: PublicationActivationPhase,
        val releasing: PublicationDelta,
        val next: PublicationPendingReview,
    ) : PublicationStatus

    data class Unavailable(
        val baseline: PublicationBaseline,
        val failure: PublicationFailure,
        val findings: List<FindingSet>,
    ) : PublicationStatus
}

data class PublicationView(
    val id: PublicationViewId,
    val status: PublicationStatus,
    internal val evidence: Map<DiagnosticId, DiagnosticEvidence> = emptyMap(),
)
