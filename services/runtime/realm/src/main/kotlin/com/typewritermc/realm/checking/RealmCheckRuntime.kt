package com.typewritermc.realm.checking

import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.SelectionPredicateEvaluator
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.conflicts
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.BufferOverflow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId
import java.util.concurrent.atomic.AtomicLong

interface CheckScheduler : AutoCloseable {
    fun invalidate(changed: Set<InputIdentity>)

    suspend fun drain()
}

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
 * Owns discovered check instances, their running executions, and the findings exposed to editor clients.
 *
 * Each execution retains its authored snapshot and records the facts it reads. Completion installs current
 * findings only while its ticket and those facts still match; invalidation marks prior findings outdated and
 * schedules affected checks. Catalog reload retires old executions before releasing their provider leases.
 *
 * Publication uses [evaluateCapture] to evaluate a retained saved view independently of current editor findings.
 * Closing cancels and joins owned jobs before releasing catalog services. Finding notifications are asynchronous
 * hints for clients to query state, rather than the admission boundary itself.
 */
class RealmCheckRuntime(
    private val views: AuthoringViewStore,
    dispatcher: CoroutineDispatcher = Dispatchers.Default,
    private val dependencies: ReverseDependencyIndex = DefaultReverseDependencyIndex(),
    checkInputs: RealmCheckInputs = RealmCheckInputs(),
    selectionPredicates: SelectionPredicateEvaluator = RealmSelectionPredicateEvaluator(),
    readLimits: ViewReadLimits = ViewReadLimits(),
) : CheckScheduler,
    CurrentCheckExecutions {
    private val lock = Any()
    private val mutableFindingChanges =
        MutableSharedFlow<Unit>(
            extraBufferCapacity = 1,
            onBufferOverflow = BufferOverflow.DROP_OLDEST,
        )

    /** Coalesced hints that published or removed current findings changed. */
    val findingChanges: SharedFlow<Unit> = mutableFindingChanges
    private val scope = CoroutineScope(SupervisorJob() + dispatcher)
    private val nextIncarnation = AtomicLong()
    private val nextExecution = AtomicLong()
    private val evaluator = CheckEvaluator(views, checkInputs, selectionPredicates, readLimits, nextExecution)
    private var activeCatalog: ActiveCatalog? = null
    private val instances = linkedMapOf<CheckInstanceId, InstanceState>()
    private val retiredJobs = linkedSetOf<Job>()
    private var closed = false

    suspend fun reloadCatalog() {
        val lease = views.capture()
        val replacement =
            try {
                collectCatalog(lease, "catalog:${nextIncarnation.getAndIncrement()}", evaluator)
            } catch (failure: Throwable) {
                lease.close()
                throw failure
            }
        val retired =
            synchronized(lock) {
                ensureOpen()
                val old = activeCatalog
                activeCatalog = replacement
                instances.values.forEach { state ->
                    state.job?.cancel()
                    state.findings = state.findings?.copy(status = FindingStatus.OUTDATED)
                }
                old
            }
        drain()
        synchronized(lock) {
            instances.values.forEach { state ->
                state.job = null
                state.ticket = null
            }
        }
        retired?.close()
        reconcileAndSchedule()
    }

    fun invalidateCurrent() {
        views.capture().use { lease ->
            val values = lease.root.values
            synchronized(lock) {
                if (closed) return
                instances.values.forEach { state ->
                    val findings = state.findings ?: return@forEach
                    if (values.conflicts(findings.expectations).isNotEmpty()) {
                        state.findings = state.findings?.copy(status = FindingStatus.OUTDATED)
                        retireJobLocked(state.job)
                        state.job = null
                        scheduleLocked(state)
                    }
                }
            }
        }
        scope.launch { reconcileAndSchedule() }
    }

    override fun invalidate(changed: Set<InputIdentity>) {
        if (changed.isEmpty()) return
        val rediscover = RESOURCE_SELECTION_INPUT in changed || changed.any { it is InputIdentity.Form || it is InputIdentity.Membership }
        synchronized(lock) {
            if (closed) return
            val affected = dependencies.affectedBy(changed)
            affected.forEach { id ->
                val state = instances[id] ?: return@forEach
                state.findings = state.findings?.copy(status = FindingStatus.OUTDATED)
                retireJobLocked(state.job)
                state.job = null
                scheduleLocked(state)
            }
        }
        if (rediscover) scope.launch { reconcileAndSchedule() }
    }

    override suspend fun drain() {
        while (true) {
            val jobs =
                synchronized(lock) {
                    (instances.values.mapNotNull(InstanceState::job) + retiredJobs)
                        .filterNot(Job::isCompleted)
                        .distinct()
                }
            if (jobs.isEmpty()) return
            jobs.joinAll()
        }
    }

    fun findings(): List<FindingSet> =
        synchronized(lock) {
            instances.values.mapNotNull(InstanceState::findings)
        }

    override fun ticket(instance: CheckInstanceId): CheckTicket? =
        synchronized(lock) {
            instances[instance]?.ticket
        }

    suspend fun evaluateCapture(target: CheckAdmissionTarget.CapturedAcceptance): CapturedCheckReport {
        var snapshot: AuthoringLease? = views.retain(target.view.readContext)
        var catalog: ActiveCatalog? = null
        return try {
            val captured = requireNotNull(snapshot)
            require(captured.root.catalog.generation == target.catalog) {
                "Captured check target uses a different catalog generation."
            }
            catalog = collectCatalog(captured, "catalog:${nextIncarnation.getAndIncrement()}", evaluator)
            snapshot = null
            val active = requireNotNull(catalog)
            val subjects = discoverSubjects(active, active.snapshot).subjects
            val required = subjects.mapTo(linkedSetOf()) { subject -> subject.id }
            val admission = DefaultCheckAdmission(views, this)
            val results =
                subjects.map { subject ->
                    val result = evaluator.evaluate(active, subject, target)
                    when (admission.requireEvidenceForCapture(result, target)) {
                        AdmissionResult.Captured -> {
                            result
                        }

                        AdmissionResult.Discarded -> {
                            result.copy(outcome = CheckOutcome.IncompleteWrapper("captured evidence was discarded"))
                        }

                        AdmissionResult.RetryRequired -> {
                            if (target.view.values
                                    .conflicts(result.expectations)
                                    .isEmpty() &&
                                result.outcome != CheckOutcome.FINISHED
                            ) {
                                result
                            } else {
                                result.copy(outcome = CheckOutcome.IncompleteWrapper("captured evidence requires retry"))
                            }
                        }

                        AdmissionResult.Published -> {
                            error("Captured admission cannot publish current findings.")
                        }
                    }
                }
            CapturedCheckReport(target.view.readContext, target.catalog, required, results)
        } finally {
            catalog?.close()
            snapshot?.close()
        }
    }

    override fun close() {
        val closing =
            synchronized(lock) {
                if (closed) return
                closed = true
                val jobs = (instances.values.mapNotNull(InstanceState::job) + retiredJobs).distinct()
                instances.values.forEach { state ->
                    state.job?.cancel()
                    dependencies.retire(state.id)
                }
                instances.clear()
                retiredJobs.clear()
                ClosingRuntime(jobs, activeCatalog.also { activeCatalog = null })
            }
        scope.cancel()
        runBlocking { closing.jobs.joinAll() }
        closing.catalog?.close()
    }

    private fun reconcileAndSchedule() {
        val retained =
            synchronized(lock) {
                if (closed) return
                activeCatalog?.let { catalog -> RetainedCatalog(catalog, catalog.retain()) }
            } ?: return
        try {
            val discovery = discoverSubjects(retained.catalog)
            val discovered = discovery.subjects.associateBy(CheckSubject::id)
            val removedTickets =
                synchronized(lock) {
                    if (closed || activeCatalog !== retained.catalog) return
                    val tickets = mutableListOf<CheckTicket>()
                    instances.values
                        .filter { state -> state.id.rule in discovery.incompleteRules }
                        .forEach { state -> state.findings = state.findings?.copy(status = FindingStatus.OUTDATED) }
                    val removed = (instances.keys - discovered.keys).filter { id -> id.rule !in discovery.incompleteRules }
                    removed.forEach { id ->
                        val state = instances.remove(id) ?: return@forEach
                        state.findings?.ticket?.let(tickets::add)
                        retireJobLocked(state.job)
                        dependencies.retire(id)
                    }
                    discovered.forEach { (id, subject) ->
                        val state = instances[id]
                        if (state == null) {
                            val created = InstanceState(id, subject)
                            instances[id] = created
                            scheduleLocked(created)
                        } else {
                            state.subject = subject
                            if (state.job == null && state.findings?.status != FindingStatus.CURRENT) scheduleLocked(state)
                        }
                    }
                    tickets
                }
            if (removedTickets.isNotEmpty()) mutableFindingChanges.tryEmit(Unit)
        } finally {
            retained.lease.close()
        }
    }

    private fun discoverSubjects(
        catalog: ActiveCatalog,
        retained: AuthoringLease? = null,
    ): SubjectDiscovery {
        val lease = retained ?: views.capture()
        return try {
            catalog.discoverSubjects(lease, evaluator)
        } finally {
            if (retained == null) lease.close()
        }
    }

    private fun scheduleLocked(state: InstanceState) {
        val catalog = activeCatalog ?: return
        val lease = views.capture()
        if (lease.root.catalog.generation != catalog.generation) {
            lease.close()
            return
        }
        val ticket =
            CheckTicket(
                instance = state.id,
                incarnation = catalog.incarnation,
                execution = CheckExecutionId(value = "check:${nextExecution.getAndIncrement()}"),
                catalog =
                    lease.root.catalog.generation,
            )
        state.ticket = ticket
        val job =
            scope.launch {
                val result = evaluator.evaluate(catalog, state.subject, CheckAdmissionTarget.CurrentFindings, ticket, lease)
                complete(state.id, result)
            }
        job.invokeOnCompletion { lease.close() }
        state.job = job
    }

    private fun retireJobLocked(job: Job?) {
        if (job == null) return
        job.cancel()
        if (job.isCompleted) return
        retiredJobs += job
        job.invokeOnCompletion {
            synchronized(lock) { retiredJobs -= job }
        }
    }

    private fun complete(
        id: CheckInstanceId,
        result: CheckResult,
    ) {
        val changed =
            synchronized(lock) {
                val state = instances[id] ?: return
                if (state.ticket != result.ticket) return
                dependencies.replace(id, result.expectations)
                val admission =
                    DefaultCheckAdmission(views, this).requireCurrentExecutionAndInputs(result) {
                        state.findings =
                            FindingSet(
                                ticket = result.ticket,
                                expectations = result.expectations,
                                outcome = result.outcome,
                                findings = result.findings,
                                status = FindingStatus.CURRENT,
                            )
                    }
                state.job = null
                when (admission) {
                    AdmissionResult.Published -> {
                        true
                    }

                    AdmissionResult.RetryRequired -> {
                        state.findings = state.findings?.copy(status = FindingStatus.OUTDATED)
                        scheduleLocked(state)
                        false
                    }

                    AdmissionResult.Captured,
                    AdmissionResult.Discarded,
                    -> {
                        dependencies.retire(id)
                        false
                    }
                }
            }
        if (changed) mutableFindingChanges.tryEmit(Unit)
    }

    private fun ensureOpen() {
        check(!closed) { "Realm check runtime is closed." }
    }

    private data class InstanceState(
        val id: CheckInstanceId,
        var subject: CheckSubject,
        var ticket: CheckTicket? = null,
        var job: Job? = null,
        var findings: FindingSet? = null,
    )
}

private data class ClosingRuntime(
    val jobs: List<Job>,
    val catalog: ActiveCatalog?,
)

private data class RetainedCatalog(
    val catalog: ActiveCatalog,
    val lease: ProviderLease,
)
