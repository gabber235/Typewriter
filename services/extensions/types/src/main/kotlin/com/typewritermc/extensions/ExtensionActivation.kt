package com.typewritermc.extensions

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterActivator(
    val id: String,
)

interface ExtensionActivationContext

fun interface ExtensionActivation : AutoCloseable {
    override fun close()
}

interface ExtensionActivator {
    fun activate(context: ExtensionActivationContext): ExtensionActivation
}
