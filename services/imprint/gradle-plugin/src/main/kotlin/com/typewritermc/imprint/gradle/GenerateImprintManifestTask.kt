package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.IMPRINT_CONTRIBUTIONS_PATH
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.IMPRINT_RUNTIME_ENTRYPOINTS_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.imprint.archive.ImprintArchive
import com.typewritermc.imprint.archive.ImprintArchiveInspection
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.FileCollection
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.Nested
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction
import java.io.File

/** Wires tracked Gradle inputs to deterministic manifest assembly. */
internal fun Project.registerManifestTask(
    declaration: DeclaredArtifact,
    relationships: List<ConfiguredRelationship>,
    platformApiArtifacts: FileCollection,
    engineCoreArtifacts: FileCollection,
): org.gradle.api.tasks.TaskProvider<GenerateImprintManifestTask> {
    val productionParts =
        if (declaration.kind == ArtifactKind.EXTENSION) {
            listOf("common") + declaration.sourceParts.map(DeclaredSourcePart::name)
        } else {
            listOf("main")
        }
    val contributionFiles =
        fileTree(layout.buildDirectory.dir("generated/ksp")) {
            it.include("*/resources/$IMPRINT_CONTRIBUTIONS_PATH/**")
        }
    val runtimeEntrypointFiles =
        files(
            fileTree(layout.buildDirectory.dir("generated/ksp")) {
                it.include("*/resources/$IMPRINT_RUNTIME_ENTRYPOINTS_PATH")
            },
            fileTree("src/main/resources") { it.include(IMPRINT_RUNTIME_ENTRYPOINTS_PATH) },
        )
    return tasks.register("generateImprintManifest", GenerateImprintManifestTask::class.java) { task ->
        task.artifactKind.set(declaration.kind.name)
        task.artifactId.set(declaration.id.value)
        task.artifactVersion.set(declaration.version.value)
        task.hostApiConstraint.set(declaration.hostApi?.expression.orEmpty())
        task.sourceParts.set(
            declaration.sourceParts.map { sourcePart ->
                objects.newInstance(ManifestSourcePartInput::class.java).apply {
                    name.set(sourcePart.name)
                    kind.set(
                        when (sourcePart) {
                            is DeclaredEngineSourcePart -> ArtifactKind.ENGINE
                            is DeclaredCapabilitySourcePart -> ArtifactKind.CAPABILITY
                        },
                    )
                    includes.set(sourcePart.includes)
                }
            },
        )
        task.relationships.set(
            relationships.map { relationship ->
                val description = "${relationship.sourcePart} ${relationship.index}"
                objects.newInstance(ManifestRelationshipInput::class.java).apply {
                    sourcePart.set(relationship.sourcePart)
                    index.set(relationship.index)
                    expectedKind.set(relationship.expectedKind)
                    constraint.set(relationship.constraint)
                    artifact.set(
                        layout.file(
                            relationship.directFiles.elements.map { files ->
                                files.singleOrNull()?.asFile
                                    ?: throw GradleException(
                                        "Imprint relationship $description must resolve one artifact.",
                                    )
                            },
                        ),
                    )
                }
            },
        )
        task.archiveInputs.set(
            buildList {
                if (declaration.kind in setOf(ArtifactKind.REALM, ArtifactKind.ENGINE)) {
                    add(
                        objects.newInstance(ManifestArchiveInput::class.java).apply {
                            namespace.set("platform")
                            entrypointPolicy.set(RuntimeEntrypointInputPolicy.NONE)
                            artifacts.from(platformApiArtifacts)
                        },
                    )
                }
                if (declaration.kind == ArtifactKind.ENGINE) {
                    add(
                        objects.newInstance(ManifestArchiveInput::class.java).apply {
                            namespace.set("core")
                            entrypointPolicy.set(RuntimeEntrypointInputPolicy.HOSTED_RUNTIME_METADATA)
                            artifacts.from(engineCoreArtifacts)
                        },
                    )
                }
            },
        )
        task.graphArtifacts.from(relationships.map(ConfiguredRelationship::configuration))
        task.contributionFiles.from(contributionFiles)
        task.runtimeEntrypointFiles.from(runtimeEntrypointFiles)
        task.outputFile.set(layout.buildDirectory.file("generated/imprint/artifact.cbor"))
        val kspTasks = productionParts.map { part -> if (part == "main") "kspKotlin" else "ksp${part.capitalized()}Kotlin" }
        task.dependsOn(tasks.matching { it.name in kspTasks })
    }
}

/** Gradle adapter for manifest inputs, dependency resolution, assembly, and encoded output. */
@CacheableTask
abstract class GenerateImprintManifestTask : DefaultTask() {
    @get:Input
    abstract val artifactKind: Property<String>

    @get:Input
    abstract val artifactId: Property<String>

    @get:Input
    abstract val artifactVersion: Property<String>

    @get:Input
    abstract val hostApiConstraint: Property<String>

    @get:Nested
    abstract val sourceParts: ListProperty<ManifestSourcePartInput>

    @get:Nested
    abstract val relationships: ListProperty<ManifestRelationshipInput>

    @get:Nested
    abstract val archiveInputs: ListProperty<ManifestArchiveInput>

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val graphArtifacts: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val contributionFiles: ConfigurableFileCollection

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val runtimeEntrypointFiles: ConfigurableFileCollection

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun generate() {
        val context = manifestContext()
        val dependencies = resolveDependencies(context)
        val content = contentPipeline(context, dependencies).assemble(context)
        val manifest =
            createManifest(
                context = context,
                hostApi = hostApiConstraint(),
                sourceParts = sourcePartModels(),
                dependencies = dependencies,
                content = content,
            )

        outputFile.get().asFile.apply {
            parentFile.mkdirs()
            writeBytes(ImprintManifestCodec.encode(manifest))
        }
    }

