package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.COMMON_SOURCE_PART
import org.gradle.api.Project
import org.gradle.api.file.DuplicatesStrategy
import org.gradle.api.tasks.SourceSet
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension

internal fun Project.configureExtensionProject(declaration: DeclaredArtifact) {
    configureArtifactVersion(declaration)
    val sourceSets = productionSourceSets()
    val main = sourceSets.getByName(SourceSet.MAIN_SOURCE_SET_NAME)
    main.java.setSrcDirs(emptyList<String>())
    main.resources.setSrcDirs(emptyList<String>())
    pluginManager.withPlugin("org.jetbrains.kotlin.jvm") {
        extensions
            .getByType(KotlinJvmProjectExtension::class.java)
            .sourceSets
            .getByName(SourceSet.MAIN_SOURCE_SET_NAME)
            .kotlin
            .setSrcDirs(emptyList<String>())
    }
    val common = sourceSets.maybeCreate(COMMON_SOURCE_PART)
    common.java.setSrcDirs(emptyList<String>())
    configurations.named(common.compileOnlyConfigurationName) { configuration ->
        configuration.extendsFrom(configurations.getByName(ENGINE_CORE_CONFIGURATION))
        configuration.extendsFrom(configurations.getByName(EXTENSION_API_CONFIGURATION))
    }

    val relationships = mutableListOf<ConfiguredRelationship>()
    val created = linkedMapOf(COMMON_SOURCE_PART to common)
    declaration.sourceParts.forEach { sourcePart ->
        val target = sourceSets.maybeCreate(sourcePart.name)
        target.java.setSrcDirs(emptyList<String>())
        created[sourcePart.name] = target
    }

    declaration.sourceParts.forEach { sourcePart ->
        val expectedKind =
            when (sourcePart) {
                is DeclaredEngineSourcePart -> ArtifactKind.ENGINE
                is DeclaredCapabilitySourcePart -> ArtifactKind.CAPABILITY
            }
        val configured = configureRelationships(sourcePart.relationships, sourcePart.name, expectedKind)
        relationships += configured

        val target = created.getValue(sourcePart.name)
        target.compileClasspath += common.output
        target.runtimeClasspath += common.output
        configurations.named(target.compileOnlyConfigurationName) { configuration ->
            configuration.extendsFrom(configurations.getByName(common.compileOnlyConfigurationName))
            configured.forEach { configuration.extendsFrom(it.configuration) }
        }
        configurations.named(target.implementationConfigurationName) { configuration ->
            configuration.extendsFrom(configurations.getByName(common.implementationConfigurationName))
        }

        includedSourcePartClosure(sourcePart, declaration.sourceParts).forEach { includedName ->
            val included = created.getValue(includedName)
            target.compileClasspath += included.output
            target.runtimeClasspath += included.output
            configurations.named(target.compileOnlyConfigurationName) { configuration ->
                configuration.extendsFrom(configurations.getByName(included.compileOnlyConfigurationName))
            }
            configurations.named(target.implementationConfigurationName) { configuration ->
                configuration.extendsFrom(configurations.getByName(included.implementationConfigurationName))
            }
        }
    }

    created.values.forEach { sourceSet ->
        configurations.matching { it.name == "ksp${sourceSet.name.capitalized()}" }.configureEach {
            it.extendsFrom(configurations.getByName(PROCESSORS_CONFIGURATION))
        }
    }
    configureKspContext(
        declaration,
        created.keys.associate { sourcePart -> "ksp${sourcePart.capitalized()}Kotlin" to sourcePart },
    )

    val test = sourceSets.getByName(SourceSet.TEST_SOURCE_SET_NAME)
    created.values.forEach { sourceSet ->
        test.compileClasspath += sourceSet.output
        test.runtimeClasspath += sourceSet.output
    }

    tasks.register("typewriterSourceSets") { task ->
        task.group = "typewriter"
        task.description = "Prints the extension source sets configured by Imprint."
        task.doLast {
            created.keys.forEach { task.logger.lifecycle("Typewriter source set $it") }
        }
    }

    val manifest = registerManifestTask(declaration, relationships, files())
    configureThinJar(manifest, created.values)
    tasks.named("jar") { task ->
        task.outputs.cacheIf { true }
        (task as org.gradle.api.tasks.bundling.Jar).duplicatesStrategy = DuplicatesStrategy.FAIL
    }
}

private fun includedSourcePartClosure(
    sourcePart: DeclaredSourcePart,
    allSourceParts: List<DeclaredSourcePart>,
): List<String> {
    val partsByName = allSourceParts.associateBy(DeclaredSourcePart::name)
    val included = linkedSetOf<String>()

    fun include(name: String) {
        if (!included.add(name)) return
        partsByName.getValue(name).includes.forEach(::include)
    }
    sourcePart.includes.forEach(::include)
    return included.toList()
}
