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
) {
    private val invalidations = Channel<CompilationImpact?>(Channel.UNLIMITED)
    private var worker: Job? = null

    fun start() {
        check(worker == null) { "Registered Realm compiler is already started." }
        worker =
            scope.launch {
                compileAll()
                for (impact in invalidations) {
                    if (impact == null) compileAll() else compile(impact)
                }
            }
    }

    fun invalidate(roots: Collection<CompilationRoot>) {
        val grouped = roots.groupBy({ it.projection }, { it.resource }).mapValues { it.value.toSet() }
        invalidations.trySend(CompilationImpact(grouped)).getOrThrow()
    }

    fun invalidateAll() {
        invalidations.trySend(null).getOrThrow()
    }

    suspend fun stop() {
        worker?.cancelAndJoin()
        worker = null
    }

    private suspend fun compileAll() {
        val allRoots =
            projections.projections.associate { projection ->
                val workingGraph = graph(projection, null)
                projection.id to projection.roots(workingGraph)
            }
        compile(CompilationImpact(allRoots))
    }

    private suspend fun compile(impact: CompilationImpact) {
        while (true) {
            try {
                compiler.compile(
                    sourceRevision = sourceRevision(),
                    catalogRevision = catalogRevision(),
                    impact = impact,
                    graph = { projection, root -> graph(projection, root) },
                )
                return
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Throwable) {
                delay(1.seconds)
            }
        }
    }
}
