package com.typewritermc.realm.checking

import com.typewritermc.authoring.ReadContext
import com.typewritermc.formula.graph.StaleRevision
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import com.typewritermc.failures.rethrowExceptional
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CompletableJob
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.job
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.supervisorScope
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.CatalogGeneration
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

data class CapturedCheckReport(
    val context: ReadContext,
    val catalog: CatalogGeneration,
    val required: Set<CheckInstanceId>,
    val results: List<CheckResult>,
) {
    val complete: Boolean
        get() =
            results.mapTo(linkedSetOf()) { result -> result.ticket.instance } == required &&
                results.all { result -> result.outcome !is CheckOutcome.IncompleteWrapper }
}

/**
 * Owns the realm's check instances and the findings editor clients see, and runs every check as a graph query.
 *
 * One pass per revision owns all scheduling: each change of the view store starts a pass that reads every instance's
 * [CheckRun] at its revision and cancels the one before, so a run overtaken by a commit is always read again. A memo
 * hit does no check work, and no query runs under this runtime's lock. Applying discovery and storing a result both
 * require that the pass's revision is still current, so an overtaken pass changes nothing.
 *
 * Publication uses [evaluateCapture] to evaluate exactly the view it captured, through a fork of the graph. Finding
 * notifications are hints for clients to query state, sent only when what a reader can see changed. Closing cancels
 * and joins every pass, also one blocked in provider code that ignores cancellation.
 */
class RealmCheckRuntime(
    private val views: AuthoringViewStore,
    dispatcher: CoroutineDispatcher = Dispatchers.Default,
    private val telemetry: ServiceTelemetry = OpenTelemetry.noop().serviceTelemetry("realm.checks"),
) : AutoCloseable {
    private val lock = Any()
    private val mutableFindingChanges =
        MutableSharedFlow<Unit>(
            extraBufferCapacity = 1,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )

    /** Coalesced hints that published or removed current findings changed. */
    val findingChanges: SharedFlow<Unit> = mutableFindingChanges
    private val scope = CoroutineScope(SupervisorJob() + dispatcher)

    // The collector runs inside install, under the view lock, and does nothing but start a pass.
    private val signals = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
    private val running = AtomicReference<Job?>()
    private val started = AtomicBoolean()
    private val closing: CompletableJob = Job()
    private val instances = linkedMapOf<CheckInstanceId, InstanceState>()
    private var closed = false

    /** Runs every check now, and again on every change of the view store. Returns while the checks run; a second call does nothing. */
    fun start() {
        if (!started.compareAndSet(false, true)) return
        signals.launch {
            views.changes.collect {
                running.getAndSet(scope.launch { runPass() })?.cancel()
            }
        }
    }

    /** Waits until every pass has ended, also an overtaken one blocked in provider code, or until the runtime closes. */
    suspend fun drain() {
        while (!closing.isCompleted) {
            val passes =
                scope.coroutineContext.job.children
                    .toList()
            if (passes.isEmpty()) return
            select {
                closing.onJoin {}
                passes.forEach { pass -> pass.onJoin {} }
            }
        }
    }

    fun findings(): List<FindingSet> =
        synchronized(lock) {
            instances.values.mapNotNull(InstanceState::findings)
        }

    /** Evaluates [view] exactly, whatever has been committed since it was captured. */
    suspend fun evaluateCapture(view: AuthoringView): CapturedCheckReport =
        views.retain(view.readContext).use {
            val reads = views.forkAt(view).pin()
            val subjects = reads.read(CheckSubjects).subjects
            val results =
                subjects.map { subject ->
                    val run = CheckRun(subject.id)
                    runCatching { with(reads) { read(run).toCheckResult(run.evidence()) } }.getOrElse { failure ->
                        failure.rethrowExceptional()
                        subject
                            .failedRun(
                                CheckTicket(instance = subject.id, catalog = view.catalog.generation),
                                failure,
                            ).toCheckResult(emptyList())
                    }
                }
            CapturedCheckReport(view.readContext, view.catalog.generation, subjects.mapTo(linkedSetOf()) { it.id }, results)
        }

    override fun close() {
        signals.cancel()
        synchronized(lock) {
            if (closed) return
            closed = true
            instances.clear()
        }
        closing.complete()
        scope.cancel()
        // Waits for provider code that ignores cancellation, so none of it outlives the view store.
        runBlocking { scope.coroutineContext.job.join() }
    }

    /**
     * Runs one pass on its own span. A pass that fails, as when saved authoring cannot be read again, records the
     * failure there and leaves the findings it could not refresh outdated; the next change retries it.
     */
    private suspend fun runPass() {
        runCatching { telemetry.mainSpan("realm.checks.pass", PASS_FAILED) { settle() } }.onFailure { failure ->
            failure.rethrowExceptional()
            synchronized(lock) { instances.values.forEach(InstanceState::markOutdated) }
        }
    }

    private suspend fun settle() {
        views.pin().use { pinned ->
            val reads = pinned.reads
            val discovery =
                try {
                    reads.read(CheckSubjects)
                } catch (_: StaleRevision) {
                    return
                }
            if (!reconcile(discovery, reads.revision)) return
            supervisorScope {
                discovery.subjects.forEach { subject ->
                    launch { runOne(subject, reads, pinned.view) }
                }
            }
        }
    }

    private fun runOne(
        subject: CheckSubject,
        reads: RealmReads,
        view: AuthoringView,
    ) {
        val run = CheckRun(subject.id)
        val (result, evidence) =
            runCatching { with(reads) { read(run) to run.evidence() } }.getOrElse { failure ->
                // The next pass reads an overtaken run again.
                if (failure is StaleRevision) return
                failure.rethrowExceptional()
                subject.failedRun(CheckTicket(instance = subject.id, catalog = view.catalog.generation), failure) to emptyList()
            }
        val next = result.toFindingSet(evidence, FindingStatus.CURRENT)
        val changed =
            synchronized(lock) {
                if (closed || reads.revision != views.graph.revision) return
                val state = instances[subject.id] ?: return
                if (state.findings == next) return
                state.findings = next
                true
            }
        if (changed) mutableFindingChanges.tryEmit(Unit)
    }

    /** Applies [discovery] at [revision]: removes instances that are gone and adds new ones. False once a newer revision exists. */
    private fun reconcile(
        discovery: SubjectDiscovery,
        revision: Long,
    ): Boolean {
        val removed =
            synchronized(lock) {
                if (closed || revision != views.graph.revision) return false
                instances.filterKeys { it.rule in discovery.incompleteRules }.values.forEach(InstanceState::markOutdated)
                val discovered = discovery.subjects.mapTo(hashSetOf(), CheckSubject::id)
                val removed = (instances.keys - discovered).filter { it.rule !in discovery.incompleteRules }
                removed.forEach(instances::remove)
                discovered.forEach { id -> instances.getOrPut(id) { InstanceState() } }
                removed
            }
        if (removed.isNotEmpty()) mutableFindingChanges.tryEmit(Unit)
        return true
    }

    private companion object {
        val PASS_FAILED = ErrorSlug.of("realm-check-pass-failed")
    }

    private class InstanceState(
        var findings: FindingSet? = null,
    ) {
        fun markOutdated() {
            findings = findings?.copy(status = FindingStatus.OUTDATED)
        }
    }
}
