package com.typewritermc.realm.compiler

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.PublishedContent
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.builtins.ListSerializer

data class PublicationAttempt(
    val id: PublicationId,
    val catalog: CatalogGeneration,
    val engineInputs: EngineImplementationInputs,
    val state: PublicationState,
)

sealed interface PublicationState {
    data object Checking : PublicationState

    data object Compiling : PublicationState

    data object Activating : PublicationState

    data object Complete : PublicationState

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : PublicationState

    data object Interrupted : PublicationState
}

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
    private val findings: () -> List<com.typewritermc.realm.checking.FindingSet> = { emptyList() },
) {
    private val gate = Mutex()
    private val evaluation = Mutex()
    private val lock = Any()
    private val wakeups = kotlinx.coroutines.channels.Channel<Unit>(kotlinx.coroutines.channels.Channel.CONFLATED)
    private var observer: kotlinx.coroutines.Job? = null
    private var prepared: Prepared? = null
    private var releasing: Release? = null
    private var closed = false
    private var invalidationRevision = 0L
    private val mutableView =
        kotlinx.coroutines.flow.MutableStateFlow(
            PublicationView(nextViewId(), PublicationStatus.Checking(PublicationBaseline.Initial, emptyList())),
        )
    val views: kotlinx.coroutines.flow.StateFlow<PublicationView> = mutableView

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
        scope: kotlinx.coroutines.CoroutineScope,
        changes: kotlinx.coroutines.flow.Flow<Long>,
    ) {
        check(observer == null)
        observer =
            scope.launch {
                kotlinx.coroutines.flow
                    .merge(changes.map { Unit }, wakeups.receiveAsFlow())
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
            var capture: com.typewritermc.realm.authoring.AuthoringLease? = null
            var retained = false
            var baseline: PublicationBaseline = PublicationBaseline.Initial
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
                    if (releasing == null) update(PublicationStatus.Checking(baseline, capturedFindings(captured.root)))
                }
                val assessment = acceptance.evaluate(captured)
                val compilationInputs = CompilationInputs(captured.root, assessment.resources)
                val compiled = with(compilationInputs) { compilation.compile() }
                val successful = compiled.filterIsInstance<com.typewritermc.engine.CompilationResult.Success>().map { it.artifact }
                val failed = compiled.filterIsInstance<com.typewritermc.engine.CompilationResult.Blocked>()
                val evidence = assessment.evidence.toMutableMap()
                val projectionLocations =
                    captured.root.projection.problems
                        .mapTo(linkedSetOf()) { it.location }
                failed.flatMap { it.diagnostics }.forEach { finding ->
                    if (finding.id !in evidence && finding.primary in projectionLocations) {
                        val dependencies = (listOfNotNull(finding.primary) + finding.related).map { it.resource }.distinct()
                        evidence[finding.id] =
                            DiagnosticEvidence(
                                captured.root.catalog.generation,
                                dependencies.map { id ->
                                    com.typewritermc.authoring.EditExpectation
                                        .Resource(id, captured.root.resources[id])
                                },
                            )
                    }
                }
                val blockers =
                    buildList {
                        addAll(assessment.findings.filter { it.severity == DiagnosticSeverity.Error }.map(::PublicationBlocker))
                        failed.flatMap { it.diagnostics }.forEach { finding ->
                            if (finding.severity == DiagnosticSeverity.Error) {
                                add(PublicationBlocker(finding))
                            }
                        }
                    }.distinctBy { it.diagnostic.id }
                val notices =
                    (assessment.findings + failed.flatMap { it.diagnostics })
                        .distinctBy { it.id }
                        .mapNotNull { finding ->
                            when (finding.severity) {
                                DiagnosticSeverity.Info -> PublicationNotice.Information(finding)
                                DiagnosticSeverity.Warning -> PublicationNotice.Warning(finding)
                                DiagnosticSeverity.Error -> null
                            }
                        }
                val status =
                    if (blockers.isNotEmpty()) {
                        PublicationStatus.Blocked(
                            baseline,
                            PublicationBlockers(blockers.first(), blockers.drop(1)),
                            notices,
                            PublicationComparison.confirmedChanges(selected, successful, compiled.mapTo(linkedSetOf()) { it.root }, inputs),
                            failed.map { it.root },
                        )
                    } else {
                        when (val comparison = PublicationComparison.between(selected, successful, inputs)) {
                            PublicationComparison.Unchanged -> {
                                if (selected != null && !restoreIfStillSelected(selected, successful)) {
                                    invalidate()
                                    return@withLock
                                }
                                selected?.let { PublicationStatus.Current(it.publication, notices) }
                                    ?: PublicationStatus.Empty(notices)
                            }

                            is PublicationComparison.Changed -> {
                                PublicationStatus.Ready(
                                    PublicationCandidateId(
                                        java.util.UUID
                                            .randomUUID()
                                            .toString(),
                                    ),
                                    baseline,
                                    comparison.delta,
                                    notices,
                                )
                            }
                        }
                    }
                val next = Prepared(captured, inputs, baseline, successful, status, revision, evidence)
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
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (fatal: VirtualMachineError) {
                throw fatal
            } catch (failure: Exception) {
                synchronized(lock) {
                    if (!closed && releasing == null) {
                        update(
                            PublicationStatus.Unavailable(
                                baseline,
                                PublicationFailure.EvaluationInterrupted(failure.message ?: "Saved content could not be checked"),
                                capture?.let { capturedFindings(it.root) }.orEmpty(),
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
                        if (!closed && mutableView.value.status is PublicationStatus.Ready &&
                            prepared != null && status is PublicationStatus.Ready && status.candidate == candidate &&
                            prepared.revision == invalidationRevision &&
                            prepared.lease.root === current && prepared.baseline == selected.baseline() &&
                            engine.compatible(prepared.engine)
                        ) {
                            Release(
                                prepared,
                                PublicationId(
                                    java.util.UUID
                                        .randomUUID()
                                        .toString(),
                                ),
                                PublicationActivationPhase.Storing,
                            ).also {
                                releasing = it
                                updateForPrepared(prepared)
                            }
                        } else {
                            null
                        }
                    }
                } ?: return when (mutableView.value.status) {
                    is PublicationStatus.Empty, is PublicationStatus.Current -> PublicationResult.NoChanges
                    else -> PublicationResult.CandidateChanged(mutableView.value.id)
                }
            release = frozen
            val inputs = frozen.candidate.engine
            val catalog = frozen.candidate.lease.root.catalog.generation
            val id = frozen.id
            attempts.start(id, catalog, inputs)

            suspend fun announce(state: PublicationState) {
                val attempt = PublicationAttempt(id, catalog, inputs, state)
                latest = attempt
                notifyTransition(attempt, onTransition)
            }
            announce(PublicationState.Compiling)
            val content = artifacts.store(id, catalog, inputs.token.value, frozen.candidate.artifacts)
            attempts.phase(id, PublicationState.Activating)
            synchronized(lock) {
                releasing = frozen.copy(phase = PublicationActivationPhase.Activating)
                prepared?.let(::updateForPrepared)
            }
            announce(PublicationState.Activating)
            installed =
                engine.activate(inputs) {
                    attempts.install(content)
                    true
                }
            if (!installed) {
                val blockers =
                    PublicationBlockers.from(
                        listOf(publicationDiagnostic("engine_inputs_changed", "Engine requirements changed. Review saved content again.")),
                    )
                attempts.blocked(id, blockers.all.map { it.diagnostic })
                announce(PublicationState.Blocked(blockers.all.map { it.diagnostic }))
                return PublicationResult.Blocked(blockers)
            }
            artifacts.selected(content)
            announce(PublicationState.Complete)
            return PublicationResult.Activated(id, content)
        } catch (failure: Throwable) {
            release?.let { current ->
                if (!installed) withContext(NonCancellable) { attempts.phase(current.id, PublicationState.Interrupted) }
                synchronized(lock) {
                    update(
                        PublicationStatus.Unavailable(
                            current.candidate.baseline,
                            PublicationFailure.PublicationInterrupted(current.id),
                            emptyList(),
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
                if (release != null && installed) update(PublicationStatus.Checking(PublicationBaseline.Selected(release.id), emptyList()))
            }
            gate.unlock()
            invalidate()
        }
    }

    private fun capturedFindings(root: com.typewritermc.realm.authoring.AuthoringView) =
        findings().map { set ->
            val current =
                set.status == com.typewritermc.checking.FindingStatus.Current &&
                    set.ticket.catalog == root.catalog.generation && root.values.conflicts(set.expectations).isEmpty()
            set.copy(
                status = if (current) com.typewritermc.checking.FindingStatus.Current else com.typewritermc.checking.FindingStatus.Outdated,
            )
        }

    private fun updateForPrepared(next: Prepared) {
        val active = releasing
        if (active == null) {
            update(next.status, next.evidence)
            return
        }
        val status = active.candidate.status as PublicationStatus.Ready
        val pending = next.status
        val pendingRoots = (pending as? PublicationStatus.Blocked)?.pendingRoots.orEmpty()
        val later =
            if (next === active.candidate) {
                PublicationPendingReview()
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
                    blockers = (pending as? PublicationStatus.Blocked)?.blockers?.all.orEmpty(),
                    notices =
                        when (pending) {
                            is PublicationStatus.Ready -> pending.notices
                            is PublicationStatus.Blocked -> pending.notices
                            is PublicationStatus.Empty -> pending.notices
                            is PublicationStatus.Current -> pending.notices
                            else -> emptyList()
                        },
                )
            }
        update(PublicationStatus.Publishing(active.id, active.phase, status.changes, later), next.evidence)
    }

    private fun update(
        status: PublicationStatus,
        evidence: Map<DiagnosticId, DiagnosticEvidence> = emptyMap(),
    ) {
        mutableView.value = PublicationView(nextViewId(), status, evidence)
    }

    private suspend fun notifyTransition(
        attempt: PublicationAttempt,
        callback: suspend (PublicationAttempt) -> Unit,
    ) {
        try {
            callback(attempt)
        } catch (
            cancelled: CancellationException,
        ) {
            throw cancelled
        } catch (fatal: VirtualMachineError) {
            throw fatal
        } catch (_: Exception) {
        }
    }

    private data class Prepared(
        val lease: com.typewritermc.realm.authoring.AuthoringLease,
        val engine: EngineImplementationInputs,
        val baseline: PublicationBaseline,
        val artifacts: List<com.typewritermc.engine.CompiledArtifact>,
        val status: PublicationStatus,
        val revision: Long,
        val evidence: Map<DiagnosticId, DiagnosticEvidence>,
    )

    private data class Release(
        val candidate: Prepared,
        val id: PublicationId,
        val phase: PublicationActivationPhase,
    )
}

private fun PublishedContent?.baseline(): PublicationBaseline =
    this?.let { PublicationBaseline.Selected(it.publication) } ?: PublicationBaseline.Initial

private fun nextViewId() =
    PublicationViewId(
        java.util.UUID
            .randomUUID()
            .toString(),
    )

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
                    "inputs" to publicationsCodec.encode(EngineImplementationInputs.serializer(), engineInputs),
                ),
            ).take(0)
    }

    override suspend fun phase(
        id: PublicationId,
        phase: PublicationState,
    ) {
        require(phase == PublicationState.Compiling || phase == PublicationState.Activating || phase == PublicationState.Interrupted)
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
                    "findings" to publicationsCodec.encode(ListSerializer(Diagnostic.serializer()), findings),
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
                            "result" to publicationsCodec.encode(PublishedContent.serializer(), result),
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
        PublicationState.Checking -> "checking"
        PublicationState.Compiling -> "compiling"
        PublicationState.Activating -> "activating"
        PublicationState.Complete -> "complete"
        is PublicationState.Blocked -> "blocked"
        PublicationState.Interrupted -> "interrupted"
    }

internal val publicationsCodec = StructuredDatabaseCodec(authoringStorageJson)

internal fun publicationDiagnostic(
    code: String,
    message: String,
): Diagnostic =
    Diagnostic(
        id = DiagnosticId("publication:${code.hashCode().toUInt().toString(16)}"),
        origin = RuleOrigin(PUBLICATION_TYPE, 0),
        code = code,
        message = message,
        severity = DiagnosticSeverity.Error,
        primary = null,
        related = emptyList(),
    )

private val PUBLICATION_TYPE = TypeDefinitionId(TypeId.Qualified("typewriter", "publication"), 1)
