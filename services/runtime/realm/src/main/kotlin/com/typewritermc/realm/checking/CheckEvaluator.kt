package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.checking.CheckContext
import com.typewritermc.checking.DiagnosticReporter
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.ViewReadHealth
import com.typewritermc.realm.catalog.CheckPlan
import com.typewritermc.realm.formula.ContentFinding
import com.typewritermc.services.libs.utils.runExtension
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Evaluates one check subject over the reads it is given, which record what it read. Its diagnostics are numbered in
 * the order the run reports them, so an equal rerun gives an equal result.
 */
internal class CheckEvaluator(
    private val checkInputs: RealmCheckInputs,
    /** What the content rule found on a resource; the realm reads it through the graph. */
    private val contentFindings: (ResourceId) -> List<ContentFinding>,
) {
    private val expressions = RealmExpressionRuntime()

    fun evaluate(
        subject: CheckSubject,
        ticket: CheckTicket,
        reads: CapturedAuthoringReads,
    ): CheckRunResult {
        val diagnostics = CheckRunDiagnostics.of(subject.id)
        val findings = mutableListOf<Diagnostic>()
        val explicit =
            runExtension({ run(subject, reads, diagnostics, findings::add) }) { failure ->
                CheckOutcome.FailedWrapper(
                    listOf(
                        diagnostics.error(
                            subject.plan.rule.origin,
                            "check_callback_failed",
                            failure.message ?: failure::class.simpleName.orEmpty(),
                            subject.findingLocation,
                        ),
                    ),
                )
            }
        return CheckRunResult(ticket, mergeOutcome(explicit, reads.health().outcome(subject.plan.rule.origin, diagnostics)), findings)
    }

    /** Runs [subject]'s plan, reporting each finding, and returns its outcome when the plan decides one. */
    private fun run(
        subject: CheckSubject,
        reads: CapturedAuthoringReads,
        diagnostics: CheckRunDiagnostics,
        report: (Diagnostic) -> Unit,
    ): CheckOutcome? =
        when (val plan = subject.plan) {
            is CheckPlan.Simple -> {
                val binding =
                    reads.bindOccurrence(subject.location, plan.owned.recipe.owner.owner)
                        ?: return CheckOutcome.IncompleteWrapper("check occurrence is no longer present")
                val evaluation = with(reads) { checkInputs.evaluate(plan.owned.recipe, binding, diagnostics::next) }
                evaluation.findings.forEach(report)
                evaluation.outcome
            }

            is CheckPlan.Portable -> {
                portable(plan, subject, reads, diagnostics, report)
            }

            is CheckPlan.Each<*> -> {
                val binding =
                    reads.bindResource(subject.location, plan.type.match)
                        ?: return CheckOutcome.IncompleteWrapper("check subject is no longer present")
                plan.invoke(context(plan.rule.origin, reads, diagnostics, report), binding)
                null
            }

            is CheckPlan.Realm -> {
                plan.callback(context(plan.rule.origin, reads, diagnostics, report))
                null
            }

            is CheckPlan.RegistrationFailure -> {
                CheckOutcome.FailedWrapper(listOf(plan.diagnostic))
            }

            is CheckPlan.Content -> {
                contentFindings(subject.location.resource).forEach { finding ->
                    report(diagnostics.error(plan.rule.origin, finding.code, finding.message, finding.at, finding.related))
                }
                null
            }

            is CheckPlan.DiscoveryFailure -> {
                plan.findings.forEach(report)
                plan.outcome
            }
        }

    private fun portable(
        plan: CheckPlan.Portable,
        subject: CheckSubject,
        reads: CapturedAuthoringReads,
        diagnostics: CheckRunDiagnostics,
        report: (Diagnostic) -> Unit,
    ): CheckOutcome? {
        val binding = reads.bindOccurrence(subject.ownerLocation, plan.recipe.origin.owner)
        val stillPresent =
            binding != null &&
                reads.matchesRepresentation(binding, plan.recipe.relativePath, plan.recipe.representationCondition) &&
                subject.location in reads.expand(binding.location, plan.recipe.relativePath)
        if (!stillPresent) return CheckOutcome.IncompleteWrapper("portable rule occurrence is no longer present")
        return when (val evaluation = expressions.evaluateBoolean(plan.ownedRule.descriptor.predicate, subject.location, reads)) {
            is Availability.Available -> {
                if (!evaluation.value) report(portableDiagnostic(plan, subject, reads, diagnostics))
                null
            }

            is Availability.Unavailable -> {
                CheckOutcome.NeedsInputWrapper(evaluation.locations)
            }

            is Availability.Failed -> {
                CheckOutcome.FailedWrapper(
                    listOf(
                        Diagnostic(
                            id = diagnostics.next(),
                            origin = plan.ownedRule.id.origin,
                            code = evaluation.diagnostic.failure.value,
                            message = evaluation.diagnostic.message,
                            severity = DiagnosticSeverity.ERROR,
                            primary = evaluation.diagnostic.locations.firstOrNull() ?: subject.location,
                            related = evaluation.diagnostic.locations.drop(1),
                        ),
                    ),
                )
            }
        }
    }

    private fun context(
        origin: RuleOrigin,
        reads: CapturedAuthoringReads,
        diagnostics: CheckRunDiagnostics,
        sink: (Diagnostic) -> Unit,
    ): CheckContext =
        CheckContext.create(
            reads,
            object : DiagnosticReporter {
                override fun report(diagnostic: Diagnostic) = sink(diagnostic)
            },
            diagnosticFactory(origin, diagnostics),
        )

    private fun diagnosticFactory(
        origin: RuleOrigin,
        diagnostics: CheckRunDiagnostics,
    ): (String, ValueLocation, List<ValueLocation>) -> Diagnostic =
        { message, at, related -> diagnostics.error(origin, "realm.check", message, at, related) }

    private fun portableDiagnostic(
        plan: CheckPlan.Portable,
        subject: CheckSubject,
        reads: CapturedAuthoringReads,
        diagnostics: CheckRunDiagnostics,
    ): Diagnostic {
        val targets =
            plan.ownedRule.diagnostic.targets
                .flatMap { target ->
                    if (target == plan.recipe.relativePath) listOf(subject.location) else reads.expand(subject.ownerLocation, target)
                }.distinct()
        return Diagnostic(
            id = diagnostics.next(),
            origin = plan.ownedRule.id.origin,
            code = plan.ownedRule.diagnostic.code,
            message = plan.ownedRule.diagnostic.message,
            severity = plan.ownedRule.diagnostic.severity,
            primary = targets.firstOrNull() ?: subject.location,
            related = targets.drop(1),
        )
    }
}

