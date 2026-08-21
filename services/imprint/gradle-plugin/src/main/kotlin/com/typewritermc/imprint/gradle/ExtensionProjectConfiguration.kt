package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterEngineCapabilityReference
import com.typewritermc.imprint.TypewriterProjectDeclaration
import com.typewritermc.imprint.TypewriterRuntimeTargetKind
import io.github.z4kn4fein.semver.toVersion
import org.gradle.api.GradleException
import org.gradle.api.Project
import org.gradle.api.file.DuplicatesStrategy
import org.gradle.api.tasks.SourceSet
import org.gradle.api.tasks.SourceSetContainer
import org.gradle.api.tasks.bundling.Jar
import org.gradle.language.jvm.tasks.ProcessResources

internal fun Project.configureExtensionProject(declaration: TypewriterProjectDeclaration) {
    pluginManager.withPlugin("org.jetbrains.kotlin.jvm") {
        val layout = extensionLayout(declaration)
        tasks.register("typewriterSourceSets") { task ->
            task.group = "typewriter"
            task.description = "Prints the source sets derived from extension targets."
            task.doLast {
                layout.sourceSets.forEach { task.logger.lifecycle("Typewriter source set ${it.name}") }
                layout.capabilities.forEach {
                    task.logger.lifecycle("Typewriter resolved capability ${it.id} ${it.version}")
                }
            }
        }
        val sourceSets = extensions.getByType(SourceSetContainer::class.java)
        val created = linkedMapOf<String, SourceSet>()

        layout.sourceSets.forEach { specification ->
            val sourceSet = sourceSets.maybeCreate(specification.name)
            sourceSet.java.setSrcDirs(emptyList<String>())
            created[specification.name] = sourceSet
            specification.parents.forEach { parentName ->
                val parent = created.getValue(parentName)
                sourceSet.compileClasspath += parent.output
                sourceSet.runtimeClasspath += parent.output
                configurations.named(sourceSet.implementationConfigurationName) {
                    it.extendsFrom(configurations.getByName(parent.implementationConfigurationName))
                }
            }
        }

        val test = sourceSets.getByName(SourceSet.TEST_SOURCE_SET_NAME)
        created.values.forEach { sourceSet ->
            test.compileClasspath += sourceSet.output
            test.runtimeClasspath += sourceSet.output
        }

        tasks.named("jar", Jar::class.java) { jar ->
            created.values.forEach { jar.from(it.output) }
            jar.duplicatesStrategy = DuplicatesStrategy.FAIL
        }

        configureExtensionCodegen(created.values)
        configureExtensionManifest(declaration, layout, created.values)
    }
}

private fun Project.configureExtensionCodegen(sourceSets: Collection<SourceSet>) {
    val codegen = rootProject.findProject(":extension-codegen") ?: return
    val types = rootProject.findProject(":extension-types") ?: return
    sourceSets.forEach { sourceSet ->
        dependencies.add(sourceSet.implementationConfigurationName, types)
        dependencies.add("ksp${sourceSet.name.capitalized()}", codegen)
    }
}

private fun Project.configureExtensionManifest(
    declaration: TypewriterProjectDeclaration,
    layout: ExtensionLayout,
    sourceSets: Collection<SourceSet>,
) {
    val generatedDirectory = layout.buildDirectory.dir("generated/typewriter")
    val indexFiles =
        files(
            sourceSets.map { sourceSet ->
                layout.buildDirectory.file(
                    "generated/ksp/${sourceSet.name}/resources/META-INF/typewriter/activators/${sourceSet.name}.cbor",
                )
            },
        ).filter {
            it.isFile
        }
    val manifest =
        tasks.register("generateTypewriterManifest", GenerateExtensionManifestTask::class.java) { task ->
            task.extensionId.set(declaration.id)
            task.extensionVersion.set(declaration.version)
            task.targets.set(declaration.targets.map { "${it.kind.name}|${it.id}|${it.version}" })
            task.capabilities.set(layout.capabilities.map { "${it.id}|${it.version}" })
            task.activatorIndexes.from(indexFiles)
            task.outputFile.set(generatedDirectory.map { it.file("META-INF/typewriter/extension.cbor") })
            task.dependsOn(sourceSets.map { tasks.named("ksp${it.name.capitalized()}Kotlin") })
        }

    tasks.named("processResources", ProcessResources::class.java) { task ->
        task.from(generatedDirectory)
        task.dependsOn(manifest)
    }
    sourceSets.forEach { sourceSet ->
        tasks.named(sourceSet.processResourcesTaskName, ProcessResources::class.java) { task ->
            task.exclude("META-INF/typewriter/activators/*.cbor")
        }
    }
}

private data class ExtensionLayout(
    val sourceSets: List<ExtensionSourceSet>,
    val capabilities: List<TypewriterEngineCapabilityReference>,
    val buildDirectory: org.gradle.api.file.DirectoryProperty,
)

