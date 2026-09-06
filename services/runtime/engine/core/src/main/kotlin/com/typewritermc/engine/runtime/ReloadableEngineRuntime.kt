package com.typewritermc.engine.runtime

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.runtime.DiscoveryDeployment
import com.typewritermc.engine.ActivatedCompiledContent
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.StagedHostedRuntime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Owns the activation scope of a staged discovery deployment and orders compiled content application.
 *
 * Activation runs registrars in list order and starts delivery. Quiescing stops delivery and releases activation
 * resources while retaining discovery and the last content for resume. Final closure also closes discovery.
 * Lifecycle methods and external content application require serialized access.
 */
class ReloadableEngineRuntime(
    deployment: DiscoveryDeployment,
    private val registrars: List<RuntimeRegistrar>,
    private val parentScope: CoroutineScope,
    private val contentGateway: EngineContentGateway? = null,
    private val contentDelivery: EngineContentDelivery? = null,
) : StagedHostedRuntime {
    private val mutableHealth = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = mutableHealth
    private var deployment: DiscoveryDeployment? = deployment
    private var scope: ManagedRuntimeScope? = null
    private var lastContent: ActivatedCompiledContent? = null

    override suspend fun activate() {
        val currentDeployment = checkNotNull(deployment) { "Engine deployment is stopped." }
        check(scope == null) { "Engine deployment is already active." }
        val replacement = ManagedRuntimeScope(parentScope, currentDeployment.prototypes, currentDeployment.facts)
        try {
            with(replacement) {
                registrars.forEach { it.register() }
            }
            lastContent?.let { content -> contentGateway?.apply(content) }
            scope = replacement
            contentDelivery?.start { content -> applyContent(content) }
            mutableHealth.value = RuntimeHealth.Healthy
        } catch (failure: Throwable) {
            runCatching { replacement.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            mutableHealth.value = RuntimeHealth.Unhealthy(failure.message ?: "Engine activation failed.")
            throw failure
        }
    }

    /**
     * Applies content only while active and only if its activation revision exceeds the last successful one.
     *
     * The remembered revision advances after the gateway succeeds. Missing gateways return Unsupported; older or
     * equal revisions return the current activation without reapplying.
     */
    suspend fun applyContent(content: ActivatedCompiledContent): ContentApplicationResult {
        check(scope != null) { "Engine deployment is not active." }
        val current = lastContent
        if (current != null && content.activationRevision <= current.activationRevision) {
            return ContentApplicationResult.Ignored(current.activationRevision, current.content.manifest.digest)
        }
        val gateway = contentGateway ?: return ContentApplicationResult.Unsupported
        gateway.apply(content)
        lastContent = content
        return ContentApplicationResult.Applied(content.activationRevision, content.content.manifest.digest)
    }

    override suspend fun quiesce() {
        contentDelivery?.stop()
        val active = scope ?: return
        scope = null
        active.close()
        mutableHealth.value = RuntimeHealth.Staged
    }

    /**
     * Creates a fresh activation scope, reruns registrars, and reapplies the last accepted content before
     * restarting delivery.
     *
     * Resume requires a quiesced deployment; it is not valid after final closure.
     */
    override suspend fun resume() {
        activate()
    }

    suspend fun stop() {
        quiesce()
        val activeDeployment = deployment
        deployment = null
        activeDeployment?.close()
    }

    override suspend fun close() = stop()

    internal fun ownsDeployment(): Boolean = deployment != null
}
