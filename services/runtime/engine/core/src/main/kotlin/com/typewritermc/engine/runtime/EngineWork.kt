package com.typewritermc.engine.runtime

import com.typewritermc.loader.api.work.RuntimeWork
import com.typewritermc.loader.api.work.WorkSubjects
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Runnable
import kotlin.coroutines.CoroutineContext

/**
 * The scope of one engine deployment. Every task of the engine runs on its one dispatcher, which counts each task in
 * [work] from its dispatch until it ran, for the subjects of the coroutine it continues: whatever the engine does
 * between two suspensions is in flight work of its host, and whatever it awaits counts where it waits (the host's
 * messaging and shared artifacts).
 *
 * Work in the scope that throws fails the whole scope, and the deployment then reports itself unhealthy with that
 * cause ([ReloadableEngineRuntime]), so the failure is handled there and never left to the global handler alone.
 */
internal fun engineScope(work: RuntimeWork): CoroutineScope =
    CoroutineScope(CountingDispatcher(Dispatchers.Default, work) + ReportedByDeployment)

/** A failed deployment scope is reported by the deployment that watches it, through its health. */
private val ReportedByDeployment = CoroutineExceptionHandler { _, _ -> }

private class CountingDispatcher(
    private val dispatcher: CoroutineDispatcher,
    private val work: RuntimeWork,
) : CoroutineDispatcher() {
    override fun isDispatchNeeded(context: CoroutineContext): Boolean = dispatcher.isDispatchNeeded(context)

    override fun dispatch(
        context: CoroutineContext,
        block: Runnable,
    ) {
        val item = work.begin("engine task ${context[CoroutineName]?.name ?: "unnamed"}", context[WorkSubjects]?.subjects)
        try {
            dispatcher.dispatch(
                context,
                Runnable {
                    try {
                        block.run()
                    } finally {
                        item.end()
                    }
                },
            )
        } catch (
            // Whatever refuses the task ends its item with that cause, and the caller still sees it.
            @Suppress("TooGenericExceptionCaught") refused: Throwable,
        ) {
            item.failed(refused)
            throw refused
        }
    }

    override fun limitedParallelism(
        parallelism: Int,
        name: String?,
    ): CoroutineDispatcher = CountingDispatcher(dispatcher.limitedParallelism(parallelism, name), work)

    override fun toString(): String = "Counting($dispatcher)"
}