private data class ExtensionSourceSet(
    val name: String,
    val parents: List<String>,
)

private fun Project.extensionLayout(declaration: TypewriterProjectDeclaration): ExtensionLayout {
    val sourceSets = mutableListOf(ExtensionSourceSet("common", emptyList()))
    declaration.targets
        .filter { it.kind != TypewriterRuntimeTargetKind.ENGINE }
        .forEach { target -> sourceSets += ExtensionSourceSet(target.id.sourceSetName(), listOf("common")) }

    val resolvedCapabilities = linkedMapOf<String, TypewriterEngineCapabilityReference>()
    declaration.targets
        .filter { it.kind == TypewriterRuntimeTargetKind.ENGINE }
        .forEach { target ->
            val engine = builtInEngines[target.id] ?: throw GradleException("Unknown engine target: ${target.id}")
            requireCompatible(target.version, engine.version, "engine ${target.id}")
            resolveCapabilities(engine.capabilities, resolvedCapabilities, mutableListOf())
            val parents =
                listOf("common") +
                    engine.capabilities
                        .flatMap(::transitiveCapabilityIds)
                        .distinct()
                        .map { it.sourceSetName("capability") }
            sourceSets += ExtensionSourceSet(target.id.sourceSetName("engine"), parents)
        }

    val capabilitySourceSets =
        resolvedCapabilities.values.map { capability ->
            val definition = builtInCapabilities.getValue(capability.id)
            val parents = listOf("common") + definition.requires.map { it.id.sourceSetName("capability") }
            ExtensionSourceSet(capability.id.sourceSetName("capability"), parents)
        }
    sourceSets.addAll(1, capabilitySourceSets)
    return ExtensionLayout(
        sourceSets.distinctBy(ExtensionSourceSet::name),
        resolvedCapabilities.values.toList(),
        layout.buildDirectory,
    )
}

private data class EngineDefinition(
    val version: String,
    val capabilities: List<TypewriterEngineCapabilityReference>,
)

private data class CapabilityDefinition(
    val version: String,
    val requires: List<TypewriterEngineCapabilityReference> = emptyList(),
)

private val builtInEngines =
    mapOf(
        "paper" to EngineDefinition("1.0.0", listOf(capability("typewritermc:minecraft"))),
        "conformance" to EngineDefinition("1.0.0", listOf(capability("typewritermc:conformance-composite"))),
    )

private val builtInCapabilities =
    mapOf(
        "typewritermc:minecraft" to CapabilityDefinition("1.0.0"),
        "typewritermc:conformance-base" to CapabilityDefinition("1.0.0"),
        "typewritermc:conformance-composite" to
            CapabilityDefinition("1.0.0", listOf(capability("typewritermc:conformance-base"))),
    )

private fun resolveCapabilities(
    requirements: List<TypewriterEngineCapabilityReference>,
    resolved: LinkedHashMap<String, TypewriterEngineCapabilityReference>,
    visiting: MutableList<String>,
) {
    requirements.forEach { requirement ->
        val definition =
            builtInCapabilities[requirement.id]
                ?: throw GradleException("Unknown engine capability: ${requirement.id}")
        requireCompatible(requirement.version, definition.version, "engine capability ${requirement.id}")
        val existing = resolved[requirement.id]
        if (
            existing != null &&
            existing.version.toVersion(strict = true).major != requirement.version.toVersion(strict = true).major
        ) {
            throw GradleException("Incompatible major versions requested for engine capability ${requirement.id}.")
        }
        if (requirement.id in visiting) {
            throw GradleException("Cyclic engine capability requirement: ${(visiting + requirement.id).joinToString(" -> ")}")
        }
        if (existing != null) return@forEach
        visiting += requirement.id
        resolveCapabilities(definition.requires, resolved, visiting)
        visiting.removeLast()
        resolved[requirement.id] = requirement
    }
}

private fun transitiveCapabilityIds(reference: TypewriterEngineCapabilityReference): List<String> {
    val definition = builtInCapabilities.getValue(reference.id)
    return definition.requires.flatMap(::transitiveCapabilityIds) + reference.id
}

private fun requireCompatible(
    required: String,
    available: String,
    subject: String,
) {
    val requiredVersion = required.toVersion(strict = true)
    val availableVersion = available.toVersion(strict = true)
    if (requiredVersion.major != availableVersion.major || availableVersion < requiredVersion) {
        throw GradleException("$subject $available does not satisfy version $required.")
    }
}

private fun capability(id: String) = TypewriterEngineCapabilityReference(id, "1.0.0")

private fun String.sourceSetName(prefix: String = ""): String {
    val words = substringAfter(':').split(Regex("[^A-Za-z0-9]+"))
    val name = words.joinToString("") { it.capitalized() }
    return if (prefix.isEmpty()) name.replaceFirstChar(Char::lowercase) else prefix + name
}

private fun String.capitalized(): String = replaceFirstChar(Char::uppercase)
