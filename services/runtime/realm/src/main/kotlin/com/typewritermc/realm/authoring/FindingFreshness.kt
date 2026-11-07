package com.typewritermc.realm.authoring

import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus

/**
 * This set marked current when [view] supports it, outdated otherwise. The status the check runtime stored is not
 * consulted: an editor reply describes [view], so a set whose evidence still holds there is current for it even while
 * the runtime reruns the check.
 */
internal fun FindingSet.judgedAgainst(view: AuthoringView): FindingSet = withStatus(view.supports(this))

/**
 * This set marked current only while the check runtime still holds it current and [view] supports it. Publication
 * gates a release on the set, so one the runtime already marked outdated (discovery incomplete, a failed pass) stays
 * outdated even when its evidence still matches [view].
 */
internal fun FindingSet.judgedForRelease(view: AuthoringView): FindingSet =
    withStatus(status == FindingStatus.CURRENT && view.supports(this))

/**
 * This set as a reply carries it: its evidence only when it has something to report, since a reader compares
 * evidence only for the findings and outcome it shows. Judge it first, which needs the evidence.
 */
internal fun FindingSet.forReply(): FindingSet =
    if (findings.isEmpty() && outcome == CheckOutcome.FINISHED) copy(expectations = emptyList()) else this

/** Whether [set] was checked against this view's catalog and the values it read are still saved in this view. */
private fun AuthoringView.supports(set: FindingSet): Boolean =
    set.ticket.catalog == catalog.generation && values.conflicts(set.expectations).isEmpty()

private fun FindingSet.withStatus(current: Boolean): FindingSet =
    copy(status = if (current) FindingStatus.CURRENT else FindingStatus.OUTDATED)
