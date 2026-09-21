package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.HostedRuntimeEntrypointMetadataCodec
import com.typewritermc.imprint.IMPRINT_CONTRIBUTIONS_PATH
import com.typewritermc.imprint.IMPRINT_RUNTIME_ENTRYPOINTS_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ResolvedArtifact
import java.io.File
import java.util.zip.ZipFile

internal data class ManifestAssemblyContext(
    val artifactId: ArtifactId,
    val artifactVersion: ArtifactVersion,
    val artifactKind: ArtifactKind,
)

internal data class ManifestContent(
    val contributions: List<GeneratedContribution> = emptyList(),
    val runtimeEntrypoints: List<String> = emptyList(),
) {
    operator fun plus(other: ManifestContent): ManifestContent =
        ManifestContent(
            contributions = contributions + other.contributions,
            runtimeEntrypoints = runtimeEntrypoints + other.runtimeEntrypoints,
        )

    companion object {
        val Empty = ManifestContent()
    }
}

internal fun interface ManifestContentSource {
    fun read(context: ManifestAssemblyContext): ManifestContent
}

internal operator fun ManifestContentSource.plus(other: ManifestContentSource): ManifestContentSource =
    ManifestContentSource { context -> read(context) + other.read(context) }

internal fun Iterable<ManifestContentSource>.combined(): ManifestContentSource =
    fold(ManifestContentSource { ManifestContent.Empty }) { combined, source -> combined + source }

internal class LocalGeneratedContentSource(
    private val contributionFiles: Collection<File>,
    private val runtimeEntrypointFiles: Collection<File>,
) : ManifestContentSource {
    override fun read(context: ManifestAssemblyContext): ManifestContent =
        ManifestContent(
            contributions = contributionFiles.map { it.toGeneratedContribution(context.artifactId) },
            runtimeEntrypoints = runtimeEntrypointFiles.flatMap(File::readRuntimeEntrypoints),
        )
}

internal class ArchiveManifestContentSource(
    private val artifact: File,
    private val namespace: String,
    private val runtimeEntrypoints: RuntimeEntrypointContribution = RuntimeEntrypointContribution.None,
) : ManifestContentSource {
    override fun read(context: ManifestAssemblyContext): ManifestContent {
        require(artifact.isFile && artifact.extension == "jar") {
            "Manifest content artifact ${artifact.name} must be a JAR."
        }
        return ZipFile(artifact).use { archive ->
            ManifestContent(
                contributions = archive.readContributions(context.artifactId, namespace),
                runtimeEntrypoints = runtimeEntrypoints.read(archive),
            )
        }
    }
}

internal fun interface RuntimeEntrypointContribution {
    fun read(archive: ZipFile): List<String>

    data object None : RuntimeEntrypointContribution {
        override fun read(archive: ZipFile): List<String> = emptyList()
    }

    data object HostedRuntimeMetadata : RuntimeEntrypointContribution {
        override fun read(archive: ZipFile): List<String> {
            val source = File(archive.name).name
            return archive
                .entries()
                .asSequence()
                .filterNot { it.isDirectory }
                .filter { it.name == IMPRINT_RUNTIME_ENTRYPOINTS_PATH }
                .flatMap { entry ->
                    val classes =
                        try {
                            archive.getInputStream(entry).use { input ->
                                HostedRuntimeEntrypointMetadataCodec.decode(input.readBytes()).classes
                            }
                        } catch (failure: Exception) {
                            throw IllegalArgumentException(
                                "Cannot read runtime entrypoint metadata from $source.",
                                failure,
                            )
                        }
                    classes.asSequence()
                }.toList()
                .validatedRuntimeEntrypoints(source)
        }
    }
}

internal class CapabilityGraphContentSource(
    private val resolvedArtifacts: List<ResolvedArtifact>,
    private val manifests: Map<ArtifactId, ImprintManifest>,
) : ManifestContentSource {
    override fun read(context: ManifestAssemblyContext): ManifestContent =
        ManifestContent(
            contributions =
                resolvedArtifacts.flatMap { artifact ->
                    manifests.getValue(artifact.id).contributions
                },
        )
}

internal fun interface ManifestContentTransform {
    fun apply(
        context: ManifestAssemblyContext,
        content: ManifestContent,
    ): ManifestContent
}

internal data object ValidateContributionKeys : ManifestContentTransform {
    override fun apply(
        context: ManifestAssemblyContext,
        content: ManifestContent,
    ): ManifestContent {
        val duplicates =
            content.contributions
                .groupBy { contribution ->
                    listOf(
                        contribution.origin.value,
                        contribution.sourcePart,
                        contribution.producer,
                        contribution.name,
                    )
                }.filterValues { contributions -> contributions.size > 1 }
        require(duplicates.isEmpty()) {
            "Duplicate Imprint contribution keys: ${duplicates.keys.joinToString()}."
        }
        return content
    }
}

