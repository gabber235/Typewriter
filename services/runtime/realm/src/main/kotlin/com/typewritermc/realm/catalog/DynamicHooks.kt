package com.typewritermc.realm.catalog

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.discovery.OwnedDynamic
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.formula.DynamicBuilder
import com.typewritermc.formula.Dynamics
import com.typewritermc.discovery.runExtension
import com.typewritermc.types.qualified
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/**
 * One registered hook. It matches like any check subject, so a hook on a parent contract runs for its subtypes in
 * other artifacts, and a hook by definition id runs for every type argument of that definition.
 */
internal class DynamicHook(
    val origin: RuleOrigin,
    val match: ResourceTypeMatch,
    private val dynamic: DynamicBuilder.(DraftBinding) -> Unit,
) {
    /** Runs this hook on the resource [binding] binds; a caller binds through [match] first. */
    fun run(
        builder: DynamicBuilder,
        binding: DraftBinding,
    ) = builder.dynamic(binding)
}

/** The hooks every dynamic provider registered, and a registration failure plan for each provider whose register threw. */
internal class CollectedDynamics(
    val hooks: List<DynamicHook>,
    val failures: List<CheckPlan>,
)

/** Collects the hooks of every dynamic provider, adding to [leases] each provider it calls into. */
internal fun collectDynamics(
    providers: OwnedProviderRegistry,
    leases: MutableList<ProviderLease>,
): CollectedDynamics {
    val hooks = mutableListOf<DynamicHook>()
    val failures = mutableListOf<CheckPlan>()
    providers.dynamics().forEach { owned ->
        leases += providers.retain(owned.origin)
        val collector = DynamicCollector(owned)
        runExtension({
            owned.provider.run { collector.register() }
            hooks += collector.hooks
        }) { failure -> failures += registrationFailure(owned.ruleOrigin, "dynamic_registration_failed", failure) }
    }
    return CollectedDynamics(hooks, failures)
}

private class DynamicCollector(
    private val owned: OwnedDynamic,
) : Dynamics {
    val hooks = mutableListOf<DynamicHook>()

    override fun <D> each(
        type: DraftType<D>,
        dynamic: DynamicBuilder.(D) -> Unit,
    ) {
        hooks += DynamicHook(owned.ruleOrigin, type.match) { binding -> dynamic(type.bind(binding)) }
    }

    override fun each(
        definition: TypeDefinitionId,
        dynamic: DynamicBuilder.(ResourceId) -> Unit,
    ) {
        hooks += DynamicHook(owned.ruleOrigin, ResourceTypeMatch.Definition(definition)) { binding -> dynamic(binding.location.resource) }
    }
}

/**
 * The reserved owner of the realm's content rule. It has the same reserved form as the publication diagnostics' owner,
 * so no provider or configuration rule can share its rule id.
 */
internal val CONTENT_DIAGNOSTIC_TYPE: TypeDefinitionId = TypeDefinitionId.qualified("typewriter", "content")

/** The rule of the realm's content findings. */
internal val CONTENT_RULE: RuleId = RuleId(origin = RuleOrigin(owner = CONTENT_DIAGNOSTIC_TYPE, ordinal = 0), localIndex = 0)
