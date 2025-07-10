package com.typewritermc.core.utils

import kotlinx.coroutines.*
import org.jetbrains.annotations.ApiStatus
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.util.concurrent.SynchronousQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import kotlin.coroutines.CoroutineContext

@ApiStatus.NonExtendable
@ApiStatus.Internal
abstract class TypewriterDispatcher(
    private val delegate: CoroutineContext
) : CoroutineDispatcher(), KoinComponent {
    private val isEnabled by inject<Boolean>(named("isEnabled"))

    override fun isDispatchNeeded(context: CoroutineContext): Boolean {
        return isEnabled && delegate[CoroutineDispatcher]!!.isDispatchNeeded(context)
    }

    override fun dispatch(context: CoroutineContext, block: Runnable) {
        if (!isDispatchNeeded(context)) return Dispatchers.Unconfined.dispatch(context, block)
        return delegate[CoroutineDispatcher]!!.dispatch(context, block)
    }
}

/**
 * The maximum number of platform threads allowed in the pool.
 *
 * [MAX_PLATFORM_THREADS] + [MAX_VIRTUAL_THREADS] = The maximum number of threads in the pool.
 *
 * All platform threads in the pool are [daemon threads][Thread.setDaemon]
 *
 * @see Thread
 */
val MAX_PLATFORM_THREADS = Runtime.getRuntime().availableProcessors() * 2

/**
 * The maximum number of virtual threads allowed in the pool.
 *
 * [MAX_PLATFORM_THREADS] + [MAX_VIRTUAL_THREADS] = The maximum number of threads in the pool.
 *
 * @see Thread
 * @see VirtualThread
 */
val MAX_VIRTUAL_THREADS = Runtime.getRuntime().availableProcessors() * 10

/**
 * The number of threads that are always present in the [pool][CachedThreadPoolDispatcher].
 *
 * If [MAX_PLATFORM_THREADS] is less than the [CORE_POOL_SIZE], then virtual threads will be in the core pool.
 *
 * @see ThreadPoolExecutor.corePoolSize
 */
const val CORE_POOL_SIZE = 6

@OptIn(ExperimentalStdlibApi::class)
private object CachedThreadPoolDispatcher : TypewriterDispatcher(
    run {
        // threads won't be created until this is initialized.
        lateinit var pool: ThreadPoolExecutor

        pool = ThreadPoolExecutor(
            CORE_POOL_SIZE,
            MAX_VIRTUAL_THREADS + MAX_PLATFORM_THREADS,
            60L,
            TimeUnit.SECONDS,
            SynchronousQueue()
        ) {
            (
                    if (pool.activeCount > MAX_PLATFORM_THREADS) Thread.ofVirtual()
                    else Thread.ofPlatform().daemon(true)
            )
                .name("TypewriterPoolThread-", 1)
                .unstarted(it)
        }

        pool.asCoroutineDispatcher()
    }
)

val Dispatchers.UntickedAsync: CoroutineDispatcher get() = CachedThreadPoolDispatcher

fun CoroutineContext.launch(
    block: suspend CoroutineScope.() -> Unit
): Job = CoroutineScope(this).launch(block = block)

suspend fun <T> CoroutineContext.switchContext(
    block: suspend CoroutineScope.() -> T
): T = withContext(this, block = block)