internal data object RequireHostedRuntimeEntrypoint : ManifestContentTransform {
    override fun apply(
        context: ManifestAssemblyContext,
        content: ManifestContent,
    ): ManifestContent {
        require(content.runtimeEntrypoints.size == 1) {
            "A hosted artifact must declare exactly one runtime entrypoint, but found " +
                "${content.runtimeEntrypoints.size}."
        }
        return content
    }
}

internal data object RejectRuntimeEntrypoints : ManifestContentTransform {
    override fun apply(
        context: ManifestAssemblyContext,
        content: ManifestContent,
    ): ManifestContent {
        require(content.runtimeEntrypoints.isEmpty()) {
            "Only hosted Imprint artifacts may declare a runtime entrypoint."
        }
        return content
    }
}

internal data object CanonicalizeManifestContent : ManifestContentTransform {
    override fun apply(
        context: ManifestAssemblyContext,
        content: ManifestContent,
    ): ManifestContent =
        content.copy(
            contributions =
                content.contributions.sortedWith(
                    compareBy(
                        { it.origin.value },
                        GeneratedContribution::sourcePart,
                        GeneratedContribution::producer,
                        GeneratedContribution::name,
                    ),
                ),
            runtimeEntrypoints = content.runtimeEntrypoints.sorted(),
        )
}

internal class ManifestContentPipeline(
    private val source: ManifestContentSource,
    private val transforms: List<ManifestContentTransform>,
) {
    fun assemble(context: ManifestAssemblyContext): ManifestContent =
        transforms.fold(source.read(context)) { content, transform -> transform.apply(context, content) }
}

internal fun realmContentPipeline(
    local: ManifestContentSource,
    embedded: ManifestContentSource,
): ManifestContentPipeline = hostedContentPipeline(local + embedded)

internal fun engineContentPipeline(
    local: ManifestContentSource,
    embedded: ManifestContentSource,
    capabilities: ManifestContentSource,
): ManifestContentPipeline = hostedContentPipeline(local + embedded + capabilities)

private fun hostedContentPipeline(source: ManifestContentSource): ManifestContentPipeline =
    ManifestContentPipeline(
        source = source,
        transforms =
            listOf(
                ValidateContributionKeys,
                RequireHostedRuntimeEntrypoint,
                CanonicalizeManifestContent,
            ),
    )

internal fun libraryContentPipeline(source: ManifestContentSource): ManifestContentPipeline =
    ManifestContentPipeline(
        source = source,
        transforms =
            listOf(
                ValidateContributionKeys,
                RejectRuntimeEntrypoints,
                CanonicalizeManifestContent,
            ),
    )

private fun File.toGeneratedContribution(origin: ArtifactId): GeneratedContribution {
    val path = invariantSeparatorsPath
    val resourcesMarker = "/resources/$IMPRINT_CONTRIBUTIONS_PATH/"
    require(resourcesMarker in path) { "Unsafe Imprint contribution path $name." }
    val prefix = path.substringBefore(resourcesMarker)
    val sourcePart = prefix.substringAfterLast('/')
    val contributionPath = path.substringAfter(resourcesMarker)
    val producer = contributionPath.substringBefore('/')
    val name = contributionPath.substringAfter('/', "")
    require(
        sourcePart.isNotBlank() &&
            producer.isNotBlank() &&
            name.isNotBlank() &&
            contributionPath.split('/').none { it == "." || it == ".." },
    ) {
        "Unsafe Imprint contribution path $contributionPath."
    }
    return GeneratedContribution(origin, sourcePart, producer, name, readBytes())
}

private fun File.readRuntimeEntrypoints(): List<String> =
    try {
        HostedRuntimeEntrypointMetadataCodec
            .decode(readBytes())
            .classes
            .validatedRuntimeEntrypoints(name)
    } catch (failure: Exception) {
        throw IllegalArgumentException("Cannot read runtime entrypoint metadata from $name.", failure)
    }

private fun ZipFile.readContributions(
    origin: ArtifactId,
    namespace: String,
): List<GeneratedContribution> {
    require(namespace.isNotBlank() && '/' !in namespace) { "Contribution namespace must be one path segment." }
    val prefix = "$IMPRINT_CONTRIBUTIONS_PATH/"
    return entries()
        .asSequence()
        .filterNot { it.isDirectory }
        .filter { it.name.startsWith(prefix) }
        .map { entry ->
            val contributionPath = entry.name.removePrefix(prefix)
            val producer = contributionPath.substringBefore('/')
            val name = contributionPath.substringAfter('/', "")
            require(
                producer.isNotBlank() &&
                    name.isNotBlank() &&
                    contributionPath.split('/').none { it == "." || it == ".." },
            ) {
                "Unsafe archive contribution path ${entry.name}."
            }
            GeneratedContribution(
                origin = origin,
                sourcePart = "main",
                producer = producer,
                name = "$namespace/$name",
                payload = getInputStream(entry).use { it.readBytes() },
            )
        }.toList()
}

private fun List<String>.validatedRuntimeEntrypoints(source: String): List<String> {
    val normalized = map(String::trim)
    require(normalized.none(String::isEmpty)) {
        "Runtime entrypoint metadata in $source contains a blank class name."
    }
    return normalized
}
