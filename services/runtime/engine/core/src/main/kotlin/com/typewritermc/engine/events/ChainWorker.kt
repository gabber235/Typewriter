package com.typewritermc.engine.events

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/**
 * Drains the [queue] once per [pickup]: the engine kind calls it when a tick ends (Paper on `ServerTickEndEvent`, the
 * panel engine at once). Each pickup starts one worker that takes chains until the queue is empty, so a worker stuck in
 * one chain leaves the rest to the next pickup's worker. Workers share a bounded [dispatcher].
 */
class ChainWorker(
    private val queue: ChainQueue,
    private val scope: CoroutineScope,
    private val dispatcher: CoroutineDispatcher = Dispatchers.Default.limitedParallelism(WORKERS),
) {
    fun pickup() {
        scope.launch(dispatcher) { queue.runPending() }
    }

    private companion object {
        /** How many chains run at once at most; the rest wait for a free worker. */
        const val WORKERS = 4
    }
}
