package com.typewritermc.engine.paper.utils

import com.github.shynixn.mccoroutine.bukkit.asyncDispatcher
import com.github.shynixn.mccoroutine.bukkit.launch
import com.github.shynixn.mccoroutine.bukkit.minecraftDispatcher
import com.typewritermc.engine.paper.plugin
import kotlinx.coroutines.*
import com.typewritermc.core.utils.server

enum class ThreadType {
    SYNC,
    ASYNC,
    DISPATCHERS_ASYNC,
    REMAIN,
    ;

    @OptIn(ExperimentalCoroutinesApi::class)
    suspend fun <T> switchContext(block: suspend () -> T): T {
        if (!plugin.isEnabled) {
            return block()
        }
        if (this == REMAIN) {
            return block()
        }

        return withContext(
            when (this) {
                SYNC -> plugin.minecraftDispatcher
                ASYNC -> plugin.asyncDispatcher
                DISPATCHERS_ASYNC -> pool ?: Dispatchers.IO
                else -> throw IllegalStateException("Unknown thread type: $this")
            }
        ) {
            block()
        }
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    fun launch(block: suspend () -> Unit): Job {
        if (!plugin.isEnabled) {
            runBlocking {
                block()
            }
            return Job()
        }

        return plugin.launch(
            when (this) {
                SYNC -> plugin.minecraftDispatcher
                ASYNC -> plugin.asyncDispatcher
                DISPATCHERS_ASYNC -> pool ?: Dispatchers.IO
                REMAIN -> if (server.isPrimaryThread) plugin.minecraftDispatcher else plugin.asyncDispatcher
            }
        ) {
            block()
        }
    }

    companion object {
        @OptIn(ExperimentalCoroutinesApi::class)
        private var pool: CloseableCoroutineDispatcher? = null

        @OptIn(ExperimentalCoroutinesApi::class, DelicateCoroutinesApi::class)
        fun initialize() {
            pool = newFixedThreadPoolContext(Runtime.getRuntime().availableProcessors(), "Typewriter")
        }

        @OptIn(ExperimentalCoroutinesApi::class)
        fun shutdown() {
            pool?.close()
            pool = null
        }
    }
}