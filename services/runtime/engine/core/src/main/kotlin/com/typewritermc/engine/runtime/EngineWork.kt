package com.typewritermc.engine.runtime

import com.typewritermc.loader.api.work.RuntimeWork
import com.typewritermc.loader.api.work.countedIn
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers

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
    CoroutineScope(Dispatchers.Default.countedIn(work, "engine task") + ReportedByDeployment)

/** A failed deployment scope is reported by the deployment that watches it, through its health. */
private val ReportedByDeployment = CoroutineExceptionHandler { _, _ -> }
