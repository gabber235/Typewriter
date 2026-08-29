package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.types.TypePrototypeRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin

/**
 * Owns coroutines and resources created during one engine activation.
 *
 * [close] is idempotent. It cancels child coroutines before running cleanup in reverse registration order. Cleanup
 * continues after failures, then throws the first failure with later failures attached as suppressed causes.
 */
class ManagedRuntimeScope(
    parent: CoroutineScope,
    override val prototypes: TypePrototypeRegistry,
    override val facts: DeploymentFacts,
) : com.typewritermc.discovery.RuntimeScope {
    private val job = SupervisorJob(parent.coroutineContext[Job])
    override val coroutineScope = CoroutineScope(parent.coroutineContext + job)
    private val cleanups = mutableListOf<suspend () -> Unit>()
    private var closed = false

    override fun own(cleanup: suspend () -> Unit) {
        check(!closed) { "Runtime scope is already closed." }
        cleanups += cleanup
    }

    override fun <Resource : AutoCloseable> own(resource: Resource): Resource {
        own { resource.close() }
        return resource
    }

    suspend fun close() {
        if (closed) return
        closed = true
        job.cancelAndJoin()
        val failures = mutableListOf<Throwable>()
        cleanups.reversed().forEach { cleanup ->
            runCatching { cleanup() }.exceptionOrNull()?.let(failures::add)
        }
        cleanups.clear()
        if (failures.isNotEmpty()) {
            val failure = failures.first()
            failures.drop(1).forEach(failure::addSuppressed)
            throw failure
        }
    }
}
