package com.typewritermc.discovery

/**
 * Owns registered resources without owning the runtime coroutine lifetime.
 *
 * Closure rejects later registrations and attempts each accepted action once in reverse order. Later failures are
 * suppressed on the first failure. Lifecycle owners serialize closure and supply a context in which it can finish.
 */
class RuntimeCleanupOwner {
    private val lock = Any()
    private val actions = mutableListOf<suspend () -> Unit>()
    private var closed = false

    fun own(cleanup: suspend () -> Unit) {
        synchronized(lock) {
            check(!closed) { "Runtime cleanup ownership is closed." }
            actions += cleanup
        }
    }

    fun <Resource : AutoCloseable> own(resource: Resource): Resource = resource.also { own(it::close) }

    suspend fun close() {
        val pending =
            synchronized(lock) {
                if (closed) return
                closed = true
                actions.asReversed().toList().also { actions.clear() }
            }
        val failures = pending.mapNotNull { action -> runCatching { action() }.exceptionOrNull() }
        if (failures.isNotEmpty()) {
            val failure = failures.first()
            failures.drop(1).forEach { later -> if (later !== failure) failure.addSuppressed(later) }
            throw failure
        }
    }
}
