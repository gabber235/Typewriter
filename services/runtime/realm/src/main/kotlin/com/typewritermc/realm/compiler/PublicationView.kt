package com.typewritermc.realm.compiler

import com.typewritermc.types.unknownVariant
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.PublicationBlocker
import skirout.editor.v1.publication.PublicationBlockers
import skirout.editor.v1.publication.PublicationDiagnosticDetails
import skirout.editor.v1.publication.PublicationNotice
import skirout.editor.v1.publication.PublicationStatus

/*
 * The review state is the generated Skir PublicationView and PublicationStatus. It describes saved content review
 * separately from the selected runtime publication: Ready carries a releasable candidate, issued once per Ready
 * assessment, which the user can release while its captured inputs remain current. Publishing retains the frozen
 * release delta while its pending review describes later saved changes. Current means saved runtime content matches
 * selection; it does not acknowledge application by every engine host.
 *
 * Diagnostics are classified once at the saved candidate evaluation boundary. A notice variant states the severity of
 * its finding, so the constructors below admit only the matching severity.
 */

/** A notice for an information or warning finding, or null for an error, which blocks publication instead. */
internal fun Diagnostic.notice(evidence: DiagnosticEvidence?): PublicationNotice? =
    when (severity) {
        DiagnosticSeverity.INFORMATION -> PublicationNotice.InformationWrapper(details(evidence))
        DiagnosticSeverity.WARNING -> PublicationNotice.WarningWrapper(details(evidence))
        DiagnosticSeverity.ERROR -> null
        else -> unknownVariant(severity)
    }

/** A blocker for an error finding. */
internal fun Diagnostic.blocker(evidence: DiagnosticEvidence?): PublicationBlocker {
    require(severity == DiagnosticSeverity.ERROR) { "Only error findings block publication." }
    return PublicationBlocker(details = details(evidence))
}

/** A blocking assessment always has at least one reason. */
internal fun List<PublicationBlocker>.blockers(): PublicationBlockers = PublicationBlockers(first = first(), additional = drop(1))

internal val PublicationBlockers.all: List<PublicationBlocker> get() = listOf(first) + additional

/** The notices of a review state that carries them. */
internal val PublicationStatus.notices: List<PublicationNotice>
    get() =
        when (this) {
            is PublicationStatus.EmptyWrapper -> value.notices
            is PublicationStatus.CurrentWrapper -> value.notices
            is PublicationStatus.ReadyWrapper -> value.notices
            is PublicationStatus.BlockedWrapper -> value.notices
            else -> emptyList()
        }

private fun Diagnostic.details(evidence: DiagnosticEvidence?): PublicationDiagnosticDetails =
    PublicationDiagnosticDetails(
        id = id,
        origin = origin,
        code = code,
        message = message,
        primary = primary,
        related = related,
        evidence = evidence?.toSkir(),
    )
