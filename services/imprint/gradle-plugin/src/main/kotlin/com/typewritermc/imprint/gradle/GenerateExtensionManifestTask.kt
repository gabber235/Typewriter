package com.typewritermc.imprint.gradle

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
import java.io.ByteArrayOutputStream

@CacheableTask
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
                .flatMap { file -> file.readLines().filter(String::isNotBlank) }
                .map(ActivatorIndexEntry::parse)
                .sortedWith(compareBy(ActivatorIndexEntry::sourceSet, ActivatorIndexEntry::id, ActivatorIndexEntry::className))
        val duplicates = activators.groupBy { it.sourceSet to it.id }.filterValues { it.size > 1 }.keys
        if (duplicates.isNotEmpty()) {
            throw GradleException("Duplicate extension activator ids: ${duplicates.joinToString()}")
        }

        val bytes =
            ExtensionManifestEncoder.encode(
                extensionId.get(),
                extensionVersion.get(),
                targets.get().sorted(),
                layers.get().sorted(),
                activators,
            )
        outputFile.get().asFile.apply {
            parentFile.mkdirs()
            writeBytes(bytes)
        }
    }
}

internal data class ActivatorIndexEntry(
    val sourceSet: String,
    val id: String,
    val className: String,
) {
    companion object {
        fun parse(value: String): ActivatorIndexEntry {
            val parts = value.split('|')
            if (parts.size != 3 || parts.any(String::isBlank)) {
                throw GradleException("Invalid extension activator index entry: $value")
            }
            return ActivatorIndexEntry(parts[0], parts[1], parts[2])
        }
    }
}

internal object ExtensionManifestEncoder {
    fun encode(
        extensionId: String,
        extensionVersion: String,
        targets: List<String>,
        layers: List<String>,
        activators: List<ActivatorIndexEntry>,
    ): ByteArray =
        CborWriter()
            .apply {
                map(
                    sortedMapOf(
                        "activators" to
                            activators
                                .sortedWith(
                                    compareBy(ActivatorIndexEntry::sourceSet, ActivatorIndexEntry::id, ActivatorIndexEntry::className),
                                ).map {
                                    sortedMapOf(
                                        "class" to it.className,
                                        "id" to it.id,
                                        "sourceSet" to it.sourceSet,
                                    )
                                },
                        "dependencies" to emptyList<Any>(),
                        "format" to 1,
                        "id" to extensionId,
                        "layers" to layers.sorted(),
                        "schemas" to emptyList<Any>(),
                        "targets" to targets.sorted(),
                        "version" to extensionVersion,
                    ),
                )
            }.bytes()
}

private class CborWriter {
    private val output = ByteArrayOutputStream()

    fun bytes(): ByteArray = output.toByteArray()

    fun value(value: Any) {
        when (value) {
            is String -> text(value)
            is Int -> unsigned(value.toLong())
            is List<*> -> array(value.filterNotNull())
            is Map<*, *> -> map(value.entries.associate { it.key.toString() to requireNotNull(it.value) }.toSortedMap())
            else -> throw IllegalArgumentException("Unsupported manifest value: ${value::class.qualifiedName}")
        }
    }

    fun map(values: Map<String, Any>) {
        length(5, values.size.toLong())
        values.forEach { (key, value) ->
            text(key)
            value(value)
        }
    }

    private fun array(values: List<Any>) {
        length(4, values.size.toLong())
        values.forEach(::value)
    }

    private fun text(value: String) {
        val bytes = value.encodeToByteArray()
        length(3, bytes.size.toLong())
        output.write(bytes)
    }

    private fun unsigned(value: Long) {
        require(value >= 0)
        length(0, value)
    }

    private fun length(
        major: Int,
        value: Long,
    ) {
        when {
            value < 24 -> {
                output.write((major shl 5) or value.toInt())
            }

            value <= UByte.MAX_VALUE.toLong() -> {
                output.write((major shl 5) or 24)
                output.write(value.toInt())
            }

            value <= UShort.MAX_VALUE.toLong() -> {
                output.write((major shl 5) or 25)
                writeInteger(value, 2)
            }

            value <= UInt.MAX_VALUE.toLong() -> {
                output.write((major shl 5) or 26)
                writeInteger(value, 4)
            }

            else -> {
                output.write((major shl 5) or 27)
                writeInteger(value, 8)
            }
        }
    }

    private fun writeInteger(
        value: Long,
        bytes: Int,
    ) {
        for (shift in (bytes - 1) * Byte.SIZE_BITS downTo 0 step Byte.SIZE_BITS) {
            output.write((value shr shift).toInt() and 0xff)
        }
    }
}
