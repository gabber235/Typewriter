package com.typewritermc.realm.deployment

import com.typewritermc.engine.SemanticVersion
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.isActive
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.attribute.FileTime
import kotlin.time.Duration

/**
 * Watches a development import directory and publishes changed JAR files as immutable artifact revisions.
 *
 * Filenames encode artifact identity, exact Semantic Versioning value, and artifact kind. Invalid names and failed imports
 * are ignored and retried on later scans. [watch] polls until its collecting coroutine is cancelled.
 */
class DevelopmentArtifactImporter(
    private val directory: Path,
    private val repository: ImmutableArtifactRepository,
    private val pollInterval: Duration,
) {
    private val imported = mutableMapOf<Path, FileTime>()

    fun watch(): Flow<DevelopmentArtifactRevision> =
        flow {
            while (currentCoroutineContext().isActive) {
                scan().forEach { emit(it) }
                delay(pollInterval)
            }
        }

    suspend fun scan(): List<DevelopmentArtifactRevision> {
        if (!Files.isDirectory(directory)) return emptyList()
        val changed =
            Files.list(directory).use { paths ->
                paths
                    .filter(Files::isRegularFile)
                    .sorted()
                    .filter { path -> imported[path] != Files.getLastModifiedTime(path) }
                    .toList()
            }
        return changed.mapNotNull { path ->
            val descriptor = DevelopmentArtifactDescriptor.parse(path.fileName.toString()) ?: return@mapNotNull null
            val result = repository.import(descriptor.id, descriptor.version, descriptor.kind, Files.readAllBytes(path))
            if (result is ArtifactImportResult.Success) {
                imported[path] = Files.getLastModifiedTime(path)
                DevelopmentArtifactRevision(path, result.reference)
            } else {
                null
            }
        }
    }
}

/** Records which local development file produced a newly imported immutable artifact. */
data class DevelopmentArtifactRevision(
    val source: Path,
    val artifact: ArtifactReference,
)

private data class DevelopmentArtifactDescriptor(
    val id: String,
    val version: SemanticVersion,
    val kind: ArtifactKind,
) {
    companion object {
        fun parse(fileName: String): DevelopmentArtifactDescriptor? {
            if (!fileName.endsWith(".jar")) return null
            val segments = fileName.removeSuffix(".jar").split("__")
            if (segments.size != 3) return null
            return runCatching {
                DevelopmentArtifactDescriptor(
                    id = segments[0],
                    version = SemanticVersion.parse(segments[1]),
                    kind = ArtifactKind.valueOf(segments[2].uppercase()),
                )
            }.getOrNull()
        }
    }
}
