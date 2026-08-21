package com.typewritermc.extensions

import kotlinx.coroutines.CoroutineScope
import kotlin.reflect.KClass

/**
 * Marks an extension activator for compile time discovery by the extension code generator.
 *
 * The identifier must be unique within one generated source set. Discovery is recorded in the extension manifest, so
 * runtime loading never scans classes dynamically.
 */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterActivator(
    val id: String,
)

/**
 * Owns every resource created while one extension activation is live.
 *
 * Activators must register cleanup immediately after acquiring a resource. Cleanup runs in reverse ownership order when
 * activation fails, the deployment is replaced, or the host stops. Coroutines launched in [lifetime] are cancelled with
 * the activation.
 */
interface ExtensionRuntimeScope {
    val lifetime: CoroutineScope

    fun own(cleanup: suspend () -> Unit)

    fun <Resource : AutoCloseable> own(resource: Resource): Resource
}

/**
 * Gives an activator access to its owned lifetime and the gateways provided by its selected runtime target.
 *
 * [gateway] fails when the deployment does not provide the requested contract. Extensions should request only gateways
 * guaranteed by their declared engine target and derived capabilities.
 */
interface ExtensionActivationContext {
    val scope: ExtensionRuntimeScope

    fun <Gateway : Any> gateway(type: KClass<Gateway>): Gateway
}

/**
 * Represents the live effect of one successful extension activation.
 *
 * Closing the activation releases activator specific behavior. Resources registered with [ExtensionRuntimeScope] remain
 * owned by the runtime scope and are closed by that scope.
 */
fun interface ExtensionActivation : AutoCloseable {
    override fun close()
}

/**
 * Creates one target specific extension activation from generated manifest metadata.
 *
 * Activation must either return a fully usable [ExtensionActivation] or throw. The runtime cleans the partial scope when
 * activation throws, which keeps the currently active deployment available for rollback.
 */
interface ExtensionActivator {
    fun activate(context: ExtensionActivationContext): ExtensionActivation
}
