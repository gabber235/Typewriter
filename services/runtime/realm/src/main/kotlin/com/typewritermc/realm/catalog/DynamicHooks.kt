package com.typewritermc.realm.catalog

import com.typewritermc.discovery.CollectedDynamics
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.types.qualified
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId


/**
 * The plans for what load rejected among the dynamic providers' registrations, adding to [leases] each provider whose
 * hooks and binds the catalog may call into.
 */
internal fun dynamicPlans(
    dynamics: CollectedDynamics,
    providers: OwnedProviderRegistry,
    leases: MutableList<ProviderLease>,
): List<CheckPlan> {
    providers.dynamics().forEach { owned -> leases += providers.retain(owned.origin) }
    return dynamics.failures.map { failure -> registrationFailure(failure.provider.ruleOrigin, failure.code, failure.cause) }
}

/**
 * The reserved owner of the realm's content rule. It has the same reserved form as the publication diagnostics' owner,
 * so no provider or configuration rule can share its rule id.
 */
internal val CONTENT_DIAGNOSTIC_TYPE: TypeDefinitionId = TypeDefinitionId.qualified("typewriter", "content")

/** The rule of the realm's content findings. */
internal val CONTENT_RULE: RuleId = RuleId(origin = RuleOrigin(owner = CONTENT_DIAGNOSTIC_TYPE, ordinal = 0), localIndex = 0)
