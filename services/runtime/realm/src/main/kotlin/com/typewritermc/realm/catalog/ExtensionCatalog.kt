package com.typewritermc.realm.catalog

import com.typewritermc.discovery.CollectedDynamics
import com.typewritermc.discovery.DynamicHook
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.formula.CoreFormulas
import com.typewritermc.formula.FormulaFunction
import com.typewritermc.services.libs.utils.closeAll
import skirout.editor.v1.catalog.ConfigurationRecipe

/**
 * What extension code contributes to one code catalog: its check plans, the dynamic hooks it registered at load, the
 * formula functions formulas can call, and the provider retains they need. It is collected once, from that catalog alone, and closed
 * with the catalog's last lease, so a new generation is one install and no reader can mix two generations.
 */
class ExtensionCatalog internal constructor(
    internal val plans: List<CheckPlan>,
    internal val hooks: List<DynamicHook>,
    /** The loaded formula providers' functions and the core functions, by name. */
    internal val functions: Map<String, List<FormulaFunction>>,
    private val leases: List<ProviderLease>,
) : AutoCloseable {
    override fun close() = leases.asReversed().closeAll()
}

/**
 * Collects the extensions of a code catalog, retaining every provider its plans, hooks and functions call into. A
 * collection that fails releases every retain it took, so the next read can try again.
 */
internal fun collectExtensions(
    checks: List<OwnedCheckRecipe>,
    configuration: List<ConfigurationRecipe>,
    dynamics: CollectedDynamics,
    providers: OwnedProviderRegistry,
): ExtensionCatalog {
    val leases = mutableListOf<ProviderLease>()
    return runCatching {
        val plans = collectPlans(checks, configuration, providers, leases)
        val dynamicFailures = dynamicPlans(dynamics, providers, leases)
        val formulas = providers.formulas()
        formulas.map { it.origin }.distinct().forEach { leases += providers.retain(it) }
        ExtensionCatalog(
            plans = plans + dynamicFailures + CheckPlan.Content(CONTENT_RULE),
            hooks = dynamics.hooks,
            functions = (formulas.map { it.function } + CoreFormulas.functions).groupBy { it.name },
            leases = leases,
        )
    }.onFailure { failure -> leases.asReversed().closeAll(failure) }
        .getOrThrow()
}

/**
 * The extensions of one code catalog, collected on first read and closed once with its last lease. A failed
 * collection keeps nothing, so the next read collects again.
 */
internal class CollectedExtensions(
    private val collect: () -> ExtensionCatalog,
) : AutoCloseable {
    private val lock = Any()
    private var collected: ExtensionCatalog? = null
    private var closed = false

    val value: ExtensionCatalog
        get() =
            synchronized(lock) {
                check(!closed) { "The catalog's extensions are closed." }
                collected ?: collect().also { collected = it }
            }

    override fun close() {
        val catalog =
            synchronized(lock) {
                if (closed) return
                closed = true
                collected.also { collected = null }
            }
        catalog?.close()
    }
}
