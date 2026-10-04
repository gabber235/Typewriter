package com.typewritermc.engine.runtime

import com.typewritermc.discovery.DeploymentFacts
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin

/**
 * Owns jobs and cleanup actions for one engine activation.
 *
 * Closure cancels and joins child jobs, then runs cleanup in reverse registration order. Once the closed flag is
 * set, repeated calls return and new ownership registrations fail. Lifecycle and registration access must be
 * serialized; the cleanup list is not synchronized. Cleanup exceptions are collected with later causes suppressed.
 */
class ManagedRuntimeScope(
    parent: CoroutineScope,
    override val facts: DeploymentFacts,
) : com.typewritermc.discovery.RuntimeScope {
    private val job = SupervisorJob(parent.coroutineContext[Job])
    override val coroutineScope = CoroutineScope(parent.coroutineContext + job)
    private val cleanups = mutableListOf<suspend () -> Unit>()
    private var closed = false

    /** Registers cleanup owned by this activation, executed after child jobs and in reverse registration order. */
    override fun own(cleanup: suspend () -> Unit) {
        check(!closed) { "Runtime scope is already closed." }
        cleanups += cleanup
    }

    /** Registers [resource] for closure with the activation and returns the same resource for immediate use. */
    override fun <Resource : AutoCloseable> own(resource: Resource): Resource {
        own { resource.close() }
        return resource
    }

    /**
     * Retires activation work before releasing registered resources.
     *
     * Call from the lifecycle owner rather than a child job of this scope. The caller must provide a context in
     * which suspending shutdown can finish; cancellation during joining can interrupt cleanup.
     */
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
