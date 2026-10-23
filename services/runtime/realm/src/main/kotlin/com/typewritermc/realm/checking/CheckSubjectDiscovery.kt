package com.typewritermc.realm.checking

import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.reason
import com.typewritermc.realm.authoring.AuthoringLease
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** Discovers the current subjects of every plan in this catalog over [lease]. */
internal fun ActiveCatalog.discoverSubjects(
    lease: AuthoringLease,
    evaluator: CheckEvaluator,
): SubjectDiscovery {
    if (lease.root.catalog.generation != generation) return SubjectDiscovery(emptyList(), emptySet())
    val subjects = mutableListOf<CheckSubject>()
    val incompleteRules = linkedSetOf<RuleId>()
    plans.forEach { plan ->
        val reads = evaluator.reads(lease)
        subjects +=
            when (plan) {
                is CheckPlan.Simple -> {
                    reads.discoverOccurrences(plan.owned.recipe.owner.owner).map { binding ->
                        plan.subject(binding.location)
                    }
                }

                is CheckPlan.Portable -> {
                    reads.discoverOccurrences(plan.recipe.origin.owner).flatMap { binding ->
                        if (!reads.matchesRepresentation(binding, plan.recipe.relativePath, plan.recipe.representationCondition)) {
                            emptyList()
                        } else {
                            reads.expand(binding.location, plan.recipe.relativePath).map { location ->
                                plan.subject(location, binding.location)
                            }
                        }
                    }
                }

                is CheckPlan.Each<*> -> {
                    reads.discoverResources(plan.type).map { binding -> plan.subject(binding.location) }
                }

                is CheckPlan.Realm -> {
                    listOf(plan.subject(REALM_SUBJECT_KEY))
                }

                is CheckPlan.RegistrationFailure -> {
                    listOf(plan.subject(REALM_SUBJECT_KEY))
                }

                is CheckPlan.DiscoveryFailure -> {
                    emptyList()
                }
            }
        val outcome = reads.health().outcome(plan.rule.origin)
        if (outcome != CheckOutcome.FINISHED) {
            incompleteRules += plan.rule
            val findings =
                if (outcome is CheckOutcome.IncompleteWrapper) {
                    listOf(
                        evaluator.diagnostic(
                            plan.rule.origin,
                            "check_discovery_incomplete",
                            outcome.reason,
                            at = null,
                        ),
                    )
                } else {
                    emptyList()
                }
            subjects +=
                CheckPlan
                    .DiscoveryFailure(
                        rule = plan.rule,
                        outcome = outcome,
                        findings = findings,
                        observed = reads.observations().flatMap { it.dependencies() },
                    ).subject(DISCOVERY_SUBJECT_KEY)
        }
    }
    return SubjectDiscovery(subjects, incompleteRules)
}

internal data class SubjectDiscovery(
    val subjects: List<CheckSubject>,
    val incompleteRules: Set<RuleId>,
)

/**
 * One scheduled rule occurrence. [location] keys the check instance on the wire, where realm-wide
 * subjects use the reserved [REALM_SUBJECT_KEY] and [DISCOVERY_SUBJECT_KEY] because the check
 * instance contract requires a location.
 */
internal data class CheckSubject(
    val plan: CheckPlan,
    val location: ValueLocation,
    val ownerLocation: ValueLocation = location,
) {
    val id: CheckInstanceId = CheckInstanceId(rule = plan.rule, location = location)

    /** Location findings for this subject anchor to; realm-wide subjects have none. */
    val findingLocation: ValueLocation?
        get() =
            when (plan) {
                is CheckPlan.Simple, is CheckPlan.Portable, is CheckPlan.Each<*> -> location
                is CheckPlan.Realm, is CheckPlan.RegistrationFailure, is CheckPlan.DiscoveryFailure -> null
            }
}

private fun CheckPlan.subject(location: ValueLocation): CheckSubject = CheckSubject(this, location)

private fun CheckPlan.subject(
    location: ValueLocation,
    ownerLocation: ValueLocation,
): CheckSubject = CheckSubject(this, location, ownerLocation)

private val REALM_SUBJECT_KEY = ValueLocation.of(ResourceId(value = "typewriter.realm"))
private val DISCOVERY_SUBJECT_KEY = ValueLocation.of(ResourceId(value = "typewriter.discovery"), ValuePath.root.field("subjects"))
