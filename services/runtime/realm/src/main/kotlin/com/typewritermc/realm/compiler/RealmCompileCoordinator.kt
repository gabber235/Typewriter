package com.typewritermc.realm.compiler

import com.typewritermc.realm.repository.PageDocumentRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

/**
 * Serializes compilation of latest authored state in a background worker.
 *
 * Pending invalidations are conflated. Stale publication retries immediately; operational failures update health
 * and retry after a delay. Start triggers an initial pass, and stop cancels and joins the worker.
 */
class RealmCompileCoordinator(
    private val documents: PageDocumentRepository,
    private val compiler: RealmCompiler,
    private val catalogRevision: () -> String,
    private val scope: CoroutineScope,
    private val onActivated: suspend (RealmCompileResult.Activated) -> Unit = {},
) {
    private val invalidations = Channel<Unit>(Channel.CONFLATED)
    private val mutableHealth = MutableStateFlow<RealmCompileHealth>(RealmCompileHealth.Idle)
    val health: StateFlow<RealmCompileHealth> = mutableHealth
    private var worker: Job? = null

    fun start() {
        check(worker == null) { "Realm compiler is already started." }
        worker =
            scope.launch {
                invalidate()
                for (ignored in invalidations) compileLatest()
            }
    }

    /**
     * Requests compilation without waiting for it.
     *
     * Pending requests collapse into one; observe health or activation state for completion.
     */
    fun invalidate() {
        invalidations.trySend(Unit).getOrThrow()
    }

    suspend fun stop() {
        worker?.cancelAndJoin()
        worker = null
        mutableHealth.value = RealmCompileHealth.Idle
    }

    private suspend fun compileLatest() {
        while (true) {
            try {
                mutableHealth.value = RealmCompileHealth.Compiling
                val snapshot = documents.getAuthoringSnapshot()
                when (val result = compiler.compile(snapshot, catalogRevision())) {
                    RealmCompileResult.Stale -> {
                        continue
                    }

                    is RealmCompileResult.Activated -> {
                        onActivated(result)
                        mutableHealth.value = RealmCompileHealth.Active(result.manifest.sourceRevision)
                    }

                    is RealmCompileResult.Blocked -> {
                        mutableHealth.value = RealmCompileHealth.Blocked(result.diagnostics)
                    }
                }
                return
            } catch (failure: CancellationException) {
                throw failure
            } catch (failure: Throwable) {
                mutableHealth.value = RealmCompileHealth.Failed(failure.message ?: failure::class.simpleName.orEmpty())
                delay(1.seconds)
            }
        }
    }
}

/**
 * Reports compiler activity separately from the previous active manifest.
 *
 * Blocked identifies invalid input, while Failed identifies an operational exception being retried.
 */
sealed interface RealmCompileHealth {
    data object Idle : RealmCompileHealth

    data object Compiling : RealmCompileHealth

    data class Active(
        val sourceRevision: String,
    ) : RealmCompileHealth

    data class Blocked(
        val diagnostics: List<com.typewritermc.engine.CompileDiagnostic>,
    ) : RealmCompileHealth

    data class Failed(
        val message: String,
    ) : RealmCompileHealth
}
