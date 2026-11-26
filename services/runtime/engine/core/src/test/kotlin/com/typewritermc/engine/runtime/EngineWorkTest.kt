package com.typewritermc.engine.runtime

import com.typewritermc.loader.api.work.WorkSubjects
import com.typewritermc.loader.api.work.testing.RecordedWork
import com.typewritermc.loader.api.work.testing.WorkEvent
import com.typewritermc.loader.api.work.testing.minecraftSubject
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.Continuation
import kotlin.coroutines.ContinuationInterceptor
import kotlin.coroutines.resume
import kotlin.time.Duration.Companion.milliseconds

/** Every task an engine runs counts as in flight work of its host, from the moment it is dispatched until it ran. */
val EngineWorkTest by testSuite {
    test("a task of an engine counts for the subjects of its coroutine from its dispatch until it ran") {
        val recorded = RecordedWork()
        val scope = engineScope(recorded.runtime)
        val player = minecraftSubject("8d6c")
        val parked = CompletableDeferred<Continuation<Unit>>()
        val countWhileRunning = CompletableDeferred<Int>()

        val job =
            scope.launch(WorkSubjects(setOf(player)) + CoroutineName("join")) {
                suspendCancellableCoroutine { parked.complete(it) }
                countWhileRunning.complete(recorded.work.count)
            }
        val continuation = parked.await()
        while (recorded.work.count > 0) delay(1.milliseconds)
        continuation.resume(Unit)
        job.join()
        while (recorded.work.count > 0) delay(1.milliseconds)
        scope.cancel()

        countWhileRunning.await() shouldBe 1
        recorded.events shouldContainExactly
            listOf(
                WorkEvent.Began("engine task join", setOf(player)),
                WorkEvent.Ended("engine task join"),
                WorkEvent.Began("engine task join", setOf(player)),
                WorkEvent.Ended("engine task join"),
            )
    }

    test("a task on a narrowed view of an engine's dispatcher counts as well") {
        val recorded = RecordedWork()
        val scope = engineScope(recorded.runtime)
        val narrowed = (scope.coroutineContext[ContinuationInterceptor] as CoroutineDispatcher).limitedParallelism(1)

        val job = scope.launch { withContext(narrowed + CoroutineName("narrowed")) {} }
        job.join()
        while (recorded.work.count > 0) delay(1.milliseconds)
        scope.cancel()

        recorded.eventsOf("engine task narrowed").map { it::class } shouldContainExactly
            listOf(WorkEvent.Began::class, WorkEvent.Ended::class)
    }
}
