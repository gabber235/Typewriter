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
 * The maximum number of threads to allow in the pool at any
 * given time.
 */
const val MAX_THREAD_POOL_SIZE = 180

/**
 * Upon the [pool's active thread count][ThreadPoolExecutor.getActiveCount] reaching or exceeding this value,
 * [virtual threads][VirtualThread] will be created instead of [platform threads][Thread].
 *
 * In other words, there is a maximum of [VIRTUAL_THREAD_THRESHOLD] platform threads in the [pool][CachedThreadPoolDispatcher].
 */
const val VIRTUAL_THREAD_THRESHOLD = 30

/**
 * The number of threads that are always present in the [pool][CachedThreadPoolDispatcher].
 */
const val CORE_POOL_SIZE = 6

@OptIn(ExperimentalStdlibApi::class)
private object CachedThreadPoolDispatcher : TypewriterDispatcher(
    run {
        // threads won't be created until this is initialized.
        lateinit var pool: ThreadPoolExecutor

        pool = ThreadPoolExecutor(
            CORE_POOL_SIZE,
            MAX_THREAD_POOL_SIZE,
            60L,
            TimeUnit.SECONDS,
            SynchronousQueue()
        ) {
            (
                    if (pool.activeCount > VIRTUAL_THREAD_THRESHOLD) Thread.ofVirtual()
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