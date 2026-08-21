package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import kotlin.reflect.KClass

/**
 * Exposes the runtime contracts that generated extension activators may request.
 *
 * Exactly one gateway may satisfy a requested type. [require] fails for missing or ambiguous gateways so an invalid
 * deployment is rejected during activation instead of failing later during execution.
 */
class EngineGatewayRegistry(
    gateways: Collection<Any>,
) {
    private val gateways = gateways.toList()

    fun <Gateway : Any> require(type: KClass<Gateway>): Gateway {
        val matches = gateways.filter(type::isInstance)
        check(matches.size <= 1) { "Multiple engine gateways implement: ${type.qualifiedName}" }
        val gateway = matches.singleOrNull() ?: error("Engine gateway is not available: ${type.qualifiedName}")
        @Suppress("UNCHECKED_CAST")
        return gateway as Gateway
    }
}

internal class DefaultExtensionActivationContext(
    override val scope: RuntimeScope,
    private val gateways: EngineGatewayRegistry,
) : ExtensionActivationContext {
    override fun <Gateway : Any> gateway(type: KClass<Gateway>): Gateway = gateways.require(type)
}

/** Applies ordered Realm content revisions without replacing extension code or its classloader. */
fun interface EngineContentGateway {
    suspend fun apply(revision: ContentRevision)
}

/**
 * Carries one immutable content snapshot assigned by a Realm.
 *
 * Revisions are positive and monotonic within one deployment. The caller retains ownership of [payload] and must not
 * mutate it after construction.
 */
data class ContentRevision(
    val revision: Long,
    val payload: ByteArray,
) {
    init {
        require(revision >= 1) { "Content revision must be positive." }
    }

    override fun equals(other: Any?): Boolean =
        other is ContentRevision && revision == other.revision && payload.contentEquals(other.payload)

    override fun hashCode(): Int = 31 * revision.hashCode() + payload.contentHashCode()
}

/**
 * Describes everything needed to activate one staged engine deployment.
 *
 * Activators run in list order and are released in reverse order. [contentGateway] is absent when the engine does not
 * support content updates without code replacement.
 */
data class EngineActivationPlan(
    val activators: List<ExtensionActivator>,
    val gateways: EngineGatewayRegistry,
    val contentGateway: EngineContentGateway? = null,
)
