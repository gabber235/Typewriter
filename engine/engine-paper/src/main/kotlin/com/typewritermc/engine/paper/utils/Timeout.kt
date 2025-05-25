package com.typewritermc.engine.paper.utils

import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import org.koin.core.component.KoinComponent
import kotlin.time.Duration

class Timeout(
    private val duration: Duration,
    private val invoker: () -> Unit,
    private val immediateRunnable: Runnable? = null,
) : KoinComponent {
    private var job: Job? = null
    operator fun invoke() {
        immediateRunnable?.run()
        if (job == null) {
            job = Dispatchers.UntickedAsync.launch {
                delay(duration)
                job = null
                invoker()
            }
        }
    }

    fun force() {
        cancel()
        invoker()
    }

    fun cancel() {
        job?.cancel()
        job = null
    }
}