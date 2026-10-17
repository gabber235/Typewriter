package com.typewritermc.engine.runtime

import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.scripting.RuntimeMemberSignature
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
    deployment: GeneratedProviderDeployment,
    private val registrars: List<RuntimeRegistrar>,
    private val parentScope: CoroutineScope,
    private val implementationToken: String,
    private val enforceImplementationCompatibility: Boolean = true,
    private val runtimeSignatures: Set<RuntimeMemberSignature>,
    private val contentGateway: EngineContentGateway? = null,
    private val contentDelivery: EngineContentDelivery? = null,
) : StagedHostedRuntime {
    private val mutableHealth = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = mutableHealth
    private var deployment: GeneratedProviderDeployment? = deployment
    private var scope: ManagedRuntimeScope? = null
    private var lastContent: LoadedPublishedContent? = null

    override suspend fun activate() {
        val currentDeployment = checkNotNull(deployment) { "Engine deployment is stopped." }
        check(scope == null) { "Engine deployment is already active." }
        val replacement = ManagedRuntimeScope(parentScope, currentDeployment.facts)
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

    /** Applies a current descriptor delivered by the serialized content worker. */
    suspend fun applyContent(content: LoadedPublishedContent): ContentApplicationResult {
        check(scope != null) { "Engine deployment is not active." }
        if (enforceImplementationCompatibility) {
            require(content.descriptor.implementationToken == implementationToken) {
                "Compiled content targets a different engine implementation."
            }
        }
        require(content.descriptor.runtimeSignatures == runtimeSignatures) {
            "Compiled content requires a different runtime member signature set."
        }
        val current = lastContent
        if (current?.descriptor?.publication == content.descriptor.publication) {
            return ContentApplicationResult.Unchanged(current.descriptor.publication)
        }
        val gateway = contentGateway ?: return ContentApplicationResult.Unsupported
        gateway.apply(content)
        lastContent = content
        return ContentApplicationResult.Applied(content.descriptor.publication)
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

    /** Permanently closes the active scope and discovery deployment; this runtime cannot be resumed afterward. */
    suspend fun stop() {
        quiesce()
        val activeDeployment = deployment
        deployment = null
        activeDeployment?.close()
    }

    override suspend fun close() = stop()

    internal fun ownsDeployment(): Boolean = deployment != null
}
