package com.typewritermc.realm.checking

import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CheckContext
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticReporter
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.FindingStatus
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.RealmChecks
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.OwnedRule
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.discovery.OwnedCheck
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.SnapshotLease
import com.typewritermc.types.ResourceId
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicLong

interface CheckScheduler : AutoCloseable {
    fun invalidate(changed: Set<InputIdentity>)

    suspend fun drain()
}

data class CapturedCheckReport(
    val snapshot: com.typewritermc.checking.SnapshotId,
    val catalog: com.typewritermc.checking.CatalogGeneration,
    val required: Set<CheckInstanceId>,
    val results: List<CheckResult>,
) {
    val complete: Boolean
        get() =
            results.mapTo(linkedSetOf()) { result -> result.ticket.instance } == required &&
                results.all { result -> result.outcome !is CheckOutcome.Incomplete }
}

class RealmCheckRuntime(
    private val snapshots: AuthoringSnapshotStore,
    dispatcher: CoroutineDispatcher = Dispatchers.Default,
    private val dependencies: ReverseDependencyIndex = DefaultReverseDependencyIndex(),
    private val checkInputs: RealmCheckInputs = RealmCheckInputs(),
    private val selectionPredicates: SelectionPredicateEvaluator = RealmSelectionPredicateEvaluator(),
    private val readLimits: SnapshotReadLimits = SnapshotReadLimits(),
    private val onFindingsChanged: suspend (CheckTicket) -> Unit = {},
) : CheckScheduler,
    CurrentCheckExecutions {
    private val lock = Any()
    private val scope = CoroutineScope(SupervisorJob() + dispatcher)
    private val nextIncarnation = AtomicLong()
    private val nextExecution = AtomicLong()
    private val nextDiagnostic = AtomicLong()
    private val expressions = RealmExpressionRuntime()
    private var activeCatalog: ActiveCatalog? = null
    private val instances = linkedMapOf<CheckInstanceId, InstanceState>()
    private val retiredJobs = linkedSetOf<Job>()
    private var closed = false

    suspend fun reloadCatalog() {
        val lease = snapshots.capture()
        val replacement =
            try {
                collectCatalog(lease)
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
                    state.findings = state.findings?.copy(status = FindingStatus.Outdated)
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

    override fun invalidate(changed: Set<InputIdentity>) {
        if (changed.isEmpty()) return
        val rediscover = RESOURCE_SELECTION_INPUT in changed || changed.any { it is InputIdentity.Form || it is InputIdentity.Membership }
        synchronized(lock) {
            if (closed) return
            val affected = dependencies.affectedBy(changed)
            affected.forEach { id ->
                val state = instances[id] ?: return@forEach
                state.findings = state.findings?.copy(status = FindingStatus.Outdated)
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
        var snapshot: SnapshotLease? = snapshots.retain(target.snapshot)
        var catalog: ActiveCatalog? = null
        return try {
            val captured = requireNotNull(snapshot)
            require(captured.root.catalog.generation == target.catalog) {
                "Captured check target uses a different catalog generation."
            }
            catalog = collectCatalog(captured)
            snapshot = null
            val active = requireNotNull(catalog)
            val subjects = discoverSubjects(active, active.snapshot).subjects
            val required = subjects.mapTo(linkedSetOf()) { subject -> subject.id }
            val admission = DefaultCheckAdmission(snapshots, this)
            val results =
                subjects.map { subject ->
                    val result = evaluate(active, subject, target)
                    when (admission.requireEvidenceForCapture(result, target)) {
                        AdmissionResult.Captured -> result
                        AdmissionResult.Discarded -> result.copy(outcome = CheckOutcome.Incomplete("captured evidence was discarded"))
                        AdmissionResult.RetryRequired -> result.copy(outcome = CheckOutcome.Incomplete("captured evidence requires retry"))
                        AdmissionResult.Published -> error("Captured admission cannot publish current findings.")
                    }
                }
            CapturedCheckReport(target.snapshot, target.catalog, required, results)
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
                        .forEach { state -> state.findings = state.findings?.copy(status = FindingStatus.Outdated) }
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
                            if (state.job == null && state.findings?.status != FindingStatus.Current) scheduleLocked(state)
                        }
                    }
                    tickets
                }
            removedTickets
                .distinctBy { ticket -> ticket.snapshot to ticket.catalog }
                .forEach { ticket -> scope.launch { onFindingsChanged(ticket) } }
        } finally {
            retained.lease.close()
        }
    }

    private fun discoverSubjects(
        catalog: ActiveCatalog,
        retained: SnapshotLease? = null,
    ): SubjectDiscovery {
        val lease = retained ?: snapshots.capture()
        return try {
            if (lease.root.catalog.generation != catalog.generation) return SubjectDiscovery(emptyList(), emptySet())
            val subjects = mutableListOf<CheckSubject>()
            val incompleteRules = linkedSetOf<RuleId>()
            catalog.plans.forEach { plan ->
                val reads = SnapshotReads(lease.originalView(), predicates = selectionPredicates, limits = readLimits)
                subjects +=
                    when (plan) {
                        is CheckPlan.Simple -> {
                            reads.discoverOccurrences(plan.owned.recipe.owner.owner).map { binding ->
                                plan.subject(binding.location)
                            }
                        }

                        is CheckPlan.Portable -> {
                            reads.discoverOccurrences(plan.recipe.origin.owner).flatMap { binding ->
                                if (!reads.matchesRepresentation(binding, plan.recipe.relativePath, plan.recipe.representationCondition)) {
                                    emptyList()
                                } else {
                                    reads.expand(binding.location, plan.recipe.relativePath).map { location ->
                                        plan.subject(location, binding.location)
                                    }
                                }
                            }
                        }

                        is CheckPlan.Each<*> -> {
                            reads.discoverResources(plan.type).map { binding -> plan.subject(binding.location) }
                        }

                        is CheckPlan.Realm -> {
                            listOf(plan.subject(REALM_LOCATION))
                        }

                        is CheckPlan.RegistrationFailure -> {
                            listOf(plan.subject(REALM_LOCATION))
                        }

                        is CheckPlan.DiscoveryFailure -> {
                            emptyList()
                        }
                    }
                val outcome = reads.health().outcome(plan.rule.origin)
                if (outcome != CheckOutcome.Finished) {
                    incompleteRules += plan.rule
                    val findings =
                        if (outcome is CheckOutcome.Incomplete) {
                            listOf(
                                diagnostic(
                                    plan.rule.origin,
                                    "check_discovery_incomplete",
                                    outcome.reason,
                                    DISCOVERY_LOCATION,
                                ),
                            )
                        } else {
                            emptyList()
                        }
                    subjects +=
                        CheckPlan
                            .DiscoveryFailure(
                                rule = plan.rule,
                                outcome = outcome,
                                findings = findings,
                                observed = reads.observations().map { it.identity },
                            ).subject(DISCOVERY_LOCATION)
                }
            }
            SubjectDiscovery(subjects, incompleteRules)
        } finally {
            if (retained == null) lease.close()
        }
    }

    private fun scheduleLocked(state: InstanceState) {
        val catalog = activeCatalog ?: return
        val lease = snapshots.capture()
        if (lease.root.catalog.generation != catalog.generation) {
            lease.close()
            return
        }
        val ticket =
            CheckTicket(
                instance = state.id,
                incarnation = catalog.incarnation,
                execution = CheckExecutionId("check:${nextExecution.getAndIncrement()}"),
                snapshot = lease.root.id,
                catalog = lease.root.catalog.generation,
            )
        state.ticket = ticket
        val job =
            scope.launch {
                val result = evaluate(catalog, state.subject, CheckAdmissionTarget.CurrentFindings, ticket, lease)
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
                dependencies.replace(id, result.observations)
                val admission = DefaultCheckAdmission(snapshots, this).requireCurrentExecutionAndInputs(result)
                state.job = null
                when (admission) {
                    AdmissionResult.Published -> {
                        state.findings =
                            FindingSet(result.ticket, result.observations, result.outcome, result.findings, FindingStatus.Current)
                        result.ticket
                    }

                    AdmissionResult.RetryRequired -> {
                        state.findings = state.findings?.copy(status = FindingStatus.Outdated)
                        scheduleLocked(state)
                        null
                    }

                    AdmissionResult.Captured,
                    AdmissionResult.Discarded,
                    -> {
                        dependencies.retire(id)
                        null
                    }
                }
            }
        if (changed != null) scope.launch { onFindingsChanged(changed) }
    }

    private fun evaluate(
        catalog: ActiveCatalog,
        subject: CheckSubject,
        target: CheckAdmissionTarget,
        ticket: CheckTicket? = null,
        suppliedLease: SnapshotLease? = null,
    ): CheckResult {
        val lease = suppliedLease ?: snapshots.retain((target as CheckAdmissionTarget.CapturedAcceptance).snapshot)
        val actualTicket =
            ticket ?: CheckTicket(
                instance = subject.id,
                incarnation = catalog.incarnation,
                execution = CheckExecutionId("capture:${nextExecution.getAndIncrement()}"),
                snapshot = lease.root.id,
                catalog = lease.root.catalog.generation,
            )
        val reads = SnapshotReads(lease.originalView(), predicates = selectionPredicates, limits = readLimits)
        val findings = mutableListOf<Diagnostic>()
        var explicitOutcome: CheckOutcome? = null
        return try {
            try {
                when (val plan = subject.plan) {
                    is CheckPlan.Simple -> {
                        val binding = reads.bindOccurrence(subject.location, plan.owned.recipe.owner.owner)
                        if (binding == null) {
                            explicitOutcome = CheckOutcome.Incomplete("check occurrence is no longer present")
                        } else {
                            val evaluation = with(reads) { checkInputs.evaluate(plan.owned.recipe, binding) }
                            explicitOutcome = evaluation.outcome
                            findings += evaluation.findings
                        }
                    }

                    is CheckPlan.Portable -> {
                        val binding = reads.bindOccurrence(subject.ownerLocation, plan.recipe.origin.owner)
                        val stillPresent =
                            binding != null &&
                                reads.matchesRepresentation(binding, plan.recipe.relativePath, plan.recipe.representationCondition) &&
                                subject.location in reads.expand(binding.location, plan.recipe.relativePath)
                        if (!stillPresent) {
                            explicitOutcome = CheckOutcome.Incomplete("portable rule occurrence is no longer present")
                        } else {
                            when (
                                val evaluation =
                                    expressions.evaluateBoolean(
                                        plan.ownedRule.descriptor.predicate,
                                        subject.location,
                                        reads,
                                    )
                            ) {
                                is com.typewritermc.authoring.Availability.Available -> {
                                    if (!evaluation.value) findings += portableDiagnostic(plan, subject, reads)
                                }

                                is com.typewritermc.authoring.Availability.Unavailable -> {
                                    explicitOutcome = CheckOutcome.NeedsInput(evaluation.locations)
                                }

                                is com.typewritermc.authoring.Availability.Failed -> {
                                    explicitOutcome =
                                        CheckOutcome.Failed(
                                            listOf(
                                                Diagnostic(
                                                    id = DiagnosticId("check:${nextDiagnostic.getAndIncrement()}"),
                                                    origin = plan.ownedRule.id.origin,
                                                    code = evaluation.diagnostic.code,
                                                    message = evaluation.diagnostic.message,
                                                    severity = DiagnosticSeverity.Error,
                                                    primary = evaluation.diagnostic.locations.firstOrNull(),
                                                    related = evaluation.diagnostic.locations.drop(1),
                                                ),
                                            ),
                                        )
                                }
                            }
                        }
                    }

                    is CheckPlan.Each<*> -> {
                        val binding = reads.bindResource(subject.location, plan.type.match)
                        if (binding == null) {
                            explicitOutcome = CheckOutcome.Incomplete("check subject is no longer present")
                        } else {
                            val reporter =
                                object : DiagnosticReporter {
                                    override fun report(diagnostic: Diagnostic) {
                                        findings += diagnostic
                                    }
                                }
                            val context = CheckContext.create(reads, reporter, diagnosticFactory(plan.rule.origin))
                            plan.invoke(context, binding)
                        }
                    }

                    is CheckPlan.Realm -> {
                        val reporter =
                            object : DiagnosticReporter {
                                override fun report(diagnostic: Diagnostic) {
                                    findings += diagnostic
                                }
                            }
                        val context = CheckContext.create(reads, reporter, diagnosticFactory(plan.rule.origin))
                        plan.callback(context)
                    }

                    is CheckPlan.RegistrationFailure -> {
                        explicitOutcome = CheckOutcome.Failed(listOf(plan.diagnostic))
                    }

                    is CheckPlan.DiscoveryFailure -> {
                        plan.observed.forEach(reads::observeInput)
                        explicitOutcome = plan.outcome
                        findings += plan.findings
                    }
                }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (failure: Exception) {
                explicitOutcome =
                    CheckOutcome.Failed(
                        listOf(
                            diagnostic(
                                subject.plan.rule.origin,
                                "check_callback_failed",
                                failure.message ?: failure::class.simpleName.orEmpty(),
                                subject.location,
                            ),
                        ),
                    )
            }
            val outcome = mergeOutcome(explicitOutcome, reads.health().outcome(subject.plan.rule.origin))
            CheckResult(actualTicket, outcome, reads.observations(), findings)
        } finally {
            if (suppliedLease == null) lease.close()
        }
    }

    private fun collectCatalog(snapshot: SnapshotLease): ActiveCatalog {
        val root = snapshot.root
        val incarnation = "catalog:${nextIncarnation.getAndIncrement()}"
        val leases = mutableListOf<ProviderLease>()
        val plans = mutableListOf<CheckPlan>()
        try {
            root.catalog.checks.forEach { owned ->
                leases += root.catalog.providers.retain(owned.origin)
                plans += CheckPlan.Simple(RuleId(owned.recipe.owner, 0), owned)
            }
            root.catalog.configuration.forEach { recipe ->
                recipe.rules.forEach { rule -> plans += CheckPlan.Portable(rule.id, recipe, rule) }
            }
            root.catalog.providers.checks().forEach { owned ->
                leases += root.catalog.providers.retain(owned.origin)
                val collector = RealmCheckCollector(owned)
                try {
                    owned.provider.run { collector.register() }
                    plans += collector.plans
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (failure: Exception) {
                    plans +=
                        CheckPlan.RegistrationFailure(
                            rule = RuleId(owned.ruleOrigin, 0),
                            diagnostic =
                                diagnostic(
                                    owned.ruleOrigin,
                                    "check_registration_failed",
                                    failure.message ?: failure::class.simpleName.orEmpty(),
                                    REALM_LOCATION,
                                ),
                        )
                }
            }
            return ActiveCatalog(root.catalog.generation, incarnation, plans, leases, snapshot)
        } catch (failure: Throwable) {
            closeAll(leases.asReversed(), failure)
            throw failure
        }
    }

    private fun diagnosticFactory(origin: RuleOrigin): (String, ValueLocation, List<ValueLocation>) -> Diagnostic =
        { message, at, related -> diagnostic(origin, "realm.check", message, at, related) }

    private fun diagnostic(
        origin: RuleOrigin,
        code: String,
        message: String,
        at: ValueLocation,
        related: List<ValueLocation> = emptyList(),
    ): Diagnostic =
        Diagnostic(
            id = DiagnosticId("check:${nextDiagnostic.getAndIncrement()}"),
            origin = origin,
            code = code,
            message = message,
            severity = DiagnosticSeverity.Error,
            primary = at,
            related = related,
        )

    private fun portableDiagnostic(
        plan: CheckPlan.Portable,
        subject: CheckSubject,
        reads: SnapshotReads,
    ): Diagnostic {
        val targets =
            plan.ownedRule.diagnostic.targets
                .flatMap { target ->
                    if (target == plan.recipe.relativePath) listOf(subject.location) else reads.expand(subject.ownerLocation, target)
                }.distinct()
        return Diagnostic(
            id = DiagnosticId("check:${nextDiagnostic.getAndIncrement()}"),
            origin = plan.ownedRule.id.origin,
            code = plan.ownedRule.diagnostic.code,
            message = plan.ownedRule.diagnostic.message,
            severity = plan.ownedRule.diagnostic.severity,
            primary = targets.firstOrNull() ?: subject.location,
            related = targets.drop(1),
        )
    }

    private fun ensureOpen() {
        check(!closed) { "Realm check runtime is closed." }
    }

    private inner class RealmCheckCollector(
        private val owned: OwnedCheck,
    ) : RealmChecks {
        val plans = mutableListOf<CheckPlan>()
        private var nextRegistration = 0

        override fun <D> each(
            type: DraftType<D>,
            check: CheckContext.(D) -> Unit,
        ) {
            val rule = RuleId(owned.ruleOrigin, nextRegistration++)
            plans += CheckPlan.Each(rule, type, check)
        }

        override fun realm(check: CheckContext.() -> Unit) {
            val rule = RuleId(owned.ruleOrigin, nextRegistration++)
            plans += CheckPlan.Realm(rule, check)
        }
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

private class ActiveCatalog(
    val generation: com.typewritermc.checking.CatalogGeneration,
    val incarnation: String,
    val plans: List<CheckPlan>,
    private val providerLeases: List<ProviderLease>,
    val snapshot: SnapshotLease,
) : AutoCloseable {
    private val lock = Any()
    private var references = 1
    private var closeRequested = false

    fun retain(): ProviderLease =
        synchronized(lock) {
            check(references > 0) { "Check catalog is closed." }
            references += 1
            ActiveCatalogLease(this)
        }

    override fun close() {
        release(owner = true)
    }

    private fun release(owner: Boolean) {
        val releaseResources =
            synchronized(lock) {
                if (owner) {
                    if (closeRequested) return
                    closeRequested = true
                }
                check(references > 0) { "Check catalog reference count is invalid." }
                references -= 1
                references == 0
            }
        if (releaseResources) closeAll(providerLeases.asReversed() + snapshot)
    }

    private class ActiveCatalogLease(
        private var catalog: ActiveCatalog?,
    ) : ProviderLease {
        override fun close() {
            val current = synchronized(this) { catalog.also { catalog = null } } ?: return
            current.release(owner = false)
        }
    }
}

private fun closeAll(
    closeables: Iterable<AutoCloseable>,
    primaryFailure: Throwable? = null,
) {
    var failure = primaryFailure
    closeables.forEach { closeable ->
        val closeFailure = runCatching { closeable.close() }.exceptionOrNull() ?: return@forEach
        if (failure == null) {
            failure = closeFailure
        } else {
            failure.addSuppressed(closeFailure)
        }
    }
    if (primaryFailure == null) failure?.let { throw it }
}

private sealed interface CheckPlan {
    val rule: RuleId

    data class Simple(
        override val rule: RuleId,
        val owned: OwnedCheckRecipe,
    ) : CheckPlan

    data class Portable(
        override val rule: RuleId,
        val recipe: ConfigurationRecipe,
        val ownedRule: OwnedRule,
    ) : CheckPlan

    data class Each<D>(
        override val rule: RuleId,
        val type: DraftType<D>,
        val callback: CheckContext.(D) -> Unit,
    ) : CheckPlan {
        fun invoke(
            context: CheckContext,
            binding: DraftBinding,
        ) {
            callback(context, type.bind(binding))
        }
    }

    data class Realm(
        override val rule: RuleId,
        val callback: CheckContext.() -> Unit,
    ) : CheckPlan

    data class RegistrationFailure(
        override val rule: RuleId,
        val diagnostic: Diagnostic,
    ) : CheckPlan

    data class DiscoveryFailure(
        override val rule: RuleId,
        val outcome: CheckOutcome,
        val findings: List<Diagnostic>,
        val observed: List<InputIdentity>,
    ) : CheckPlan
}

private data class SubjectDiscovery(
    val subjects: List<CheckSubject>,
    val incompleteRules: Set<RuleId>,
)

private data class CheckSubject(
    val plan: CheckPlan,
    val location: ValueLocation,
    val ownerLocation: ValueLocation = location,
) {
    val id: CheckInstanceId = CheckInstanceId(plan.rule, location)
}

private fun CheckPlan.subject(location: ValueLocation): CheckSubject = CheckSubject(this, location)

private fun CheckPlan.subject(
    location: ValueLocation,
    ownerLocation: ValueLocation,
): CheckSubject = CheckSubject(this, location, ownerLocation)

internal fun SnapshotReadHealth.outcome(origin: RuleOrigin): CheckOutcome =
    when {
        incomplete.isNotEmpty() -> {
            CheckOutcome.Incomplete(incomplete.joinToString())
        }

        failures.isNotEmpty() -> {
            CheckOutcome.Failed(
                failures.mapIndexed { index, failure ->
                    Diagnostic(
                        id = DiagnosticId("evaluation:$index:${failure.hashCode()}"),
                        origin = origin,
                        code = failure.code,
                        message = failure.message,
                        severity = DiagnosticSeverity.Error,
                        primary = failure.locations.firstOrNull(),
                        related = failure.locations.drop(1),
                    )
                },
            )
        }

        missing.isNotEmpty() -> {
            CheckOutcome.NeedsInput(missing)
        }

        else -> {
            CheckOutcome.Finished
        }
    }

private fun mergeOutcome(
    explicit: CheckOutcome?,
    tracked: CheckOutcome,
): CheckOutcome =
    when {
        explicit is CheckOutcome.Incomplete -> explicit
        tracked is CheckOutcome.Incomplete -> tracked
        explicit is CheckOutcome.Failed -> explicit
        tracked is CheckOutcome.Failed -> tracked
        explicit is CheckOutcome.NeedsInput -> explicit
        tracked is CheckOutcome.NeedsInput -> tracked
        explicit != null -> explicit
        else -> tracked
    }

private val REALM_LOCATION = ValueLocation(ResourceId("typewriter.realm"), ValuePath())
private val DISCOVERY_LOCATION =
    ValueLocation(
        ResourceId("typewriter.discovery"),
        ValuePath(
            listOf(
                com.typewritermc.authoring.PathSegment
                    .Field("subjects"),
            ),
        ),
    )
