package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionActivationContext
import com.typewritermc.extensions.ExtensionActivator
import kotlin.reflect.KClass

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

fun interface EngineContentGateway {
    suspend fun apply(revision: ContentRevision)
}

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

data class EngineActivationPlan(
    val activators: List<ExtensionActivator>,
    val gateways: EngineGatewayRegistry,
    val contentGateway: EngineContentGateway? = null,
)
