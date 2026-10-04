package com.typewritermc.realm.compiler

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactManifest
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.repository.utils.StorageRetryPolicy
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.catalog.Resolution
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withContext
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

data class PublicationAttempt(
    val id: PublicationId,
    val capture: SnapshotId,
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
        val manifest: String,
    ) : PublicationResult

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : PublicationResult

    data class Interrupted(
        val publication: PublicationId,
    ) : PublicationResult
}

interface PublicationAttemptStore {
    suspend fun claim(attempt: PublicationAttempt): Boolean

    suspend fun transition(
        id: PublicationId,
        from: PublicationState,
        to: PublicationState,
    ): Boolean

    suspend fun unfinished(): List<PublicationAttempt>
}

internal class RealmPublicationCoordinator(
    private val acceptance: PublicationAcceptance,
    private val attempts: PublicationAttemptStore,
    private val content: RegisteredCompiledContentRepository,
    private val artifacts: RegisteredCompiledArtifactStore,
    private val engine: EngineImplementationSource,
) {
    private val slot = Mutex()

    @Volatile
    private var latest: PublicationAttempt? = null

    fun currentAttempt(): PublicationAttempt? = latest

    suspend fun recoverInterrupted(): List<PublicationResult> =
        attempts.unfinished().map { attempt ->
            val active = content.activePublication()
            if (active == attempt.id) {
                val manifest = requireNotNull(content.activeManifest())
                transition(attempt, attempt.state, PublicationState.Complete)
                PublicationResult.Activated(attempt.id, manifest.digest.value)
            } else {
                transition(attempt, attempt.state, PublicationState.Interrupted)
                PublicationResult.Interrupted(attempt.id)
            }
        }

    suspend fun publish(
        id: PublicationId,
        capture: SnapshotId,
        catalog: CatalogGeneration,
        onTransition: suspend (PublicationAttempt) -> Unit = {},
    ): PublicationResult =
        publishLocked(capture, catalog, onTransition) {
            PublicationAttempt(
                id = id,
                capture = capture,
                catalog = catalog,
                engineInputs = engine.capture(),
                state = PublicationState.Checking,
            )
        }

    suspend fun publish(
        request: PublicationAttempt,
        onTransition: suspend (PublicationAttempt) -> Unit = {},
    ): PublicationResult = publishLocked(request.capture, request.catalog, onTransition) { request }

    private suspend fun publishLocked(
        requestedSnapshot: SnapshotId,
        requestedCatalog: CatalogGeneration,
        onTransition: suspend (PublicationAttempt) -> Unit,
        requestFactory: () -> PublicationAttempt,
    ): PublicationResult {
        if (!slot.tryLock()) return PublicationResult.Publishing
        var request: PublicationAttempt? = null
        var capture: com.typewritermc.realm.authoring.SnapshotLease? = null
        var claimed = false
        var state: PublicationState = PublicationState.Checking
        try {
            val retained = acceptance.retain(requestedSnapshot, requestedCatalog)
            capture = retained
            request = requestFactory()
            if (request.state != PublicationState.Checking) return PublicationResult.Publishing
            require(request.capture == requestedSnapshot && request.catalog == requestedCatalog) {
                "Publication request changed its retained capture."
            }
            if (!attempts.claim(request)) return PublicationResult.Publishing
            claimed = true
            latest = request
            notifyTransition(request, onTransition)

            suspend fun move(to: PublicationState) {
                val next = transition(request, state, to)
                state = to
                notifyTransition(next, onTransition)
            }

            val accepted = acceptance.evaluate(retained)
            if (accepted is AcceptanceResult.Blocked) {
                move(PublicationState.Blocked(accepted.findings))
                return PublicationResult.Blocked(accepted.findings)
            }
            accepted as AcceptanceResult.Accepted
            if (!engine.compatible(request.engineInputs)) {
                val findings = listOf(publicationDiagnostic("engine_inputs_changed", "Engine implementation inputs changed."))
                move(PublicationState.Blocked(findings))
                return PublicationResult.Blocked(findings)
            }
            move(PublicationState.Compiling)
            val compiled = compile(retained.root, accepted.proof.bindingRequirements, request.engineInputs)
            if (compiled is CompilationOutcome.Blocked) {
                move(PublicationState.Blocked(compiled.findings))
                return PublicationResult.Blocked(compiled.findings)
            }
            compiled as CompilationOutcome.Ready
            move(PublicationState.Activating)
            val activation =
                artifacts.store(
                    activationRevision = content.nextActivationRevision(),
                    manifest = compiled.manifest,
                    artifacts = compiled.artifacts,
                    previousActivation = content.activeActivation(),
                )
            val published =
                engine.activate(request.engineInputs) {
                    content.publish(request.id, compiled.manifest, compiled.artifacts, activation)
                }
            if (!published) {
                val findings =
                    listOf(publicationDiagnostic("engine_inputs_changed", "Engine implementation inputs changed before activation."))
                move(PublicationState.Blocked(findings))
                return PublicationResult.Blocked(findings)
            }
            move(PublicationState.Complete)
            return PublicationResult.Activated(request.id, compiled.manifest.digest.value)
        } catch (failure: Throwable) {
            val activeRequest = request
            if (claimed && activeRequest != null && !state.isTerminal()) {
                withContext(NonCancellable) {
                    runCatching {
                        val interrupted = transition(activeRequest, state, PublicationState.Interrupted)
                        state = PublicationState.Interrupted
                        notifyTransition(interrupted, onTransition)
                    }.exceptionOrNull()
                        ?.let(failure::addSuppressed)
                }
            }
            throw failure
        } finally {
            capture?.close()
            slot.unlock()
        }
    }

    private suspend fun transition(
        attempt: PublicationAttempt,
        from: PublicationState,
        to: PublicationState,
    ): PublicationAttempt {
        check(attempts.transition(attempt.id, from, to))
        latest = attempt.copy(state = to)
        return requireNotNull(latest)
    }

    private suspend fun notifyTransition(
        attempt: PublicationAttempt,
        onTransition: suspend (PublicationAttempt) -> Unit,
    ) {
        try {
            onTransition(attempt)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (fatal: VirtualMachineError) {
            throw fatal
        } catch (_: Exception) {
            return
        }
    }

    private fun compile(
        root: com.typewritermc.realm.authoring.AuthoredSnapshotRoot,
        bindingRequirements: List<NativeBindingRequirement>,
        engineInputs: EngineImplementationInputs,
    ): CompilationOutcome {
        val ownership =
            root.catalog.relations
                .filter { relation ->
                    RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in relation.families
                }.mapTo(linkedSetOf(), RelationContract::id)
        val compiler = PageCompiler(ownership, bindingRequirements.associateBy(NativeBindingRequirement::actual))
        val pageRoots =
            root.resources
                .filterValues { record ->
                    val selection = record.configuration as? com.typewritermc.authoring.TypeSelection.Complete
                    selection != null && root.catalog.checked.isNominalSubtype(selection.use.definition, PAGE_CONTRACT_TYPE)
                }.keys
                .sortedBy { it.value }
        val results = pageRoots.map { page -> page to compiler.compile(page, root) }
        val blocked = results.mapNotNull { (_, result) -> (result as? PageCompileResult.Blocked)?.diagnostics }.flatten()
        if (blocked.isNotEmpty()) return CompilationOutcome.Blocked(blocked.map(::publicationDiagnostic))
        val compiled =
            results.map { (page, result) ->
                val shard = (result as PageCompileResult.Success).shard
                CompiledArtifact(
                    root = CompilationRoot(PAGE_PROJECTION, page),
                    formatRevision = shard.formatRevision,
                    mediaType = PAGE_MEDIA_TYPE,
                    inputFingerprint = shard.inputFingerprint,
                    semanticDigest = shard.digest,
                    payload = publicationJson.encodeToString(shard).encodeToByteArray(),
                )
            }
        val references =
            compiled.map { artifact ->
                CompiledArtifactReference(
                    root = artifact.root,
                    formatRevision = artifact.formatRevision,
                    mediaType = artifact.mediaType,
                    semanticDigest = artifact.semanticDigest,
                )
            }
        val manifest =
            CompiledArtifactManifest(
                formatRevision = CURRENT_COMPILER_FORMAT,
                digest = manifestDigest(root.id, root.catalog.generation, references),
                sourceRevision = root.id.value,
                catalogRevision = root.catalog.generation.value,
                implementationToken = engineInputs.token.value,
                runtimeSignatures = engineInputs.signatures,
                artifacts = references,
            )
        return CompilationOutcome.Ready(manifest, compiled)
    }
}

internal class SurrealPublicationAttemptStore(
    private val database: Surreal,
    private val retryPolicy: StorageRetryPolicy = StorageRetryPolicy(),
) : PublicationAttemptStore {
    override suspend fun claim(attempt: PublicationAttempt): Boolean =
        retryPolicy.retryWriteConflicts {
            database.inTransaction { transaction ->
                val claimed =
                    transaction
                        .query(
                            "UPDATE ONLY publication_slot:current SET owner = \$owner WHERE owner IS NONE RETURN VALUE owner;",
                            mapOf("owner" to attempt.id.value),
                        ).take(0)
                if (claimed.isNone || claimed.isNull) return@inTransaction false
                transaction
                    .query(
                        "CREATE ONLY \$attempt CONTENT { capture: \$capture, catalog: \$catalog, engine_token: \$engine_token, " +
                            "engine_inputs: \$engine_inputs, state: \$state, active: true, started_at: time::now(), updated_at: time::now() };",
                        mapOf(
                            "attempt" to RecordId("publication_attempt", attempt.id.value),
                            "capture" to attempt.capture.value,
                            "catalog" to attempt.catalog.value,
                            "engine_token" to attempt.engineInputs.token.value,
                            "engine_inputs" to publicationJson.encodeToString(attempt.engineInputs),
                            "state" to attempt.state.storageName(),
                        ),
                    ).take(0)
                true
            }
        }

    override suspend fun transition(
        id: PublicationId,
        from: PublicationState,
        to: PublicationState,
    ): Boolean =
        database.inTransaction { transaction ->
            val attempt = RecordId("publication_attempt", id.value)
            val current = transaction.query("SELECT VALUE state FROM ONLY \$attempt;", mapOf("attempt" to attempt)).take(0)
            if (current.isNone || current.isNull || current.getString() != from.storageName()) return@inTransaction false
            val terminal = to is PublicationState.Complete || to is PublicationState.Blocked || to is PublicationState.Interrupted
            transaction
                .query(
                    "UPDATE ONLY \$attempt SET state = \$state, active = \$active, updated_at = time::now();",
                    mapOf(
                        "attempt" to attempt,
                        "state" to to.storageName(),
                        "active" to !terminal,
                    ),
                ).take(0)
            if (to is PublicationState.Blocked) {
                transaction
                    .query(
                        "UPDATE ONLY \$attempt SET findings = \$findings;",
                        mapOf(
                            "attempt" to attempt,
                            "findings" to publicationJson.encodeToString(to.findings),
                        ),
                    ).take(0)
            }
            if (terminal) {
                transaction
                    .query(
                        "UPDATE ONLY publication_slot:current SET owner = NONE WHERE owner = \$owner;",
                        mapOf("owner" to id.value),
                    ).take(0)
            }
            true
        }

    override suspend fun unfinished(): List<PublicationAttempt> =
        database
            .query(
                "SELECT id, capture, catalog, engine_inputs, state, started_at FROM publication_attempt WHERE active = true ORDER BY started_at;",
            ).take(0)
            .getArray()
            .map { rowValue ->
                val row = rowValue.getObject()
                PublicationAttempt(
                    id =
                        PublicationId(
                            row
                                .get("id")
                                .getRecordId()
                                .toString()
                                .substringAfter(':'),
                        ),
                    capture = SnapshotId(row.get("capture").getString()),
                    catalog = CatalogGeneration(row.get("catalog").getString()),
                    engineInputs = publicationJson.decodeFromString(row.get("engine_inputs").getString()),
                    state = row.get("state").getString().activePublicationState(),
                )
            }
}

private sealed interface CompilationOutcome {
    data class Ready(
        val manifest: CompiledArtifactManifest,
        val artifacts: List<CompiledArtifact>,
    ) : CompilationOutcome

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : CompilationOutcome
}

private fun PublicationState.storageName(): String =
    when (this) {
        PublicationState.Checking -> "checking"
        PublicationState.Compiling -> "compiling"
        PublicationState.Activating -> "activating"
        PublicationState.Complete -> "complete"
        is PublicationState.Blocked -> "blocked"
        PublicationState.Interrupted -> "interrupted"
    }

private fun PublicationState.isTerminal(): Boolean =
    this == PublicationState.Complete || this is PublicationState.Blocked || this == PublicationState.Interrupted

private fun String.activePublicationState(): PublicationState =
    when (this) {
        "checking" -> PublicationState.Checking
        "compiling" -> PublicationState.Compiling
        "activating" -> PublicationState.Activating
        else -> error("Stored active publication has terminal state $this.")
    }

private fun publicationDiagnostic(diagnostic: CompileDiagnostic): Diagnostic = publicationDiagnostic(diagnostic.code, diagnostic.message)

private fun publicationDiagnostic(
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

private fun manifestDigest(
    snapshot: SnapshotId,
    catalog: CatalogGeneration,
    artifacts: List<CompiledArtifactReference>,
): ContentDigest {
    val facts =
        buildString {
            append(snapshot.value).append('|').append(catalog.value)
            artifacts.forEach { artifact -> append('|').append(artifact.root).append(':').append(artifact.semanticDigest.value) }
        }
    return ContentDigest(
        MessageDigest.getInstance("SHA-256").digest(facts.encodeToByteArray()).joinToString("") {
            "%02x".format(it.toInt() and 0xff)
        },
    )
}

private val PUBLICATION_TYPE = TypeDefinitionId(TypeId.Qualified("typewriter", "publication"), 1)
private val PAGE_PROJECTION = CompilationProjectionId("typewriter.page")
private const val PAGE_MEDIA_TYPE = "application/vnd.typewriter.page+json"
private val publicationJson = Json { encodeDefaults = true }
