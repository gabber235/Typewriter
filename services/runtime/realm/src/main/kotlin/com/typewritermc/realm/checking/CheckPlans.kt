package com.typewritermc.realm.checking

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.root
import com.typewritermc.checking.CheckContext
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.RealmChecks
import com.typewritermc.discovery.OwnedCheck
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.services.libs.utils.closeAll
import com.typewritermc.services.libs.utils.rethrowExceptional
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RuleId

/** Collects the check plans of [snapshot]'s catalog, retaining every provider they call into. */
internal fun collectCatalog(
    snapshot: AuthoringLease,
    incarnation: String,
    diagnostics: CheckDiagnosticIds,
): ActiveCatalog {
    val root = snapshot.root
    val leases = mutableListOf<ProviderLease>()
    val plans = mutableListOf<CheckPlan>()
    try {
        root.catalog.checks.forEach { owned ->
            leases += root.catalog.providers.retain(owned.origin)
            plans += CheckPlan.Simple(RuleId(origin = owned.recipe.owner, localIndex = 0), owned)
        }
        root.catalog.configuration.forEach { recipe ->
            recipe.rules.forEach { rule -> plans += CheckPlan.Portable(rule.id, recipe, rule) }
        }
        root.catalog.providers.checks().forEach { owned ->
            leases += root.catalog.providers.retain(owned.origin)
            val collector = RealmCheckCollector(owned)
            try {
                owned.provider.run { collector.register() }
                plans += collector.plans
            } catch (failure: Exception) {
                failure.rethrowExceptional()
                plans +=
                    CheckPlan.RegistrationFailure(
                        rule = RuleId(origin = owned.ruleOrigin, localIndex = 0),
                        diagnostic =
                            diagnostics.error(
                                owned.ruleOrigin,
                                "check_registration_failed",
                                failure.message ?: failure::class.simpleName.orEmpty(),
                                at = null,
                            ),
                    )
            }
        }
        return ActiveCatalog(root.catalog.generation, incarnation, plans, leases, snapshot)
    } catch (failure: Throwable) {
        leases.asReversed().closeAll(failure)
        throw failure
    }
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

internal class ActiveCatalog(
    val generation: CatalogGeneration,
    val incarnation: String,
    val plans: List<CheckPlan>,
    private val providerLeases: List<ProviderLease>,
    val snapshot: AuthoringLease,
) : AutoCloseable {
    private val lock = Any()
    private var references = 1
    private var closeRequested = false

    fun retain(): ProviderLease =
        synchronized(lock) {
            check(references > 0) { "Check catalog is closed." }
            references += 1
            ActiveCatalogLease(this)
        }

    override fun close() {
        release(owner = true)
    }

    private fun release(owner: Boolean) {
        val releaseResources =
            synchronized(lock) {
                if (owner) {
                    if (closeRequested) return
                    closeRequested = true
                }
                check(references > 0) { "Check catalog reference count is invalid." }
                references -= 1
                references == 0
            }
        if (releaseResources) (providerLeases.asReversed() + snapshot).closeAll()
    }

    private class ActiveCatalogLease(
        private var catalog: ActiveCatalog?,
    ) : ProviderLease {
        override fun close() {
            val current = synchronized(this) { catalog.also { catalog = null } } ?: return
            current.release(owner = false)
        }
    }
}

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

    data class RegistrationFailure(
        override val rule: RuleId,
        val diagnostic: Diagnostic,
    ) : CheckPlan

    data class DiscoveryFailure(
        override val rule: RuleId,
        val outcome: CheckOutcome,
        val findings: List<Diagnostic>,
        val observed: List<InputIdentity>,
    ) : CheckPlan
}
