package com.typewritermc.discovery

import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.CoroutineScope

/**
 * Gives extension code access to the current activation and a place to register owned resources.
 *
 * Launch activation work in [coroutineScope] and register cleanup with [own] so the runtime can release it when
 * the activation ends. [prototypes] and [facts] belong to this deployment. Implementations define cleanup ordering
 * and synchronization; callers must not assume the scope survives a reload.
 */
interface RuntimeScope {
    val coroutineScope: CoroutineScope
    val prototypes: TypePrototypeRegistry
    val facts: DeploymentFacts

    /**
     * Transfers responsibility for invoking [cleanup] to the runtime scope.
     *
     * Register immediately after acquisition. The cleanup must release only resources owned by this activation; it
     * must not shut down shared host services.
     */
    fun own(cleanup: suspend () -> Unit)

    /**
     * Registers [resource] for closure and returns the same instance for convenient initialization.
     *
     * Ownership transfers to this scope; do not independently close the resource while activation code still uses
     * it.
     */
    fun <Resource : AutoCloseable> own(resource: Resource): Resource
}

/**
 * Installs extension behavior for one runtime activation.
 *
 * Implement [register] using the contextual [RuntimeScope] for jobs, prototypes, facts, and resource cleanup. A
 * later activation may call registration again with a fresh scope, so do not retain activation resources globally.
 */
interface RuntimeRegistrar {
    context(scope: RuntimeScope)
    suspend fun register()
}

/**
 * Makes a registrar discoverable through generated metadata and dependency injection bindings.
 *
 * The flags select which discovery domains receive the registrar. Execution is enabled by default; Realm
 * registration must be requested explicitly. The annotation is retained in binaries for tooling.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRegistrar(
    val id: String,
    val realm: Boolean = false,
    val execution: Boolean = true,
)
