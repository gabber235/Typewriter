package com.typewritermc.engine.paper.utils

import com.github.shynixn.mccoroutine.bukkit.asyncDispatcher
import com.github.shynixn.mccoroutine.bukkit.minecraftDispatcher
import com.typewritermc.core.utils.TypewriterDispatcher
import com.typewritermc.engine.paper.plugin
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers

private object PaperTickedAsyncDispatcher : TypewriterDispatcher(plugin.asyncDispatcher)
private object PaperSyncDispatcher : TypewriterDispatcher(plugin.minecraftDispatcher)

val Dispatchers.Sync: CoroutineDispatcher get() = PaperSyncDispatcher
val Dispatchers.TickedAsync: CoroutineDispatcher get() = PaperTickedAsyncDispatcher

