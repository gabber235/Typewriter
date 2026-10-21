package com.typewritermc.realm.compiler

import build.skir.Serializers
import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.realm.repository.utils.encodeSkir
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanScope
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unknownVariant
import io.opentelemetry.context.Context
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.publication.DiagnosticEvidence
import skirout.editor.v1.publication.EngineImplementationInputs
import skirout.editor.v1.publication.PublicationActivationPhase
import skirout.editor.v1.publication.PublicationAttempt
import skirout.editor.v1.publication.PublicationBaseline
import skirout.editor.v1.publication.PublicationBlockers
import skirout.editor.v1.publication.PublicationCandidateId
import skirout.editor.v1.publication.PublicationFailure
import skirout.editor.v1.publication.PublicationPendingReview
import skirout.editor.v1.publication.PublicationState
import skirout.editor.v1.publication.PublicationStatus
import skirout.editor.v1.publication.PublicationView
import skirout.editor.v1.publication.PublicationViewId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId
import java.util.UUID

sealed interface PublicationResult {
    data object Publishing : PublicationResult

    data class Activated(
        val publication: PublicationId,
        val content: PublishedContent,
    ) : PublicationResult

    data class Blocked(
        val blockers: PublicationBlockers,
    ) : PublicationResult

    data object NoChanges : PublicationResult

    data class CandidateChanged(
        val view: PublicationViewId,
    ) : PublicationResult

    data class Interrupted(
        val publication: PublicationId,
    ) : PublicationResult
}

interface PublicationAttemptStore {
    suspend fun start(
        id: PublicationId,
        catalog: CatalogGeneration,
        engineInputs: EngineImplementationInputs,
    )

    suspend fun phase(
        id: PublicationId,
        phase: PublicationState,
    )

    suspend fun blocked(
        id: PublicationId,
        findings: List<Diagnostic>,
    )

    suspend fun install(result: PublishedContent)

    suspend fun interruptUnfinished()
}

/**
 * Owns saved content assessment, the reviewed candidate, and selection of a new immutable publication.
 *
 * Refresh evaluates a retained saved view without storing blobs or changing selection. Publish freezes only
 * the current Ready candidate after rechecking saved root, baseline, invalidation revision, and engine inputs.
 * Blob storage precedes transactional selection of the descriptor. Engines consume that selection independently.
 *
 * One release runs at a time, while later saved edits can produce the next review beside the frozen release.
 * Candidate leases keep their catalog callbacks alive through assessment and release. Closing stops observation
 * and waits for the active release before dropping retained preparation state.
 */
