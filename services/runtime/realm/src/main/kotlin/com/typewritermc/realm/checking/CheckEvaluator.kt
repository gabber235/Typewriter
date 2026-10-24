package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.root
import com.typewritermc.checking.CheckContext
import com.typewritermc.checking.DiagnosticReporter
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.authoring.ViewReadHealth
import com.typewritermc.services.libs.utils.rethrowExceptional
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.atomic.AtomicLong

/**
 * Evaluates one check subject against a retained authored snapshot and records the reads it depends on.
 *
 * The owning [RealmCheckRuntime] supplies the reads factory and the execution and diagnostic id sequences.
 */
internal class CheckEvaluator(
    private val views: AuthoringViewStore,
    private val checkInputs: RealmCheckInputs,
    private val captureReads: (AuthoringLease) -> CapturedAuthoringReads,
    private val nextExecution: AtomicLong,
    private val diagnostics: CheckDiagnosticIds,
) {
    private val expressions = RealmExpressionRuntime()

    fun evaluate(
        catalog: ActiveCatalog,
        subject: CheckSubject,
        target: CheckAdmissionTarget,
        ticket: CheckTicket? = null,
        suppliedLease: AuthoringLease? = null,
    ): CheckResult {
        val lease = suppliedLease ?: views.retain((target as CheckAdmissionTarget.CapturedAcceptance).view.readContext)
        val actualTicket =
            ticket ?: CheckTicket(
                instance = subject.id,
                incarnation = catalog.incarnation,
                execution = CheckExecutionId(value = "capture:${nextExecution.getAndIncrement()}"),
                catalog =
                    lease.root.catalog.generation,
            )
        val reads = captureReads(lease)
        val findings = mutableListOf<Diagnostic>()
        var explicitOutcome: CheckOutcome? = null
        return try {
            try {
                when (val plan = subject.plan) {
                    is CheckPlan.Simple -> {
                        val binding = reads.bindOccurrence(subject.location, plan.owned.recipe.owner.owner)
                        if (binding == null) {
                            explicitOutcome = CheckOutcome.IncompleteWrapper("check occurrence is no longer present")
                        } else {
                            val evaluation = with(reads) { checkInputs.evaluate(plan.owned.recipe, binding) }
                            explicitOutcome = evaluation.outcome
                            findings += evaluation.findings
                        }
                    }

                    is CheckPlan.Portable -> {
                        val binding = reads.bindOccurrence(subject.ownerLocation, plan.recipe.origin.owner)
                        val stillPresent =
                            binding != null &&
                                reads.matchesRepresentation(binding, plan.recipe.relativePath, plan.recipe.representationCondition) &&
                                subject.location in reads.expand(binding.location, plan.recipe.relativePath)
                        if (!stillPresent) {
                            explicitOutcome = CheckOutcome.IncompleteWrapper("portable rule occurrence is no longer present")
                        } else {
                            when (
                                val evaluation =
                                    expressions.evaluateBoolean(
                                        plan.ownedRule.descriptor.predicate,
                                        subject.location,
                                        reads,
                                    )
                            ) {
                                is Availability.Available -> {
                                    if (!evaluation.value) findings += portableDiagnostic(plan, subject, reads)
                                }

                                is Availability.Unavailable -> {
                                    explicitOutcome = CheckOutcome.NeedsInputWrapper(evaluation.locations)
                                }

                                is Availability.Failed -> {
                                    explicitOutcome =
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
                    }

                    is CheckPlan.Each<*> -> {
                        val binding = reads.bindResource(subject.location, plan.type.match)
                        if (binding == null) {
                            explicitOutcome = CheckOutcome.IncompleteWrapper("check subject is no longer present")
                        } else {
                            val reporter =
                                object : DiagnosticReporter {
                                    override fun report(diagnostic: Diagnostic) {
                                        findings += diagnostic
                                    }
                                }
                            val context = CheckContext.create(reads, reporter, diagnosticFactory(plan.rule.origin))
                            plan.invoke(context, binding)
                        }
                    }

                    is CheckPlan.Realm -> {
                        val reporter =
                            object : DiagnosticReporter {
                                override fun report(diagnostic: Diagnostic) {
                                    findings += diagnostic
                                }
                            }
                        val context = CheckContext.create(reads, reporter, diagnosticFactory(plan.rule.origin))
                        plan.callback(context)
                    }

                    is CheckPlan.RegistrationFailure -> {
                        explicitOutcome = CheckOutcome.FailedWrapper(listOf(plan.diagnostic))
                    }

                    is CheckPlan.DiscoveryFailure -> {
                        plan.observed.forEach(reads::observeInput)
                        explicitOutcome = plan.outcome
                        findings += plan.findings
                    }
                }
            } catch (failure: Exception) {
                failure.rethrowExceptional()
                explicitOutcome =
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
            val outcome = mergeOutcome(explicitOutcome, reads.health().outcome(subject.plan.rule.origin))
            CheckResult(ticket = actualTicket, outcome = outcome, expectations = reads.observations(), findings = findings)
        } finally {
            if (suppliedLease == null) lease.close()
        }
    }

    private fun diagnosticFactory(origin: RuleOrigin): (String, ValueLocation, List<ValueLocation>) -> Diagnostic =
        { message, at, related -> diagnostics.error(origin, "realm.check", message, at, related) }

    private fun portableDiagnostic(
        plan: CheckPlan.Portable,
        subject: CheckSubject,
        reads: CapturedAuthoringReads,
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

internal fun ViewReadHealth.outcome(origin: RuleOrigin): CheckOutcome =
    when {
        incomplete.isNotEmpty() -> {
            CheckOutcome.IncompleteWrapper(incomplete.joinToString())
        }

        failures.isNotEmpty() -> {
            CheckOutcome.FailedWrapper(
                failures.mapIndexed { index, failure ->
                    Diagnostic(
                        id = DiagnosticId(value = "evaluation:$index:${failure.hashCode()}"),
                        origin = origin,
                        code = failure.failure.value,
                        message = failure.message,
                        severity = DiagnosticSeverity.ERROR,
                        primary = failure.locations.firstOrNull(),
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
