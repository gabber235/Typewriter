package com.typewritermc.engine.runtime

import com.typewritermc.extensions.ExtensionRuntimeScope
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin

interface RuntimeScope : ExtensionRuntimeScope

class ManagedRuntimeScope(
    parent: CoroutineScope,
) : RuntimeScope {
    private val job = SupervisorJob(parent.coroutineContext[Job])
    override val lifetime = CoroutineScope(parent.coroutineContext + job)
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
