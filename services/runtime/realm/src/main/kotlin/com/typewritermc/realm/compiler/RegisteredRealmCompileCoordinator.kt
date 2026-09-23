package com.typewritermc.realm.compiler

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.types.ResourceId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.time.Duration.Companion.seconds

/** Serializes exact projection invalidations and compiles only the roots named by each accepted mutation. */
internal class RegisteredRealmCompileCoordinator(
    private val projections: AuthoringCompilationProjectionRegistry,
    private val compiler: RegisteredRealmCompiler,
    private val graph: suspend (AuthoringCompilationProjection, ResourceId?) -> AuthoringWorkingGraph,
    private val sourceRevision: suspend () -> String,
    private val catalogRevision: () -> String,
    private val scope: CoroutineScope,
    private val onFailure: suspend (Throwable) -> Unit,
) {
    private val invalidations = Channel<CompileRequest>(Channel.UNLIMITED)
    private var worker: Job? = null
    private val retryJobs = mutableSetOf<Job>()

    fun start() {
        check(worker == null) { "Registered Realm compiler is already started." }
        while (invalidations.tryReceive().isSuccess) {
            // Discard work retained from a previous lifecycle.
        }
        invalidations.trySend(CompileRequest(null)).getOrThrow()
        worker =
            scope.launch {
                for (request in invalidations) {
                    compile(request)
                }
            }
    }

    fun invalidate(roots: Collection<CompilationRoot>) {
        if (worker == null) return
        val grouped = roots.groupBy({ it.projection }, { it.resource }).mapValues { it.value.toSet() }
        invalidations.trySend(CompileRequest(CompilationImpact(grouped))).getOrThrow()
    }

    fun invalidateAll() {
        if (worker == null) return
        invalidations.trySend(CompileRequest(null)).getOrThrow()
    }

    suspend fun stop() {
        worker?.cancelAndJoin()
        worker = null
        val retries = synchronized(retryJobs) { retryJobs.toList().also { retryJobs.clear() } }
        retries.forEach { it.cancelAndJoin() }
        while (invalidations.tryReceive().isSuccess) {
            // A stopped coordinator must not replay stale invalidations after restart.
        }
    }

    private suspend fun compileAll(): CompilationImpact {
        val allRoots =
            projections.projections.associate { projection ->
                val workingGraph = graph(projection, null)
                projection.id to projection.roots(workingGraph)
            }
        return CompilationImpact(allRoots)
    }

    private suspend fun compile(request: CompileRequest) {
        try {
            val impact = request.impact ?: compileAll()
            compiler.compile(
                sourceRevision = sourceRevision(),
                catalogRevision = catalogRevision(),
                impact = impact,
                graph = { projection, root -> graph(projection, root) },
            )
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (failure: Throwable) {
            onFailure(failure)
            if (request.attempt < MAX_RETRY_ATTEMPTS) {
                val retry =
                    scope.launch {
                        delay((request.attempt + 1).seconds)
                        if (worker != null) {
                            invalidations.send(request.copy(attempt = request.attempt + 1))
                        }
                    }
                synchronized(retryJobs) { retryJobs += retry }
                retry.invokeOnCompletion { synchronized(retryJobs) { retryJobs -= retry } }
            }
        }
    }

    private data class CompileRequest(
        val impact: CompilationImpact?,
        val attempt: Int = 0,
    )

    private companion object {
        const val MAX_RETRY_ATTEMPTS = 3
    }
}
