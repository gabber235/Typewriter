package com.typewritermc.engine.runtime

import com.typewritermc.loader.ReplaceableDeploymentRuntime
import kotlinx.coroutines.CoroutineScope
import java.net.URLClassLoader
import java.time.Instant

class ReloadableEngineRuntime(
    classLoader: URLClassLoader,
    private val plan: EngineActivationPlan,
    private val parentScope: CoroutineScope,
) : ReplaceableDeploymentRuntime {
    private var classLoader: URLClassLoader? = classLoader
    private var scope: ManagedRuntimeScope? = null
    private var lastContentRevision: ContentRevision? = null

    override suspend fun activate() {
        check(classLoader != null) { "Engine deployment is stopped." }
        check(scope == null) { "Engine deployment is already active." }
        val replacement = ManagedRuntimeScope(parentScope)
        try {
            val context = DefaultExtensionActivationContext(replacement, plan.gateways)
            plan.activators.forEach { activator ->
                replacement.own(activator.activate(context))
            }
            lastContentRevision?.let { revision -> plan.contentGateway?.apply(revision) }
            scope = replacement
        } catch (failure: Throwable) {
            runCatching { replacement.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }

    suspend fun applyContent(revision: ContentRevision): ContentApplicationResult {
        check(scope != null) { "Engine deployment is not active." }
        val current = lastContentRevision
        if (current != null && revision.revision <= current.revision) {
            return ContentApplicationResult.Ignored(current.revision)
        }
        val gateway = plan.contentGateway ?: return ContentApplicationResult.Unsupported
        gateway.apply(revision)
        lastContentRevision = revision
        return ContentApplicationResult.Applied(revision.revision)
    }

    override suspend fun quiesce(deadline: Instant) {
        val active = scope ?: return
        scope = null
        active.close()
    }

    override suspend fun resume() {
        activate()
    }

    override suspend fun stop() {
        quiesce(Instant.MAX)
        val activeClassLoader = classLoader
        classLoader = null
        activeClassLoader?.close()
    }

    internal fun ownsClassLoader(): Boolean = classLoader != null
}

sealed interface ContentApplicationResult {
    data class Applied(
        val revision: Long,
    ) : ContentApplicationResult

    data class Ignored(
        val currentRevision: Long,
    ) : ContentApplicationResult

    data object Unsupported : ContentApplicationResult
}