internal class RealmPublicationCoordinator(
    private val acceptance: PublicationAcceptance,
    private val attempts: PublicationAttemptStore,
    private val artifacts: RegisteredCompiledArtifactStore,
    private val engine: EngineImplementationSource,
    private val compilation: CompiledArtifactProducerRegistry,
    private val results: PublicationResults,
    private val findings: () -> List<FindingSet>,
) {
    private val gate = Mutex()
    private val evaluation = Mutex()
    private val lock = Any()
    private val wakeups = Channel<Unit>(Channel.CONFLATED)
    private var observer: Job? = null
    private var prepared: Prepared? = null
    private var releasing: Release? = null
    private var closed = false
    private var invalidationRevision = 0L
    private val mutableView =
        MutableStateFlow(
            PublicationView(
                id = nextViewId(),
                status = PublicationStatus.createChecking(baseline = PublicationBaseline.INITIAL, findings = emptyList()),
            ),
        )
    val views: StateFlow<PublicationView> = mutableView

    @Volatile private var latest: PublicationAttempt? = null

    fun currentAttempt(): PublicationAttempt? = latest

    private suspend fun restoreIfStillSelected(
        expected: PublishedContent,
        compiled: List<CompiledArtifact>,
    ): Boolean =
        gate.withLock {
            if (synchronized(lock) { closed }) return@withLock false
            if (results.selected() != expected) return@withLock false
            artifacts.restoreSelected(expected, compiled)
            true
        }

    suspend fun recoverInterrupted() =
        gate.withLock {
            attempts.interruptUnfinished()
            artifacts.reconcile(results.selected())
        }

    fun start(
        scope: CoroutineScope,
        changes: Flow<Long>,
    ) {
        check(observer == null)
        observer =
            scope.launch {
                merge(changes.map { Unit }, wakeups.receiveAsFlow())
                    .collectLatest { refresh() }
            }
    }

    /** Coalesces publication completion with saved input invalidations. */
    fun invalidate() {
        synchronized(lock) { invalidationRevision++ }
        wakeups.trySend(Unit)
    }

    suspend fun close() {
        synchronized(lock) { closed = true }
        observer?.cancelAndJoin()
        observer = null
        wakeups.close()
        gate.withLock {
            synchronized(lock) {
                prepared?.lease?.close()
                prepared = null
            }
        }
    }

    suspend fun refresh() =
        evaluation.withLock {
            val revision = synchronized(lock) { invalidationRevision }
            var capture: AuthoringLease? = null
            var retained = false
            var baseline: PublicationBaseline = PublicationBaseline.INITIAL
            try {
                val captured = acceptance.capture()
                capture = captured
                val selected = results.selected()
                baseline = selected.baseline()
                val inputs = engine.capture()
                val alreadyPrepared =
                    synchronized(lock) {
                        val current = prepared
                        current != null && current.lease.root === captured.root && current.baseline == baseline &&
                            current.engine == inputs &&
                            current.revision == revision
                    }
                if (alreadyPrepared) return@withLock
                synchronized(lock) {
                    if (closed) return@withLock
                    if (releasing ==
                        null
                    ) {
                        update(PublicationStatus.createChecking(baseline = baseline, findings = capturedFindings(captured.root)))
                    }
                }
                val assessment = acceptance.evaluate(captured)
                val compilationInputs = CompilationInputs(captured.root, assessment.resources)
                val compiled = with(compilationInputs) { compilation.compile() }
                val successful = compiled.filterIsInstance<CompilationResult.Success>().map { it.artifact }
                val failed = compiled.filterIsInstance<CompilationResult.Blocked>()
                val evidence = assessment.evidence.toMutableMap()
                val projectionLocations =
                    captured.root.projection.problems
                        .mapTo(linkedSetOf()) { it.location }
                failed.flatMap { it.diagnostics }.forEach { finding ->
                    if (finding.id !in evidence && finding.primary in projectionLocations) {
                        val dependencies = (listOfNotNull(finding.primary) + finding.related).map { it.resource }.distinct()
                        evidence[finding.id] =
                            DiagnosticEvidence(
                                catalog = captured.root.catalog.generation,
                                expectations =
                                    dependencies.map { id ->
                                        EditExpectation.createResource(id = id, expected = captured.root.resources[id])
                                    },
                            )
                    }
                }
                val blockers =
                    (assessment.findings + failed.flatMap { it.diagnostics })
                        .filter { it.severity == DiagnosticSeverity.ERROR }
                        .distinctBy { it.id }
                        .map { finding -> finding.blocker(evidence[finding.id]) }
                val notices =
                    (assessment.findings + failed.flatMap { it.diagnostics })
                        .distinctBy { it.id }
                        .mapNotNull { finding -> finding.notice(evidence[finding.id]) }
                val status =
                    if (blockers.isNotEmpty()) {
                        PublicationStatus.createBlocked(
                            baseline = baseline,
                            blockers = blockers.blockers(),
                            notices = notices,
                            confirmedChanges =
                                PublicationComparison.confirmedChanges(
                                    selected,
                                    successful,
                                    compiled.mapTo(linkedSetOf()) { it.root },
                                    inputs,
                                ),
                            pendingRoots = failed.map { it.root },
                        )
                    } else {
                        when (val comparison = PublicationComparison.between(selected, successful, inputs)) {
                            PublicationComparison.Unchanged -> {
                                if (selected != null && !restoreIfStillSelected(selected, successful)) {
                                    invalidate()
                                    return@withLock
                                }
                                selected?.let { PublicationStatus.createCurrent(selected = it.publication, notices = notices) }
                                    ?: PublicationStatus.createEmpty(notices = notices)
                            }

                            is PublicationComparison.Changed -> {
                                PublicationStatus.createReady(
                                    candidate = PublicationCandidateId(value = UUID.randomUUID().toString()),
                                    baseline = baseline,
                                    changes = comparison.delta,
                                    notices = notices,
                                )
                            }
                        }
                    }
                val next = Prepared(captured, inputs, baseline, successful, status, revision)
                acceptance.withCurrent { current ->
                    synchronized(lock) {
                        if (!closed && current === captured.root && engine.compatible(inputs) && invalidationRevision == revision) {
                            val old = prepared
                            prepared = next
                            retained = true
                            if (old !== releasing?.candidate) old?.lease?.close()
                            updateForPrepared(next)
                        }
                    }
                }
            } catch (failure: Exception) {
                failure.rethrowExceptional()
                synchronized(lock) {
                    if (!closed && releasing == null) {
                        update(
                            PublicationStatus.createUnavailable(
                                baseline = baseline,
                                failure =
                                    PublicationFailure.EvaluationInterruptedWrapper(
                                        failure.message ?: "Saved content could not be checked",
                                    ),
                                findings = capture?.let { capturedFindings(it.root) }.orEmpty(),
                            ),
                        )
                    }
                }
            } finally {
                if (!retained) capture?.close()
            }
        }

    suspend fun publish(
        candidate: PublicationCandidateId,
        onTransition: suspend (PublicationAttempt) -> Unit = {},
    ): PublicationResult {
        if (!gate.tryLock()) return PublicationResult.Publishing
        var release: Release? = null
        var installed = false
        try {
            val selected = results.selected()
            val frozen =
                acceptance.withCurrent { current ->
                    synchronized(lock) {
                        val prepared = prepared
                        val status = prepared?.status
                        if (!closed && mutableView.value.status is PublicationStatus.ReadyWrapper &&
                            prepared != null && status is PublicationStatus.ReadyWrapper && status.value.candidate == candidate &&
                            prepared.revision == invalidationRevision &&
                            prepared.lease.root === current && prepared.baseline == selected.baseline() &&
                            engine.compatible(prepared.engine)
                        ) {
                            Release(
                                prepared,
                                PublicationId(value = UUID.randomUUID().toString()),
                                PublicationActivationPhase.STORING,
                            ).also {
                                releasing = it
                                updateForPrepared(prepared)
                            }
                        } else {
                            null
                        }
                    }
                } ?: return when (mutableView.value.status) {
                    is PublicationStatus.EmptyWrapper, is PublicationStatus.CurrentWrapper -> PublicationResult.NoChanges
                    else -> PublicationResult.CandidateChanged(mutableView.value.id)
                }
            release = frozen
            val inputs = frozen.candidate.engine
            val catalog = frozen.candidate.lease.root.catalog.generation
            val id = frozen.id
            attempts.start(id, catalog, inputs)

            suspend fun announce(state: PublicationState) {
                val attempt = PublicationAttempt(id = id, catalog = catalog, engineInputs = inputs, state = state)
                latest = attempt
                notifyTransition(attempt, onTransition)
            }
            announce(PublicationState.COMPILING)
            val content = artifacts.store(id, catalog, inputs.token.value, frozen.candidate.artifacts)
            attempts.phase(id, PublicationState.ACTIVATING)
            synchronized(lock) {
                releasing = frozen.copy(phase = PublicationActivationPhase.ACTIVATING)
                prepared?.let(::updateForPrepared)
            }
            announce(PublicationState.ACTIVATING)
            installed =
                engine.activate(inputs) {
                    attempts.install(content)
                    true
                }
            if (!installed) {
                val findings =
                    listOf(publicationDiagnostic("engine_inputs_changed", "Engine requirements changed. Review saved content again."))
                attempts.blocked(id, findings)
                announce(PublicationState.BlockedWrapper(findings))
                return PublicationResult.Blocked(findings.map { it.blocker(evidence = null) }.blockers())
            }
            artifacts.selected(content)
            announce(PublicationState.COMPLETE)
            return PublicationResult.Activated(id, content)
        } catch (failure: Throwable) {
            release?.let { current ->
                if (!installed) withContext(NonCancellable) { attempts.phase(current.id, PublicationState.INTERRUPTED) }
                synchronized(lock) {
                    update(
                        PublicationStatus.createUnavailable(
                            baseline = current.candidate.baseline,
                            failure = PublicationFailure.PublicationInterruptedWrapper(current.id),
                            findings = emptyList(),
                        ),
                    )
                }
            }
            throw failure
        } finally {
            synchronized(lock) {
                releasing = null
                release?.candidate?.let { frozen ->
                    if (prepared === frozen) prepared = null
                    frozen.lease.close()
                }
                if (release != null &&
                    installed
                ) {
                    update(
                        PublicationStatus.createChecking(
                            baseline = PublicationBaseline.SelectedWrapper(release.id),
                            findings = emptyList(),
                        ),
                    )
                }
            }
            gate.unlock()
            invalidate()
        }
    }

    private fun capturedFindings(root: AuthoringView) =
        findings().map { set ->
            val current =
                set.status == FindingStatus.CURRENT &&
                    set.ticket.catalog == root.catalog.generation &&
                    root.values.conflicts(set.expectations).isEmpty()
            set.copy(
                status = if (current) FindingStatus.CURRENT else FindingStatus.OUTDATED,
            )
        }

    private fun updateForPrepared(next: Prepared) {
        val active = releasing
        if (active == null) {
            update(next.status)
            return
        }
        val status = active.candidate.status as PublicationStatus.ReadyWrapper
        val pending = (next.status as? PublicationStatus.BlockedWrapper)?.value
        val pendingRoots = pending?.pendingRoots.orEmpty()
        val later =
            if (next === active.candidate) {
                PublicationPendingReview.partial()
            } else {
                PublicationPendingReview(
                    findings = capturedFindings(next.lease.root),
                    confirmedChanges =
                        PublicationComparison.confirmedChanges(
                            PublicationRuntimeContent.prepared(active.candidate.artifacts, active.candidate.engine),
                            next.artifacts,
                            next.artifacts.mapTo(linkedSetOf()) { it.root } + pendingRoots,
                            next.engine,
                        ),
                    pendingRoots = pendingRoots,
                    blockers = pending?.blockers?.all.orEmpty(),
                    notices = next.status.notices,
                )
            }
        update(
            PublicationStatus.createPublishing(
                publication = active.id,
                phase = active.phase,
                releasing = status.value.changes,
                next = later,
            ),
        )
    }

    private fun update(status: PublicationStatus) {
        mutableView.value = PublicationView(id = nextViewId(), status = status)
    }

    private suspend fun notifyTransition(
        attempt: PublicationAttempt,
        callback: suspend (PublicationAttempt) -> Unit,
    ) {
        try {
            callback(attempt)
        } catch (failure: Exception) {
            failure.rethrowExceptional()
            Context.current().mainSpanScope()?.recordDegraded(TRANSITION_NOTIFICATION_FAILURE, failure)
        }
    }

    private data class Prepared(
        val lease: AuthoringLease,
        val engine: EngineImplementationInputs,
        val baseline: PublicationBaseline,
        val artifacts: List<CompiledArtifact>,
        val status: PublicationStatus,
        val revision: Long,
    )

    private data class Release(
        val candidate: Prepared,
        val id: PublicationId,
        val phase: PublicationActivationPhase,
    )
}

