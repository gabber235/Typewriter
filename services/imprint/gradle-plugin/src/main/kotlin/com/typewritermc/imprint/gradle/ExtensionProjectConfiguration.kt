package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterEngineLayerReference
import com.typewritermc.imprint.TypewriterProjectDeclaration
import com.typewritermc.imprint.TypewriterRuntimeTargetKind
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
                layout.layers.forEach { task.logger.lifecycle("Typewriter resolved layer ${it.id} ${it.version}") }
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
                    "generated/ksp/${sourceSet.name}/resources/META-INF/typewriter/activators/${sourceSet.name}.index",
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
            task.layers.set(layout.layers.map { "${it.id}|${it.version}" })
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
            task.exclude("META-INF/typewriter/activators/*.index")
        }
    }
}

private data class ExtensionLayout(
    val sourceSets: List<ExtensionSourceSet>,
    val layers: List<TypewriterEngineLayerReference>,
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

    val resolvedLayers = linkedMapOf<String, TypewriterEngineLayerReference>()
    declaration.targets
        .filter { it.kind == TypewriterRuntimeTargetKind.ENGINE }
        .forEach { target ->
            val engine = builtInEngines[target.id] ?: throw GradleException("Unknown engine target: ${target.id}")
            requireCompatible(target.version, engine.version, "engine ${target.id}")
            resolveLayers(engine.layers, resolvedLayers, mutableListOf())
            val parents =
                listOf("common") +
                    engine.layers
                        .flatMap(::transitiveLayerIds)
                        .distinct()
                        .map { it.sourceSetName("layer") }
            sourceSets += ExtensionSourceSet(target.id.sourceSetName("engine"), parents)
        }

    val layerSourceSets =
        resolvedLayers.values.map { layer ->
            val definition = builtInLayers.getValue(layer.id)
            val parents = listOf("common") + definition.requires.map { it.id.sourceSetName("layer") }
            ExtensionSourceSet(layer.id.sourceSetName("layer"), parents)
        }
    sourceSets.addAll(1, layerSourceSets)
    return ExtensionLayout(sourceSets.distinctBy(ExtensionSourceSet::name), resolvedLayers.values.toList(), layout.buildDirectory)
}

private data class EngineDefinition(
    val version: String,
    val layers: List<TypewriterEngineLayerReference>,
)

private data class LayerDefinition(
    val version: String,
    val requires: List<TypewriterEngineLayerReference> = emptyList(),
)

private val builtInEngines =
    mapOf(
        "paper" to EngineDefinition("1.0.0", listOf(layer("typewritermc:minecraft"))),
        "conformance" to EngineDefinition("1.0.0", listOf(layer("typewritermc:conformance-composite"))),
    )

private val builtInLayers =
    mapOf(
        "typewritermc:minecraft" to LayerDefinition("1.0.0"),
        "typewritermc:conformance-base" to LayerDefinition("1.0.0"),
        "typewritermc:conformance-composite" to
            LayerDefinition("1.0.0", listOf(layer("typewritermc:conformance-base"))),
    )

private fun resolveLayers(
    requirements: List<TypewriterEngineLayerReference>,
    resolved: LinkedHashMap<String, TypewriterEngineLayerReference>,
    visiting: MutableList<String>,
) {
    requirements.forEach { requirement ->
        val definition = builtInLayers[requirement.id] ?: throw GradleException("Unknown engine layer: ${requirement.id}")
        requireCompatible(requirement.version, definition.version, "engine layer ${requirement.id}")
        val existing = resolved[requirement.id]
        if (existing != null && major(existing.version) != major(requirement.version)) {
            throw GradleException("Incompatible major versions requested for engine layer ${requirement.id}.")
        }
        if (requirement.id in visiting) {
            throw GradleException("Cyclic engine layer requirement: ${(visiting + requirement.id).joinToString(" -> ")}")
        }
        if (existing != null) return@forEach
        visiting += requirement.id
        resolveLayers(definition.requires, resolved, visiting)
        visiting.removeLast()
        resolved[requirement.id] = requirement
    }
}

private fun transitiveLayerIds(reference: TypewriterEngineLayerReference): List<String> {
    val definition = builtInLayers.getValue(reference.id)
    return definition.requires.flatMap(::transitiveLayerIds) + reference.id
}

private fun requireCompatible(
    required: String,
    available: String,
    subject: String,
) {
    val requiredParts = semanticParts(required)
    val availableParts = semanticParts(available)
    val older =
        compareValuesBy(
            availableParts,
            requiredParts,
            Triple<Int, Int, Int>::first,
            Triple<Int, Int, Int>::second,
            Triple<Int, Int, Int>::third,
        ) < 0
    if (major(required) != major(available) || older) {
        throw GradleException("$subject $available does not satisfy version $required.")
    }
}

private fun semanticParts(version: String): Triple<Int, Int, Int> {
    val parts = version.split('.').map(String::toInt)
    return Triple(parts[0], parts[1], parts[2])
}

private fun major(version: String): Int = version.substringBefore('.').toInt()

private fun layer(id: String) = TypewriterEngineLayerReference(id, "1.0.0")

private fun String.sourceSetName(prefix: String = ""): String {
    val words = substringAfter(':').split(Regex("[^A-Za-z0-9]+"))
    val name = words.joinToString("") { it.capitalized() }
    return if (prefix.isEmpty()) name.replaceFirstChar(Char::lowercase) else prefix + name
}

private fun String.capitalized(): String = replaceFirstChar(Char::uppercase)
