@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.loader.artifact

import com.typewritermc.loader.deployment.ArtifactCandidate
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import kotlin.io.path.createDirectories
import kotlin.io.path.exists
import kotlin.io.path.readBytes
import kotlin.io.path.writeBytes

/**
 * Persists the accepted inbox index and diagnostics in one CBOR state file.
 *
 * A mutex serializes operations within this instance; it is not a process lock. Quarantine retains the prior
 * accepted candidate, and two consecutive missing observations remove it. State writes use replacement with an
 * atomic move when supported; write failures propagate.
 */
class FileCandidateRepository(
    artifactsRoot: Path,
) : CandidateRepository {
    private val mutex = Mutex()
    private val stateFile = artifactsRoot.resolve("candidates").resolve("index.cbor")
    private var state = readState(stateFile)

    suspend fun candidates(): List<ArtifactCandidate> = mutex.withLock { state.accepted.map(AcceptedInboxCandidate::candidate) }

    suspend fun diagnostics(): List<InboxDiagnostic> = mutex.withLock { state.diagnostics }

    override suspend fun accepted(relativePath: String): AcceptedInboxCandidate? =
        mutex.withLock { state.accepted.singleOrNull { it.observation.relativePath == relativePath } }

    /**
     * Reserves and persists the next import ordinal before candidate acceptance.
     *
     * Failed imports can leave gaps; the ordinal is ordering, not a count of accepted candidates.
     */
    override suspend fun reserveImportRevision(): Long =
        mutex.withLock {
            val revision = state.nextImportRevision
            state = state.copy(nextImportRevision = revision + 1)
            writeState(stateFile, state)
            revision
        }

    override suspend fun accept(candidate: AcceptedInboxCandidate) =
        update { current ->
            val localPath = candidate.observation.relativePath
            val retained =
                current.accepted.filterNot { it.observation.relativePath == localPath }
            current.copy(
                accepted = retained + candidate,
                diagnostics = current.diagnostics.filterNot { it.relativePath == localPath },
                missingPasses = current.missingPasses - localPath,
            )
        }

    override suspend fun updateObservation(observation: InboxObservation) =
        update { current ->
            current.copy(
                accepted =
                    current.accepted.map {
                        if (it.observation.relativePath ==
                            observation.relativePath
                        ) {
                            it.copy(observation = observation)
                        } else {
                            it
                        }
                    },
                diagnostics = current.diagnostics.filterNot { it.relativePath == observation.relativePath },
                missingPasses = current.missingPasses - observation.relativePath,
            )
        }

    override suspend fun quarantine(diagnostic: InboxDiagnostic) =
        update { current ->
            current.copy(
                diagnostics = current.diagnostics.filterNot { it.relativePath == diagnostic.relativePath } + diagnostic,
            )
        }

    override suspend fun observePresence(relativePaths: Set<String>) =
        update { current ->
            val nextMissing =
                current.accepted.associate { accepted ->
                    val path = accepted.observation.relativePath
                    path to if (path in relativePaths) 0 else (current.missingPasses[path] ?: 0) + 1
                }
            current.copy(
                accepted = current.accepted.filter { nextMissing.getValue(it.observation.relativePath) < 2 },
                diagnostics = current.diagnostics.filter { it.relativePath in relativePaths },
                missingPasses = nextMissing.filterValues { it < 2 && it > 0 },
            )
        }

    private suspend fun update(transform: (CandidateState) -> CandidateState) {
        mutex.withLock {
            state = transform(state)
            writeState(stateFile, state)
        }
    }
}

@Serializable
private data class CandidateState(
    val nextImportRevision: Long = 1,
    val accepted: List<AcceptedInboxCandidate> = emptyList(),
    val diagnostics: List<InboxDiagnostic> = emptyList(),
    val missingPasses: Map<String, Int> = emptyMap(),
)

private val candidateCbor = Cbor { encodeDefaults = true }

private fun readState(path: Path): CandidateState =
    if (path.exists()) candidateCbor.decodeFromByteArray(CandidateState.serializer(), path.readBytes()) else CandidateState()

private fun writeState(
    path: Path,
    state: CandidateState,
) {
    path.parent.createDirectories()
    val temporary = path.resolveSibling("${path.fileName}.partial")
    temporary.writeBytes(candidateCbor.encodeToByteArray(CandidateState.serializer(), state))
    try {
        Files.move(temporary, path, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING)
    } catch (_: java.nio.file.AtomicMoveNotSupportedException) {
        Files.move(temporary, path, StandardCopyOption.REPLACE_EXISTING)
    }
}
