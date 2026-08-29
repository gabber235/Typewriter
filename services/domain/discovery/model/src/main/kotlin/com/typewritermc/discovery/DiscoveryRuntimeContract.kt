package com.typewritermc.discovery

import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.CoroutineScope

interface RuntimeScope {
    val coroutineScope: CoroutineScope
    val prototypes: TypePrototypeRegistry
    val facts: DeploymentFacts

    fun own(cleanup: suspend () -> Unit)

    fun <Resource : AutoCloseable> own(resource: Resource): Resource
}

interface RuntimeRegistrar {
    context(scope: RuntimeScope)
    suspend fun register()
}

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRegistrar(
    val id: String,
    val realm: Boolean = false,
    val execution: Boolean = true,
)
