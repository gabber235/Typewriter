package com.typewritermc.realm.compiler

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompileDiagnostic
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.engine.PublishedContent
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withContext
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

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
        val findings: List<Diagnostic>,
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

/** A local gate serializes publication while one retained view supplies every check and compiled output. */
internal class RealmPublicationCoordinator(
    private val acceptance: PublicationAcceptance,
    private val attempts: PublicationAttemptStore,
    private val artifacts: RegisteredCompiledArtifactStore,
    private val engine: EngineImplementationSource,
) {
    private val gate = Mutex()

    @Volatile private var latest: PublicationAttempt? = null

    fun currentAttempt(): PublicationAttempt? = latest

    suspend fun recoverInterrupted() = attempts.interruptUnfinished()

    suspend fun publish(onTransition: suspend (PublicationAttempt) -> Unit = {}): PublicationResult {
        if (!gate.tryLock()) return PublicationResult.Publishing
        var attempt: PublicationAttempt? = null
        var installed = false
        try {
            acceptance.capture().use { captured ->
                val id =
                    PublicationId(
                        java.util.UUID
                            .randomUUID()
                            .toString(),
                    )
                val inputs = engine.capture()
                attempts.start(id, captured.root.catalog.generation, inputs)
                attempt = PublicationAttempt(id, captured.root.catalog.generation, inputs, PublicationState.Checking)

                suspend fun announce(state: PublicationState) {
                    val next = requireNotNull(attempt).copy(state = state)
                    attempt = next
                    latest = next
                    notifyTransition(next, onTransition)
                }

                suspend fun phase(state: PublicationState) {
                    attempts.phase(id, state)
                    announce(state)
                }

                suspend fun blocked(findings: List<Diagnostic>): PublicationResult {
                    attempts.blocked(id, findings)
                    announce(PublicationState.Blocked(findings))
                    return PublicationResult.Blocked(findings)
                }
                announce(PublicationState.Checking)
                val accepted = acceptance.evaluate(captured)
                if (accepted is AcceptanceResult.Blocked) return blocked(accepted.findings)
                accepted as AcceptanceResult.Accepted
                phase(PublicationState.Compiling)
                val compiled = compile(captured.root, accepted.proof.bindingRequirements)
                if (compiled is CompilationOutcome.Blocked) return blocked(compiled.findings)
                compiled as CompilationOutcome.Ready
                val result =
                    artifacts.store(
                        id,
                        captured.root.catalog.generation,
                        inputs.token.value,
                        inputs.signatures,
                        compiled.artifacts,
                    )
                phase(PublicationState.Activating)
                installed =
                    engine.activate(inputs) {
                        attempts.install(result)
                        true
                    }
                if (!installed) {
                    return blocked(
                        listOf(publicationDiagnostic("engine_inputs_changed", "Engine implementation inputs changed before installation.")),
                    )
                }
                announce(PublicationState.Complete)
                return PublicationResult.Activated(id, result)
            }
        } catch (failure: Throwable) {
            if (!installed) {
                attempt?.let { current ->
                    withContext(NonCancellable) {
                        runCatching {
                            attempts.phase(
                                current.id,
                                PublicationState.Interrupted,
                            )
                        }.exceptionOrNull()?.let(failure::addSuppressed)
                    }
                }
            }
            throw failure
        } finally {
            gate.unlock()
        }
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

    private fun compile(
        root: com.typewritermc.realm.authoring.AuthoringView,
        bindingRequirements: List<NativeBindingRequirement>,
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
        return CompilationOutcome.Ready(compiled)
    }
}

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

private sealed interface CompilationOutcome {
    data class Ready(
        val artifacts: List<CompiledArtifact>,
    ) : CompilationOutcome

    data class Blocked(
        val findings: List<Diagnostic>,
    ) : CompilationOutcome
}

internal val publicationsCodec = StructuredDatabaseCodec(authoringStorageJson)

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

private val PUBLICATION_TYPE = TypeDefinitionId(TypeId.Qualified("typewriter", "publication"), 1)
private val PAGE_PROJECTION = CompilationProjectionId("typewriter.page")
private const val PAGE_MEDIA_TYPE = "application/vnd.typewriter.page+json"
private val publicationJson = Json { encodeDefaults = true }
