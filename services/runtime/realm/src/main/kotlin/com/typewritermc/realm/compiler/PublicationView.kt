package com.typewritermc.realm.compiler

import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.checking.FindingSet
import skirout.editor.v1.publication.PublicationActivationPhase
import skirout.editor.v1.publication.PublicationBaseline
import skirout.editor.v1.publication.PublicationCandidateId
import skirout.editor.v1.publication.PublicationChange
import skirout.editor.v1.publication.PublicationDelta
import skirout.editor.v1.publication.PublicationFailure
import skirout.editor.v1.publication.PublicationViewId

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
        /** Issued once per Ready assessment; the user can release it while its captured inputs remain current. */
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

/** One emitted review view; [id] identifies it, including changes that do not create a releasable candidate. */
data class PublicationView(
    val id: PublicationViewId,
    val status: PublicationStatus,
    internal val evidence: Map<DiagnosticId, DiagnosticEvidence> = emptyMap(),
)
