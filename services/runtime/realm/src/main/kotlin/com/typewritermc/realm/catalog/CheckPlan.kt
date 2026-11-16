package com.typewritermc.realm.catalog

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.checking.CheckContext
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.RealmChecks
import com.typewritermc.discovery.OwnedCheck
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.runExtension
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin

/**
 * The check plans of one code catalog, adding to [leases] every provider they call into. A provider whose register
 * throws its own failure becomes a registration failure plan instead.
 */
internal fun collectPlans(
    checks: List<OwnedCheckRecipe>,
    configuration: List<ConfigurationRecipe>,
    providers: OwnedProviderRegistry,
    leases: MutableList<ProviderLease>,
): List<CheckPlan> {
    val plans = mutableListOf<CheckPlan>()
    checks.forEach { owned ->
        leases += providers.retain(owned.origin)
        plans += CheckPlan.Simple(RuleId(origin = owned.recipe.owner, localIndex = 0), owned)
    }
    configuration.forEach { recipe ->
        recipe.rules.forEach { rule -> plans += CheckPlan.Portable(rule.id, recipe, rule) }
    }
    providers.checks().forEach { owned ->
        leases += providers.retain(owned.origin)
        val collector = RealmCheckCollector(owned)
        plans +=
            runExtension({
                owned.provider.run { collector.register() }
                collector.plans
            }) { failure -> listOf(registrationFailure(owned.ruleOrigin, "check_registration_failed", failure)) }
    }
    return plans
}

/** The plan that reports a provider whose register threw its own failure, under [origin]. */
internal fun registrationFailure(
    origin: RuleOrigin,
    code: String,
    failure: Throwable,
): CheckPlan.RegistrationFailure {
    val rule = RuleId(origin = origin, localIndex = 0)
    return CheckPlan.RegistrationFailure(
        rule = rule,
        diagnostic =
            Diagnostic(
                id = DiagnosticId(value = "registration:${RuleId.serializer.toJsonCode(rule)}"),
                origin = origin,
                code = code,
                message = failure.message ?: failure::class.simpleName.orEmpty(),
                severity = DiagnosticSeverity.ERROR,
                primary = null,
                related = emptyList(),
            ),
    )
}

private class RealmCheckCollector(
    private val owned: OwnedCheck,
) : RealmChecks {
    val plans = mutableListOf<CheckPlan>()
    private var nextRegistration = 0

    override fun <D> each(
        type: DraftType<D>,
        check: CheckContext.(D) -> Unit,
    ) {
        val rule = RuleId(origin = owned.ruleOrigin, localIndex = nextRegistration++)
        plans += CheckPlan.Each(rule, type, check)
    }

    override fun realm(check: CheckContext.() -> Unit) {
        val rule = RuleId(origin = owned.ruleOrigin, localIndex = nextRegistration++)
        plans += CheckPlan.Realm(rule, check)
    }
}

/** One rule a catalog checks: a plan the realm finds subjects of and runs. */
internal sealed interface CheckPlan {
    val rule: RuleId

    data class Simple(
        override val rule: RuleId,
        val owned: OwnedCheckRecipe,
    ) : CheckPlan

    data class Portable(
        override val rule: RuleId,
        val recipe: ConfigurationRecipe,
        val ownedRule: OwnedRule,
    ) : CheckPlan

    data class Each<D>(
        override val rule: RuleId,
        val type: DraftType<D>,
        val callback: CheckContext.(D) -> Unit,
    ) : CheckPlan {
        fun invoke(
            context: CheckContext,
            binding: DraftBinding,
        ) {
            callback(context, type.bind(binding))
        }
    }

    data class Realm(
        override val rule: RuleId,
        val callback: CheckContext.() -> Unit,
    ) : CheckPlan

    /**
     * The realm's own rules over one resource's content: formula problems, failed hooks and values that no longer fit
     * their schema. One subject per resource that has something of that kind.
     */
    data class Content(
        override val rule: RuleId,
    ) : CheckPlan

    data class RegistrationFailure(
        override val rule: RuleId,
        val diagnostic: Diagnostic,
    ) : CheckPlan

    data class DiscoveryFailure(
        override val rule: RuleId,
        val outcome: CheckOutcome,
        val findings: List<Diagnostic>,
    ) : CheckPlan
}