private fun PublishedContent?.baseline(): PublicationBaseline =
    this?.let { PublicationBaseline.SelectedWrapper(it.publication) } ?: PublicationBaseline.INITIAL

private fun nextViewId() = PublicationViewId(value = UUID.randomUUID().toString())

internal class SurrealPublicationAttemptStore(
    private val database: Surreal,
) : PublicationAttemptStore {
    override suspend fun start(
        id: PublicationId,
        catalog: CatalogGeneration,
        engineInputs: EngineImplementationInputs,
    ) {
        database
            .query(
                "CREATE ONLY \$attempt CONTENT { catalog: \$catalog, engine_inputs: \$inputs, state: 'checking', selected: false, findings: [] };",
                mapOf(
                    "attempt" to RecordId("publication_attempt", id.value),
                    "catalog" to catalog.value,
                    "inputs" to encodeSkir(EngineImplementationInputs.serializer, engineInputs),
                ),
            ).take(0)
    }

    override suspend fun phase(
        id: PublicationId,
        phase: PublicationState,
    ) {
        require(phase == PublicationState.COMPILING || phase == PublicationState.ACTIVATING || phase == PublicationState.INTERRUPTED)
        database
            .query(
                "UPDATE ONLY \$attempt SET state = \$state, updated_at = time::now() WHERE state IN ['checking', 'compiling', 'activating'];",
                mapOf("attempt" to RecordId("publication_attempt", id.value), "state" to phase.storageName()),
            ).take(0)
    }

    override suspend fun blocked(
        id: PublicationId,
        findings: List<Diagnostic>,
    ) {
        database
            .query(
                "UPDATE ONLY \$attempt SET state = 'blocked', findings = \$findings, updated_at = time::now() WHERE state IN ['checking', 'compiling', 'activating'];",
                mapOf(
                    "attempt" to RecordId("publication_attempt", id.value),
                    "findings" to encodeSkir(Serializers.list(Diagnostic.serializer), findings),
                ),
            ).take(0)
    }

    override suspend fun install(result: PublishedContent) {
        database.inTransaction { transaction ->
            transaction.query("UPDATE publication_attempt SET selected = false WHERE selected = true;").take(0)
            val installed =
                transaction
                    .query(
                        "UPDATE ONLY \$attempt SET state = 'complete', selected = true, result = \$result, updated_at = time::now() " +
                            "WHERE state = 'activating' RETURN VALUE id;",
                        mapOf(
                            "attempt" to RecordId("publication_attempt", result.publication.value),
                            "result" to encodeSkir(PublishedContent.serializer, result),
                        ),
                    ).take(0)
            check(!installed.isNone && !installed.isNull) { "Publication was not ready for installation" }
        }
    }

    override suspend fun interruptUnfinished() {
        database
            .query(
                "UPDATE publication_attempt SET state = 'interrupted', updated_at = time::now() WHERE state IN ['checking', 'compiling', 'activating'];",
            ).take(0)
    }
}

internal fun PublicationState.storageName(): String =
    when (this) {
        PublicationState.CHECKING -> "checking"
        PublicationState.COMPILING -> "compiling"
        PublicationState.ACTIVATING -> "activating"
        PublicationState.COMPLETE -> "complete"
        is PublicationState.BlockedWrapper -> "blocked"
        PublicationState.INTERRUPTED -> "interrupted"
        else -> unknownVariant(this)
    }

private val TRANSITION_NOTIFICATION_FAILURE = ErrorSlug.of("realm-publication-transition-notification-failed")
