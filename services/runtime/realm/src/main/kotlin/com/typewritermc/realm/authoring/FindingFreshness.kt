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
 * The sets a reply lists, each judged by [judge] first: those with findings, an outcome other than finished, or an
 * outdated status. So a clean set the reply's view outdates stays listed, and a check missing from the reply has no
 * findings known: it is clean, or it has not run yet.
 */
internal fun List<FindingSet>.forReply(judge: (FindingSet) -> FindingSet): List<FindingSet> =
    map(judge).filter { it.findings.isNotEmpty() || it.outcome != CheckOutcome.FINISHED || it.status != FindingStatus.CURRENT }

/** Whether [set] was checked against this view's catalog and the values it read are still saved in this view. */
private fun AuthoringView.supports(set: FindingSet): Boolean = set.ticket.catalog == catalog.generation && values.holds(set.evidence)

private fun FindingSet.withStatus(current: Boolean): FindingSet =
    copy(status = if (current) FindingStatus.CURRENT else FindingStatus.OUTDATED)
