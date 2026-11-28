package com.typewritermc.loader.api.work

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.Runnable
import kotlin.coroutines.CoroutineContext

/**
 * This dispatcher with every task it runs counted in [work] as item `"<task> <coroutine name>"`, for the subjects of
 * the coroutine it continues, from its dispatch until it ran. Whatever runs between two suspensions on it is then in
 * flight work; a narrowed view of it counts as well.
 */
fun CoroutineDispatcher.countedIn(
    work: WorkSource,
    task: String,
): CoroutineDispatcher = CountingDispatcher(this, work, task)

private class CountingDispatcher(
    private val dispatcher: CoroutineDispatcher,
    private val work: WorkSource,
    private val task: String,
) : CoroutineDispatcher() {
    override fun isDispatchNeeded(context: CoroutineContext): Boolean = dispatcher.isDispatchNeeded(context)

    override fun dispatch(
        context: CoroutineContext,
        block: Runnable,
    ) {
        val item = work.begin(context[CoroutineName]?.let { "$task ${it.name}" } ?: task, context[WorkSubjects]?.subjects)
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
    ): CoroutineDispatcher = CountingDispatcher(dispatcher.limitedParallelism(parallelism, name), work, task)

    override fun toString(): String = "Counting($dispatcher)"
}
