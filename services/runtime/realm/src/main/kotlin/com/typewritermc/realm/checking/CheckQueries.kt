package com.typewritermc.realm.checking

import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.realm.authoring.RealmServices
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.evidence
import com.typewritermc.realm.authoring.extensions
import com.typewritermc.realm.authoring.generation
import com.typewritermc.realm.authoring.tracked
import com.typewritermc.realm.formula.ContentFindings
import com.typewritermc.realm.formula.HoldsContent
import com.typewritermc.realm.formula.NameAt
import skirout.editor.v1.checking.CheckEvidence
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.diagnostic.Diagnostic

/** Which check occurrences exist. Discovery reads every record through tracked readers, so a new resource reruns it. */
internal data object CheckSubjects : RealmQuery<SubjectDiscovery> {
    context(reads: RealmReads)
    override fun compute(): SubjectDiscovery =
        extensions.discoverSubjects({ tracked() }) { tracked().resourceIds().filter { reads.read(HoldsContent(it)) } }
}

/**
 * One check occurrence's subject. A firewall for reruns and for evidence: a new resource changes [CheckSubjects] and
 * leaves every other subject equal, and evidence does not walk into it, so discovery's reads are no check's evidence.
 */
internal data class SubjectOf(
    val instance: CheckInstanceId,
) : RealmQuery<CheckSubject?> {
    context(reads: RealmReads)
    override fun compute(): CheckSubject? = reads.read(CheckSubjects).subjects.firstOrNull { it.id == instance }
}

/** One check occurrence. The id is the whole key; a pass only asks for ids it discovered at its own revision. */
internal data class CheckRun(
    val instance: CheckInstanceId,
) : RealmQuery<CheckRunResult> {
    context(reads: RealmReads)
    override fun compute(): CheckRunResult {
        val subject = checkNotNull(reads.read(SubjectOf(instance))) { "A check run was read for an unknown instance." }
        val evaluator = CheckEvaluator(RealmCheckInputs()) { resource -> reads.read(ContentFindings(resource)) }
        return evaluator.evaluate(subject, CheckTicket(instance = instance, catalog = generation), tracked())
    }

    /** What this run read at this revision, also through a memo, as its evidence. Which checks exist is not what a check read. */
    context(reads: RealmReads)
    fun evidence(): List<CheckEvidence> = evidence { it is SubjectOf }
}

/** What one run found. It keeps no evidence, because early cutoff could keep it while a value below changed. */
internal data class CheckRunResult(
    val ticket: CheckTicket,
    val outcome: CheckOutcome,
    val findings: List<Diagnostic>,
) {
    fun toFindingSet(
        evidence: List<CheckEvidence>,
        status: FindingStatus,
    ): FindingSet = FindingSet(ticket = ticket, evidence = evidence, outcome = outcome, findings = findings, status = status)

    fun toCheckResult(evidence: List<CheckEvidence>): CheckResult =
        CheckResult(ticket = ticket, outcome = outcome, evidence = evidence, findings = findings)
}

/** The result of a run that failed outside extension code: its failure finding at the subject. */
internal fun CheckSubject.failedRun(
    ticket: CheckTicket,
    failure: Throwable,
): CheckRunResult =
    CheckRunResult(
        ticket = ticket,
        outcome =
            CheckOutcome.FailedWrapper(
                listOf(
                    CheckRunDiagnostics.of(id).error(
                        plan.rule.origin,
                        "check_callback_failed",
                        failure.message ?: failure::class.simpleName.orEmpty(),
                        findingLocation,
                    ),
                ),
            ),
        findings = emptyList(),
    )

/**
 * The services a realm's view store gives its queries: the check runtime's predicates, [limits] on each read, and the
 * formula scopes' name lookup.
 */
fun checkingServices(limits: ViewReadLimits = ViewReadLimits()): RealmServices =
    RealmServices(RealmSelectionPredicateEvaluator(), limits) { at, name -> NameAt(at, name) }
