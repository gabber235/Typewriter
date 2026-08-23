package com.typewritermc.imprint.gradle

import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
import com.google.devtools.ksp.gradle.KspAATask
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.IMPRINT_CONTRIBUTIONS_PATH
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.artifacts.Configuration
import org.gradle.api.artifacts.ExternalModuleDependency
import org.gradle.api.artifacts.ProjectDependency
import org.gradle.api.artifacts.component.ModuleComponentIdentifier
import org.gradle.api.artifacts.component.ProjectComponentIdentifier
import org.gradle.api.file.FileCollection
import org.gradle.api.tasks.SourceSet
import org.gradle.api.tasks.SourceSetContainer
import org.gradle.api.tasks.bundling.Jar

internal fun Project.configureEngineProject(declaration: DeclaredArtifact) {
    configureArtifactVersion(declaration)
    val relationships = configureRelationships(declaration.relationships, "main", ArtifactKind.CAPABILITY)
    val main = productionSourceSets().getByName(SourceSet.MAIN_SOURCE_SET_NAME)
    configurations.named(main.implementationConfigurationName) { configuration ->
        configuration.extendsFrom(configurations.getByName(ENGINE_CORE_CONFIGURATION))
        relationships.forEach { configuration.extendsFrom(it.configuration) }
    }
    configureMainCodegen(declaration)
    val manifest = registerManifestTask(declaration, relationships)
    configureEngineJar(manifest)
}

internal fun Project.configureCapabilityProject(declaration: DeclaredArtifact) {
    configureArtifactVersion(declaration)
    val relationships = configureRelationships(declaration.relationships, "main", ArtifactKind.CAPABILITY)
    configurations.named("api") { configuration ->
        configuration.extendsFrom(configurations.getByName(ENGINE_CORE_CONFIGURATION))
        relationships.forEach { configuration.extendsFrom(it.configuration) }
    }
    configureMainCodegen(declaration)
    val manifest = registerManifestTask(declaration, relationships)
    configureThinJar(manifest, emptyList())
}

internal fun Project.configureArtifactVersion(declaration: DeclaredArtifact) {
    val current = version.toString()
    if (current != Project.DEFAULT_VERSION && current != declaration.version.value) {
        throw GradleException(
            "Project version $current conflicts with Imprint artifact version ${declaration.version}.",
        )
    }
    version = declaration.version.value
}

internal fun Project.configureRelationships(
    declarations: List<DeclaredRelationship>,
    sourcePart: String,
    expectedKind: ArtifactKind,
): List<ConfiguredRelationship> =
    declarations.mapIndexed { index, declaration ->
        val configurationName =
            "imprint${sourcePart.capitalized()}${expectedKind.name.lowercase().capitalized()}Relationship$index"
        val configuration =
            configurations.create(configurationName) {
                it.isCanBeConsumed = false
                it.isCanBeResolved = true
                it.isTransitive = true
                it.description = "Resolves one Imprint relationship for $sourcePart."
            }
        val dependency = dependencies.add(configurationName, declaration.dependency)
        when (dependency) {
            is ExternalModuleDependency -> dependency.version { it.require(declaration.version.mavenRange) }
            is ProjectDependency -> Unit
            else -> throw GradleException("Imprint relationships support only project and external module dependencies.")
        }
        val directFiles =
            configuration.incoming
                .artifactView { view ->
                    view.componentFilter { identifier ->
                        when (dependency) {
                            is ExternalModuleDependency -> {
                                (
                                    identifier is ModuleComponentIdentifier &&
                                        identifier.group == dependency.group &&
                                        identifier.module == dependency.name
                                ) || (
                                    identifier is ProjectComponentIdentifier && identifier.projectName == dependency.name
                                )
                            }

                            is ProjectDependency -> {
                                identifier is ProjectComponentIdentifier && identifier.projectPath == dependency.path
                            }

                            else -> {
                                false
                            }
                        }
                    }
                }.files
        ConfiguredRelationship(
            index = index,
            sourcePart = sourcePart,
            expectedKind = expectedKind,
            constraint = declaration.version.expression,
            configuration = configuration,
            directFiles = directFiles,
        )
    }

internal fun Project.configureMainCodegen(declaration: DeclaredArtifact) {
    configurations.matching { it.name == "ksp" }.configureEach {
        it.extendsFrom(configurations.getByName(PROCESSORS_CONFIGURATION))
    }
    configureKspContext(declaration, mapOf("kspKotlin" to SourceSet.MAIN_SOURCE_SET_NAME))
}

internal fun Project.configureKspContext(
    declaration: DeclaredArtifact,
    sourcePartsByTask: Map<String, String>,
) {
    tasks.withType(KspAATask::class.java).configureEach { task ->
        val sourcePart = sourcePartsByTask[task.name] ?: return@configureEach
        task.kspConfig.processorOptions.put("typewriter.artifactId", declaration.id.value)
        task.kspConfig.processorOptions.put("typewriter.sourcePart", sourcePart)
    }
}

internal fun Project.configureThinJar(
    manifest: org.gradle.api.tasks.TaskProvider<GenerateImprintManifestTask>,
    additionalSourceSets: Collection<SourceSet>,
) {
    tasks.named("jar", Jar::class.java) { jar ->
        additionalSourceSets.forEach { jar.from(it.output) }
        jar.from(manifest.flatMap(GenerateImprintManifestTask::outputFile)) { copy ->
            copy.into(IMPRINT_MANIFEST_PATH.substringBeforeLast('/'))
            copy.rename { IMPRINT_MANIFEST_PATH.substringAfterLast('/') }
        }
        jar.exclude("$IMPRINT_CONTRIBUTIONS_PATH/**")
        jar.dependsOn(manifest)
    }
}

private fun Project.configureEngineJar(manifest: org.gradle.api.tasks.TaskProvider<GenerateImprintManifestTask>) {
    pluginManager.apply("com.gradleup.shadow")
    val shadow =
        tasks.named("shadowJar", ShadowJar::class.java) { jar ->
            jar.archiveClassifier.set("")
            jar.mergeServiceFiles()
            jar.exclude(IMPRINT_MANIFEST_PATH)
            jar.exclude("$IMPRINT_CONTRIBUTIONS_PATH/**")
            jar.from(manifest.flatMap(GenerateImprintManifestTask::outputFile)) { copy ->
                copy.into(IMPRINT_MANIFEST_PATH.substringBeforeLast('/'))
                copy.rename { IMPRINT_MANIFEST_PATH.substringAfterLast('/') }
            }
            jar.dependsOn(manifest)
        }
    tasks.named("jar", Jar::class.java) { it.enabled = false }
    tasks.named("assemble") { it.dependsOn(shadow) }
    listOf("apiElements", "runtimeElements").forEach { name ->
        configurations.named(name) { configuration ->
            configuration.outgoing.artifacts.clear()
            configuration.outgoing.artifact(shadow)
        }
    }
}

internal data class ConfiguredRelationship(
    val index: Int,
    val sourcePart: String,
    val expectedKind: ArtifactKind,
    val constraint: String,
    val configuration: Configuration,
    val directFiles: FileCollection,
)

internal fun String.capitalized(): String = replaceFirstChar(Char::uppercase)

internal fun Project.productionSourceSets(): SourceSetContainer = extensions.getByType(SourceSetContainer::class.java)