    private fun manifestContext(): ManifestAssemblyContext =
        ManifestAssemblyContext(
            artifactId = ArtifactId(artifactId.get()),
            artifactVersion = ArtifactVersion(artifactVersion.get()),
            artifactKind = ArtifactKind.valueOf(artifactKind.get()),
        )

    private fun resolveDependencies(context: ManifestAssemblyContext): ManifestDependencies {
        val manifests = readGraphManifests()
        return resolveManifestDependencies(context, readRelationships(manifests), manifests)
    }

    private fun contentPipeline(
        context: ManifestAssemblyContext,
        dependencies: ManifestDependencies,
    ): ManifestContentPipeline {
        val local =
            LocalGeneratedContentSource(
                contributionFiles = contributionFiles.files.sortedBy(File::getAbsolutePath),
                runtimeEntrypointFiles = runtimeEntrypointFiles.files.sortedBy(File::getAbsolutePath),
            )
        val embedded = archiveInputs.get().mapNotNull(ManifestArchiveInput::toSource).combined()
        return when (context.artifactKind) {
            ArtifactKind.REALM -> {
                realmContentPipeline(local, embedded)
            }

            ArtifactKind.ENGINE -> {
                engineContentPipeline(
                    local = local,
                    embedded = embedded,
                    capabilities =
                        CapabilityGraphContentSource(
                            dependencies.capabilityGraph,
                            dependencies.manifests,
                        ),
                )
            }

            ArtifactKind.CAPABILITY,
            ArtifactKind.EXTENSION,
            -> {
                libraryContentPipeline(local)
            }
        }
    }

    private fun hostApiConstraint(): VersionConstraint? = hostApiConstraint.get().takeIf(String::isNotBlank)?.let(::VersionConstraint)

    private fun sourcePartModels(): List<ManifestSourcePart> =
        sourceParts.get().map { input ->
            ManifestSourcePart(
                name = input.name.get(),
                kind = input.kind.get(),
                includes = input.includes.get(),
            )
        }

    private fun readGraphManifests(): Map<ArtifactId, ImprintManifest> {
        val manifests =
            graphArtifacts.files
                .sortedBy(File::getAbsolutePath)
                .mapNotNull(::readManifestOrNull)
        val duplicates =
            manifests.groupBy(ImprintManifest::id).filterValues { values ->
                values.map { it.version to it::class }.distinct().size > 1
            }
        if (duplicates.isNotEmpty()) {
            throw GradleException("Conflicting Imprint artifacts resolved for ${duplicates.keys.joinToString()}.")
        }
        return manifests.associateBy(ImprintManifest::id)
    }

    private fun readRelationships(allManifests: Map<ArtifactId, ImprintManifest>): List<ResolvedRelationship> =
        relationships
            .get()
            .map { relationship ->
                val sourcePart = relationship.sourcePart.get()
                val file = relationship.artifact.get().asFile
                val manifest =
                    readManifestOrNull(file)
                        ?: throw GradleException("Dependency ${file.name} does not contain $IMPRINT_MANIFEST_PATH.")
                val expectedKind = relationship.expectedKind.get()
                val actual = manifest.descriptor()
                if (actual.kind != expectedKind) {
                    throw GradleException(
                        "Dependency path $sourcePart requires $expectedKind but ${manifest.id} is ${actual.kind}.",
                    )
                }
                val constraint = VersionConstraint(relationship.constraint.get())
                if (!constraint.accepts(manifest.version)) {
                    throw GradleException(
                        "Dependency path $sourcePart ${manifest.id} ${manifest.version} does not satisfy $constraint.",
                    )
                }
                if (allManifests[manifest.id] == null) {
                    throw GradleException("Resolved Imprint dependency ${manifest.id} is absent from the dependency graph.")
                }
                ResolvedRelationship(sourcePart, relationship.index.get(), constraint, manifest)
            }.sortedWith(compareBy(ResolvedRelationship::sourcePart, ResolvedRelationship::index))
}

private fun ManifestArchiveInput.toSource(): ManifestContentSource? {
    val files = artifacts.files.sortedBy(File::getAbsolutePath)
    if (files.isEmpty()) return null
    val artifact =
        files.singleOrNull()
            ?: throw GradleException("Manifest archive namespace ${namespace.get()} must resolve exactly one artifact.")
    val entrypoints =
        when (entrypointPolicy.get()) {
            RuntimeEntrypointInputPolicy.NONE -> {
                RuntimeEntrypointContribution.None
            }

            RuntimeEntrypointInputPolicy.HOSTED_RUNTIME_METADATA -> {
                RuntimeEntrypointContribution.HostedRuntimeMetadata
            }
        }
    return ArchiveManifestContentSource(
        artifact = artifact,
        namespace = namespace.get(),
        runtimeEntrypoints = entrypoints,
    )
}

private fun readManifestOrNull(file: File): ImprintManifest? {
    if (!file.isFile || file.extension != "jar") return null
    return when (val inspection = ImprintArchive.inspect(file.toPath())) {
        ImprintArchiveInspection.Absent -> null
        is ImprintArchiveInspection.Present -> inspection.manifest
    }
}
