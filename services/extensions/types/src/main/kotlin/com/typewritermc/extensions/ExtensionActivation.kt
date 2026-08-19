package com.typewritermc.extensions

import kotlinx.coroutines.CoroutineScope
import kotlin.reflect.KClass

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterActivator(
    val id: String,
)

interface ExtensionRuntimeScope {
    val lifetime: CoroutineScope

    fun own(cleanup: suspend () -> Unit)

    fun <Resource : AutoCloseable> own(resource: Resource): Resource
}

interface ExtensionActivationContext {
    val scope: ExtensionRuntimeScope

    fun <Gateway : Any> gateway(type: KClass<Gateway>): Gateway
}

fun interface ExtensionActivation : AutoCloseable {
    override fun close()
}

interface ExtensionActivator {
    fun activate(context: ExtensionActivationContext): ExtensionActivation
}
