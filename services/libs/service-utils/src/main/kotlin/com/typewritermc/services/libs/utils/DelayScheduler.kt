package com.typewritermc.services.libs.utils

import kotlin.time.Duration
import kotlinx.coroutines.delay as coroutineDelay

/** Suspends lifecycle work for a requested duration. */
fun interface DelayScheduler {
    suspend fun delay(duration: Duration)
}

/** Coroutine backed production delay scheduler. */
object CoroutineDelayScheduler : DelayScheduler {
    override suspend fun delay(duration: Duration) {
        coroutineDelay(duration)
    }
}
