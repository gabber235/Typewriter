package com.typewritermc.core.utils

import kotlinx.coroutines.*
import org.jetbrains.annotations.ApiStatus
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.RejectedExecutionHandler
import java.util.concurrent.ThreadFactory
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
 * The sum of [MAX_PLATFORM_THREADS] and [MAX_VIRTUAL_THREADS] is the maximum number of threads in the pool.
 *
 * All platform threads in the pool are [daemon threads][Thread.setDaemon]
 *
 * @see Thread
 */
val MAX_PLATFORM_THREADS = Runtime.getRuntime().availableProcessors() * 4

/**
 * The maximum number of virtual threads allowed in the pool.
 *
 * The sum of [MAX_PLATFORM_THREADS] and [MAX_VIRTUAL_THREADS] is the maximum number of threads in the pool.
 *
 * @see Thread
 * @see VirtualThread
 */
val MAX_VIRTUAL_THREADS = Runtime.getRuntime().availableProcessors() * 10

/**
 * The number of threads that are always present in the [pool][CachedThreadPoolDispatcher].
 *
 * If [MAX_PLATFORM_THREADS] is less than the [CORE_POOL_SIZE], then virtual threads will be created for the core pool.
 *
 * @see ThreadPoolExecutor.corePoolSize
 */
const val CORE_POOL_SIZE = 8

/**
 * The time to keep an idle thread in the pool, after which the thread is discarded.
 */
const val THREAD_KEEP_ALIVE_SECONDS = 60L

/**
 * The number of tasks to queue before the pool creates new threads to handle more tasks.
 * When the [number of threads in the pool][ThreadPoolExecutor.getActiveCount] exceeds the
 * maximum size (The sum of [MAX_PLATFORM_THREADS] and [MAX_VIRTUAL_THREADS]), tasks are _rejected_.
 *
 * The current implementation of the [RejectedExecutionHandler] logs the rejection and the [Runnable] victim,
 * and [invokes the task on the caller's thread][ThreadPoolExecutor.CallerRunsPolicy] (typically [Dispatchers.Default] or a thread in the [pool][CachedThreadPoolDispatcher]).
 *
 * It is important to note that if the pool is shutting down, the task is merely [discarded upon rejection][ThreadPoolExecutor.CallerRunsPolicy].
 * This behavior is trivial to modify.
 *
 * __In simple terms, this is the size of the task buffer, which sits in between using existing threads and creating new ones.__
 *
 * @see ArrayBlockingQueue the task queue implementation
 * @see ThreadPoolExecutor.CallerRunsPolicy
 */
// While using SynchronousQueue as the task queue, tasks were instantly thrown in the pool.
// This would always create a new thread if all the previous threads were busy (And there was no ability to wait for a task to finish a task before queuing the next).
// This often happened with the road network editor as it would tend to queue many, many tasks at one moment (recalculating edges).
const val TASK_QUEUE_SIZE = 16

/**
 * The thread pool used for typewriter's various asynchronous tasks.
 *
 * @throws IllegalStateException If `MAX_PLATFORM_THREADS + MAX_VIRTUAL_THREADS < CORE_POOL_SIZE`.
 */
@OptIn(ExperimentalStdlibApi::class)
private object CachedThreadPoolDispatcher : TypewriterDispatcher(
    run {
        // threads won't be created until this is initialized.
        lateinit var pool: ThreadPoolExecutor
        val callerRunsPolicy = ThreadPoolExecutor.CallerRunsPolicy()

        // Select whether we need a platform thread or a virtual thread.
        fun selectThreadBuilder(): Thread.Builder =
            if (pool.activeCount > MAX_PLATFORM_THREADS) Thread.ofVirtual()
            else Thread.ofPlatform().daemon(true)

        // ThreadPoolExecutor parameters
        val maximumPoolSize = MAX_PLATFORM_THREADS + MAX_VIRTUAL_THREADS
        val workQueue = ArrayBlockingQueue<Runnable>(TASK_QUEUE_SIZE)
        val threadFactory = ThreadFactory {
            // Create a thread and name it.
            selectThreadBuilder()
                .name("TypewriterPoolThread-", 1)
                .unstarted(it)
        }
        val handler = RejectedExecutionHandler { r, e ->
            // Log, then have the caller run the task. It is possible we want to change this approach.
            println("Typewriter thread pool is full, and the caller will execute the task. ($r)")
            // Valuable info
            println("There are approx: ${pool.activeCount} active threads, ${pool.taskCount - pool.completedTaskCount} " +
                    "tasks queued, and ${pool.poolSize - pool.maximumPoolSize} idle threads.")
            callerRunsPolicy.rejectedExecution(r, e)
        }

        pool = ThreadPoolExecutor(
            CORE_POOL_SIZE,
            maximumPoolSize,
            THREAD_KEEP_ALIVE_SECONDS,
            TimeUnit.SECONDS,
            workQueue,
            threadFactory,
            handler,
        )

        return@run pool.asCoroutineDispatcher()
    }
)

@Suppress("UnusedReceiverParameter")
val Dispatchers.UntickedAsync: CoroutineDispatcher get() = CachedThreadPoolDispatcher

fun CoroutineContext.launch(
    block: suspend CoroutineScope.() -> Unit
): Job = CoroutineScope(this).launch(block = block)

suspend fun <T> CoroutineContext.switchContext(
    block: suspend CoroutineScope.() -> T
): T = withContext(this, block = block)