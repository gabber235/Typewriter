package com.typewritermc.core.utils

import kotlinx.coroutines.*
import org.jetbrains.annotations.ApiStatus
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.util.concurrent.LinkedBlockingQueue
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
 * [MAX_PLATFORM_THREADS] = The maximum number of threads in the pool.
 *
 * All platform threads in the pool are [daemon threads][Thread.setDaemon]
 *
 * @see Thread
 */
val MAX_PLATFORM_THREADS = Runtime.getRuntime().availableProcessors() * 2

private object CachedThreadPoolDispatcher : TypewriterDispatcher(
    ThreadPoolExecutor(
        0,
        MAX_PLATFORM_THREADS,
        60L,
        TimeUnit.SECONDS,
        LinkedBlockingQueue(),
        Thread.ofPlatform().daemon(true).name("TypewriterPoolThread-", 1)
            .factory(),
    ).asCoroutineDispatcher()
)

val Dispatchers.UntickedAsync: CoroutineDispatcher get() = CachedThreadPoolDispatcher

fun CoroutineContext.launch(
    block: suspend CoroutineScope.() -> Unit
): Job = CoroutineScope(this).launch(block = block)

suspend fun <T> CoroutineContext.switchContext(
    block: suspend CoroutineScope.() -> T
): T = withContext(this, block = block)