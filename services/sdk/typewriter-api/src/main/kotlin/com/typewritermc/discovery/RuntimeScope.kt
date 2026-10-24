package com.typewritermc.discovery

import kotlinx.coroutines.CoroutineScope

/**
 * Supplies an activation's coroutine lifetime, deployment facts, and resource ownership to runtime registrars.
 *
 * Registrars launch ongoing work in [coroutineScope] and transfer cleanup to [own]. The concrete runtime owns
 * shutdown and decides when jobs stop relative to cleanup; retaining a generated provider does not keep this scope alive.
 */
interface RuntimeScope {
    val coroutineScope: CoroutineScope
    val facts: DeploymentFacts

    fun own(cleanup: suspend () -> Unit)

    fun <R : AutoCloseable> own(resource: R): R
}

/** Installs contributed runtime behavior into the supplied activation scope after discovery has selected its domain. */
interface RuntimeRegistrar {
    context(scope: RuntimeScope)
    suspend fun register()
}

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
annotation class TypewriterRegistrar(
    val id: String,
    val realm: Boolean = false,
    val execution: Boolean = true,
)