/** The outcome these reads give a run; each failed read becomes an error numbered by [diagnostics]. */
internal fun ViewReadHealth.outcome(
    origin: RuleOrigin,
    diagnostics: CheckRunDiagnostics,
): CheckOutcome =
    when {
        incomplete.isNotEmpty() -> {
            CheckOutcome.IncompleteWrapper(incomplete.joinToString())
        }

        failures.isNotEmpty() -> {
            CheckOutcome.FailedWrapper(
                failures.map { failure ->
                    diagnostics.error(
                        origin,
                        failure.failure.value,
                        failure.message,
                        at = failure.locations.firstOrNull(),
                        related = failure.locations.drop(1),
                    )
                },
            )
        }

        missing.isNotEmpty() -> {
            CheckOutcome.NeedsInputWrapper(missing)
        }

        else -> {
            CheckOutcome.FINISHED
        }
    }

private fun mergeOutcome(
    explicit: CheckOutcome?,
    tracked: CheckOutcome,
): CheckOutcome =
    when {
        explicit is CheckOutcome.IncompleteWrapper -> explicit
        tracked is CheckOutcome.IncompleteWrapper -> tracked
        explicit is CheckOutcome.FailedWrapper -> explicit
        tracked is CheckOutcome.FailedWrapper -> tracked
        explicit is CheckOutcome.NeedsInputWrapper -> explicit
        tracked is CheckOutcome.NeedsInputWrapper -> tracked
        explicit != null -> explicit
        else -> tracked
    }
