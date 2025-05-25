package com.typewritermc.core.utils

import com.typewritermc.core.utils.CachedThreadPoolDispatcher.counter
import kotlinx.coroutines.*
import org.jetbrains.annotations.ApiStatus
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger
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

private object CachedThreadPoolDispatcher : TypewriterDispatcher(Executors.newCachedThreadPool {
    Thread.ofPlatform().unstarted(it).apply {
        name = "TypewriterPoolThread-${counter.andIncrement}"
    }
}.asCoroutineDispatcher()) {
    private val counter = AtomicInteger(0)
}

val Dispatchers.UntickedAsync: CoroutineDispatcher get() = CachedThreadPoolDispatcher

fun CoroutineContext.launch(block: suspend CoroutineScope.() -> Unit): Job = CoroutineScope(this).launch(block = block)

suspend fun <T> CoroutineContext.switchContext(block: suspend CoroutineScope.() -> T): T =
    withContext(this, block = block)