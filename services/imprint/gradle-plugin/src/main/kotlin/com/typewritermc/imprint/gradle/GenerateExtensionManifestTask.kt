package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.TypewriterActivatorIndex
import com.typewritermc.imprint.TypewriterActivatorReference
import com.typewritermc.imprint.TypewriterExtensionManifest
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import org.gradle.api.DefaultTask
import org.gradle.api.GradleException
import org.gradle.api.file.ConfigurableFileCollection
import org.gradle.api.file.RegularFileProperty
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.CacheableTask
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.InputFiles
import org.gradle.api.tasks.OutputFile
import org.gradle.api.tasks.PathSensitive
import org.gradle.api.tasks.PathSensitivity
import org.gradle.api.tasks.TaskAction

@CacheableTask
@OptIn(ExperimentalSerializationApi::class)
abstract class GenerateExtensionManifestTask : DefaultTask() {
    @get:Input
    abstract val extensionId: Property<String>

    @get:Input
    abstract val extensionVersion: Property<String>

    @get:Input
    abstract val targets: ListProperty<String>

    @get:Input
    abstract val layers: ListProperty<String>

    @get:InputFiles
    @get:PathSensitive(PathSensitivity.RELATIVE)
    abstract val activatorIndexes: ConfigurableFileCollection

    @get:OutputFile
    abstract val outputFile: RegularFileProperty

    @TaskAction
    fun generate() {
        val activators =
            activatorIndexes.files
                .sortedBy { it.invariantSeparatorsPath }
                .flatMap { file -> Cbor.Default.decodeFromByteArray<TypewriterActivatorIndex>(file.readBytes()).activators }
                .sortedWith(
                    compareBy(
                        TypewriterActivatorReference::sourceSet,
                        TypewriterActivatorReference::id,
                        TypewriterActivatorReference::className,
                    ),
                )
        val duplicates = activators.groupBy { it.sourceSet to it.id }.filterValues { it.size > 1 }.keys
        if (duplicates.isNotEmpty()) {
            throw GradleException("Duplicate extension activator ids: ${duplicates.joinToString()}")
        }

        val manifest =
            canonicalExtensionManifest(
                id = extensionId.get(),
                version = extensionVersion.get(),
                targets = targets.get(),
                layers = layers.get(),
                activators = activators,
            )
        outputFile.get().asFile.apply {
            parentFile.mkdirs()
            writeBytes(Cbor.Default.encodeToByteArray(manifest))
        }
    }
}

internal fun canonicalExtensionManifest(
    id: String,
    version: String,
    targets: List<String>,
    layers: List<String>,
    activators: List<TypewriterActivatorReference>,
): TypewriterExtensionManifest =
    TypewriterExtensionManifest(
        id = id,
        version = version,
        targets = targets.sorted(),
        layers = layers.sorted(),
        activators =
            activators.sortedWith(
                compareBy(
                    TypewriterActivatorReference::sourceSet,
                    TypewriterActivatorReference::id,
                    TypewriterActivatorReference::className,
                ),
            ),
    )
