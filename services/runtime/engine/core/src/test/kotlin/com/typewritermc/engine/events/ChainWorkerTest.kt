package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.protagonist
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.nondeterministic.eventually
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.time.Duration.Companion.seconds

/** Each tick's pickup drains the chain queue on a worker, so one slow chain never holds the others. */
val ChainWorkerTest by testSuite {
    test("a chain stuck on one tick leaves the chains behind it to the next tick's worker") {
        val queue = ChainQueue()
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val ran = CopyOnWriteArrayList<String>()
        val stuck = CompletableDeferred<Unit>()
        try {
            val worker = ChainWorker(queue, scope)
            queue.enqueue(protagonist("alex"), "slow") {
                ran += "slow started"
                stuck.await()
            }
            worker.pickup()
            eventually(5.seconds) { ran shouldContainExactly listOf("slow started") }

            queue.enqueue(protagonist("sam"), "quick") { ran += "quick" }
            worker.pickup()
            eventually(5.seconds) { ran shouldContainExactly listOf("slow started", "quick") }
        } finally {
            stuck.complete(Unit)
            scope.cancel()
        }
    }
}
