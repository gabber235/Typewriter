package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.COMMON_SOURCE_PART
import org.gradle.api.Project
import org.gradle.api.artifacts.Configuration
import org.gradle.api.file.DuplicatesStrategy
import org.gradle.api.file.RegularFile
import org.gradle.api.provider.Provider
import org.gradle.api.tasks.SourceSet
import org.jetbrains.kotlin.gradle.dsl.KotlinJvmProjectExtension

/**
 * Replaces the ordinary main inputs with common and declared target source sets. Common output and explicit
 * included parts are visible during target compilation; engine, capability and plugin API dependencies remain
 * compile only, and a plugin's API reaches only the parts that use it and the parts that include them.
 * Each part receives its own KSP origin context, tests see every part, and the final thin JAR rejects duplicate
 * resources.
 */
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

    val pluginApis = configurePluginApis(declaration.plugins)
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
            // Including parts extend this configuration below, so they see the API of every plugin used here.
            sourcePart.plugins.forEach { configuration.extendsFrom(pluginApis.getValue(it)) }
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

    val manifest = registerManifestTask(declaration, relationships, files(), files())
    configureThinJar(manifest, created.values)
    val providerIndex = registerMergedProviderIndex(created.values)
    tasks.named("jar") { task ->
        task.outputs.cacheIf { true }
        val jar = task as org.gradle.api.tasks.bundling.Jar
        jar.duplicatesStrategy = DuplicatesStrategy.FAIL
        // Each source part's processor writes its own provider index; the JAR carries one index with every part's rows.
        jar.filesMatching(GENERATED_PROVIDER_INDEX_PATH) { copy ->
            if (copy.sourceName == GENERATED_PROVIDER_INDEX_FILE) copy.exclude()
        }
        jar.from(providerIndex) { copy ->
            copy.into(GENERATED_PROVIDER_INDEX_PATH.substringBeforeLast('/'))
            copy.rename { GENERATED_PROVIDER_INDEX_PATH.substringAfterLast('/') }
        }
    }
}

/** One dependency bucket per declared plugin, holding the API its using parts compile against, keyed by plugin name. */
private fun Project.configurePluginApis(plugins: List<DeclaredPlugin>): Map<String, Configuration> =
    plugins.withIndex().associate { (index, plugin) ->
        val name = plugin.requirement.name
        val configuration =
            configurations.create("imprintPluginApi$index") {
                it.isCanBeConsumed = false
                it.isCanBeResolved = false
                it.description = "Compile only API of the $name plugin for the source parts that use it."
            }
        plugin.api.forEach { dependencies.add(configuration.name, it) }
        name to configuration
    }

/**
 * Concatenates the provider index of every source part. Each row names the part it belongs to, so the loader keeps
 * only the rows of the parts an engine accepts from the one merged index.
 */
private fun Project.registerMergedProviderIndex(sourceSets: Collection<SourceSet>): Provider<RegularFile> {
    val output = layout.buildDirectory.file("imprint/$MERGED_PROVIDER_INDEX_FILE")
    val parts = files(sourceSets.map { it.output })
    val task =
        tasks.register("mergeGeneratedProviderIndexes") { task ->
            task.inputs.files(parts).withPropertyName("sourcePartOutputs")
            task.outputs.file(output)
            task.doLast {
                val rows =
                    parts.files
                        .map { it.resolve(GENERATED_PROVIDER_INDEX_PATH) }
                        .filter { it.isFile }
                        .flatMap { it.readLines() }
                        .filter(String::isNotBlank)
                output.get().asFile.apply {
                    parentFile.mkdirs()
                    writeText(rows.joinToString(separator = "") { "$it\n" })
                }
            }
        }
    return task.map { output.get() }
}

/** Where every generated provider index lives in an artifact; the loader in typewriter-contracts reads this path. */
internal const val GENERATED_PROVIDER_INDEX_PATH = "META-INF/typewriter/generated-providers"
private const val GENERATED_PROVIDER_INDEX_FILE = "generated-providers"

/** The merged index's own name until the JAR renames it, so the per part indexes can be left out by name. */
private const val MERGED_PROVIDER_INDEX_FILE = "merged-generated-providers"

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
