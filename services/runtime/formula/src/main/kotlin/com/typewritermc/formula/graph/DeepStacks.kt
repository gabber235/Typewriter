package com.typewritermc.formula.graph

import java.util.concurrent.Callable
import java.util.concurrent.ExecutionException
import java.util.concurrent.Executors
import java.util.concurrent.ThreadFactory

/**
 * Threads with a large stack, for recursion whose depth content decides, such as a chain of queries. The rustc query
 * system does the same with ensure_sufficient_stack.
 *
 * Process wide by design, like Dispatchers.Default: a cached pool of daemon threads that end after 60 seconds idle, so
 * it is empty when no deep chain runs, nothing owns or closes it, and a restart leaves nothing running. Code that runs
 * here must not rely on thread locals.
 */
object DeepStacks {
    private const val STACK_BYTES = 64L shl 20

    private val onPool = ThreadLocal.withInitial { false }
    private val base =
        Thread
            .ofPlatform()
            .name("graph-stack-", 0)
            .stackSize(STACK_BYTES)
            .daemon(true)
            .factory()
    private val threads =
        ThreadFactory { task ->
            base.newThread {
                onPool.set(true)
                task.run()
            }
        }
    private val pool = Executors.newCachedThreadPool(threads)

    /** True on one of the pool's threads. */
    fun isCurrent(): Boolean = onPool.get()

    /** Runs [body] on a fresh large stack and waits for it. Its failure crosses unchanged. */
    fun <T> run(body: () -> T): T {
        val task = pool.submit(Callable { body() })
        try {
            return task.get()
        } catch (wrapped: ExecutionException) {
            throw wrapped.cause ?: wrapped
        } catch (interrupted: InterruptedException) {
            // The caller stopped waiting, so the deep segment stops too.
            task.cancel(true)
            Thread.currentThread().interrupt()
            throw interrupted
        }
    }
}
