package com.typewritermc.discovery

import kotlinx.coroutines.CoroutineScope

interface RuntimeScope {
    val coroutineScope: CoroutineScope
    val facts: DeploymentFacts

    fun own(cleanup: suspend () -> Unit)

    fun <R : AutoCloseable> own(resource: R): R
}

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
