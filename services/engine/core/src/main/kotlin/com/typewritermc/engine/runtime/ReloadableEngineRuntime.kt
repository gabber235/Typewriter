package com.typewritermc.engine.runtime

import com.typewritermc.discovery.runtime.DiscoveryDeployment
import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.StagedHostedRuntime
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class ReloadableEngineRuntime(
    deployment: DiscoveryDeployment,
    private val registrars: List<RuntimeRegistrar>,
    private val parentScope: CoroutineScope,
    private val contentGateway: EngineContentGateway? = null,
) : StagedHostedRuntime {
    private val mutableHealth = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = mutableHealth
    private var deployment: DiscoveryDeployment? = deployment
    private var scope: ManagedRuntimeScope? = null
    private var lastContentRevision: ContentRevision? = null

    override suspend fun activate() {
        val currentDeployment = checkNotNull(deployment) { "Engine deployment is stopped." }
        check(scope == null) { "Engine deployment is already active." }
        val replacement = ManagedRuntimeScope(parentScope, currentDeployment.prototypes, currentDeployment.facts)
        try {
            with(replacement) {
                registrars.forEach { it.register() }
            }
            lastContentRevision?.let { revision -> contentGateway?.apply(revision) }
            scope = replacement
            mutableHealth.value = RuntimeHealth.Healthy
        } catch (failure: Throwable) {
            runCatching { replacement.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            mutableHealth.value = RuntimeHealth.Unhealthy(failure.message ?: "Engine activation failed.")
            throw failure
        }
    }

    suspend fun applyContent(revision: ContentRevision): ContentApplicationResult {
        check(scope != null) { "Engine deployment is not active." }
        val current = lastContentRevision
        if (current != null && revision.revision <= current.revision) {
            return ContentApplicationResult.Ignored(current.revision)
        }
        val gateway = contentGateway ?: return ContentApplicationResult.Unsupported
        gateway.apply(revision)
        lastContentRevision = revision
        return ContentApplicationResult.Applied(revision.revision)
    }

    override suspend fun quiesce() {
        val active = scope ?: return
        scope = null
        active.close()
        mutableHealth.value = RuntimeHealth.Staged
    }

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
