package com.typewritermc.loader

import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonParser
import com.google.gson.JsonSyntaxException
import com.google.gson.annotations.SerializedName
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.io.File
import java.net.URLClassLoader
import java.util.logging.Logger
import java.util.zip.ZipFile
import kotlin.math.abs
import kotlin.math.log10

class ExtensionLoader : KoinComponent {
    private val version: String by inject(named("version"))
    private val logger: Logger by inject()
    private val dependencyChecker: DependencyChecker by inject()
    private val gson: Gson by inject(named("dataSerializer"))
    private val globalClassloader: ClassLoader by inject(named("globalClassloader"))

    private var classLoader: URLClassLoader? = null
    private var entryClassCache: MutableMap<String, Class<*>> = mutableMapOf()

    // This value is not reset when the extensions are reloaded. Since we don't want to show the big message every time.
    private var hasShownLoadMessage = false

    var loadedExtensions: List<Extension.LoadedExtension> = emptyList()
        private set

    var failedExtensions: List<Extension.FailedExtension> = emptyList()
        private set

    var extensions: List<Extension> = emptyList()
        private set


    // TODO: Remove this when the database update is implemented
    var extensionJson: JsonArray = JsonArray()
        private set

    /**
     * Loads extensions from the provided JAR files.
     * If extensions were previously loaded, they are unloaded first.
     *
     * @param jars List of JAR files to load as extensions
     * @throws IllegalArgumentException if any file is not a readable JAR file
     */
    fun load(jars: List<File>) {
        require(jars.all { it.exists() && it.canRead() && it.extension.equals("jar", ignoreCase = true) }) {
            "All files must be existing, readable JAR files"
        }

        if (classLoader != null) {
            unload()
        }
        entryClassCache.clear()

        classLoader = URLClassLoader(jars.map { it.toURI().toURL() }.toTypedArray(), globalClassloader)

        val loadResults = ExtensionLoadPipeline(version, gson, dependencyChecker).load(jars)

        loadedExtensions = loadResults.successful
        failedExtensions = loadResults.failed
        extensions = loadedExtensions + failedExtensions
        extensionJson = JsonArray().apply {
            loadResults.successful.forEach { add(JsonParser.parseString(it.jsonText)) }
        }

        if (!hasShownLoadMessage) {
            hasShownLoadMessage = true
            displayLoadResults(loadResults)
        }
    }

    fun entryClass(blueprintId: String): Class<*>? {
        entryClassCache[blueprintId]?.let { return it }

        val entryClassName = loadedExtensions
            .asSequence()
            .flatMap { it.entries.asSequence() }
            .firstOrNull { it.id == blueprintId }
            ?.className
            ?: return null

        val clazz = loadClass(entryClassName)
        entryClassCache[blueprintId] = clazz
        return clazz
    }

    fun loadClass(className: String): Class<*> {
        return classLoader?.loadClass(className)
            ?: throw IllegalStateException("Cannot load class '$className': ExtensionLoader not initialized")
    }

    fun unload() {
        classLoader?.close()
        classLoader = null
        loadedExtensions = emptyList()
        failedExtensions = emptyList()
        extensions = emptyList()
        extensionJson = JsonArray()
        entryClassCache.clear()
    }

    private fun displayLoadResults(result: ExtensionLoadResult) {
        val message = if (result.isEmpty) {
            buildEmptyMessage()
        } else {
            buildResultMessage(result)
        }
        logger.info(message)
    }

    private fun buildEmptyMessage(): String = """
        |
        |${"-".repeat(15)}{ No Extensions Found }${"-".repeat(15)}
        |
        |No extension jars were found or loaded.
        |You should always have at least the BasicExtension loaded.
        |
        |${"-".repeat(50)}
    """.trimMargin()

    private fun buildResultMessage(result: ExtensionLoadResult): String = buildString {
        appendLine()
        appendLine("${"-".repeat(18)}{ Extensions }${"-".repeat(18)}")
        appendLine()

        if (result.successful.isNotEmpty()) {
            appendLine("Loaded:")

            val maxExtensionLength = result.successful.maxOf { it.info.name.length }
            val maxVersionLength = result.successful.maxOf { it.info.version.length }
            val maxDigits = result.successful.maxOf { it.entries.size.digits }

            result.successful.sortedBy { it.info.name }.forEach { ext ->
                appendLine("  ${ext.displayString(maxExtensionLength, maxVersionLength, maxDigits)}")
            }

            val unsupported = result.successful.count {
                it.info.flags.contains(ExtensionFlag.Unsupported)
            }
            if (unsupported > 0) {
                appendLine()
                appendLine(
                    "⚠️ Unsupported extensions detected. " +
                            "You won't receive support for these and should migrate away from them."
                )
            }
        }

        if (result.failed.isNotEmpty()) {
            if (result.successful.isNotEmpty()) appendLine()
            appendLine("Failed:")
            result.failed.sortedBy { it.info?.name ?: it.jarName }.forEach { failure ->
                appendLine("  ${failure.displayString()}")
            }
        }

        appendLine()
        appendLine("-".repeat(50))
    }
}

private class ExtensionLoadPipeline(
    version: String,
    private val gson: Gson,
    dependencyChecker: DependencyChecker
) {
    val validator = ExtensionValidator(version, dependencyChecker)

    fun load(jars: List<File>): ExtensionLoadResult {
        val extensions = jars
            .map { loadFromJar(it) }
            .map { validator.validate(it) }
            .validateExtensionDependencies()

        return ExtensionLoadResult(
            extensions.filterIsInstance<Extension.LoadedExtension>(),
            extensions.filterIsInstance<Extension.FailedExtension>()
        )
    }

    private fun loadFromJar(jar: File): Extension {
        val jsonText = try {
            ZipFile(jar).use { zip ->
                val entry = zip.getEntry("extension.json") ?: return Extension.FailedExtension(
                    jar.name,
                    null,
                    FailureReason.MissingJsonFile
                )
                zip.getInputStream(entry).bufferedReader().use { it.readText() }
            }
        } catch (e: Exception) {
            return Extension.FailedExtension(
                jar.name, null,
                FailureReason.ReadError(e.message ?: "Failed to read jar")
            )
        }

        return try {
            val data = gson.fromJson(jsonText, ExtensionData::class.java)
                ?: throw JsonSyntaxException("Parsed null extension")
            Extension.LoadedExtension(
                data.extension,
                data.entries,
                data.entryListeners,
                data.typewriterCommands,
                data.dependencyInjections,
                jar.name,
                jsonText
            )
        } catch (e: Exception) {
            Extension.FailedExtension(
                jar.name, null,
                FailureReason.InvalidJson(e.message ?: "Unknown parsing error")
            )
        }
    }

    private fun List<Extension>.validateExtensionDependencies(): List<Extension> {
        val todo = this.toMutableList()
        val filtered = mutableListOf<Extension>()

        while (todo.isNotEmpty()) {
            val removedAny = todo.retainAll { extension ->
                when (extension) {
                    is Extension.LoadedExtension -> {
                        extension.validateWithFilteredDependencies(filtered)?.let {
                            filtered.add(it)
                            return@retainAll false
                        }

                        extension.validateMissingDependencies(this)?.let {
                            filtered.add(it)
                            return@retainAll false
                        }

                        true
                    }

                    is Extension.FailedExtension -> {
                        filtered.add(extension)
                        false
                    }
                }
            }

            if (!removedAny) {
                require(todo.all { it is Extension.LoadedExtension }) { "FailedExtensions should have been filtered properly" }
                filtered.addAll(todo.map { extension ->
                    val loadedExtension = (extension as Extension.LoadedExtension)
                    val dependencies = loadedExtension.info.dependencies.joinToString { it.key }

                    loadedExtension.asFailed(FailureReason.Undetermined("Could not resolve dependency situation for ${loadedExtension.info.key}! Likely due to a cyclic dependency: $dependencies"))
                })
                todo.clear()
            }
        }

        return filtered
    }

    private fun Extension.LoadedExtension.validateWithFilteredDependencies(filtered: List<Extension>): Extension? {
        val filteredDependencies = this.info.dependencies.map { dependency ->
            filtered.firstOrNull { it.info?.key == dependency.key }
        }
        if (filteredDependencies.contains(null)) {
            return null
        }
        val failedDependencies = filteredDependencies.filterIsInstance<Extension.FailedExtension>()
        return if (failedDependencies.isEmpty()) {
            this
        } else {
            this.asFailed(
                FailureReason.ExtensionDependenciesFailed(
                    failedDependencies
                )
            )
        }
    }

    private fun Extension.LoadedExtension.validateMissingDependencies(possibleExtension: List<Extension>): Extension? {
        val missingDependencies = this.info.dependencies.filter { dependency ->
            possibleExtension.none { dependency.key == it.info?.key }
        }
        if (missingDependencies.isEmpty()) return null
        return asFailed(
            FailureReason.MissingExtensionDependencies(
                missingDependencies
            )
        )
    }
}

/** Validates version compatibility, platform support, and external plugin dependencies. */
private class ExtensionValidator(
    private val expectedVersion: String,
    private val dependencyChecker: DependencyChecker
) {
    fun validate(extension: Extension): Extension {
        if (extension !is Extension.LoadedExtension) return extension

        val failureReason = validate(extension)
        if (failureReason != null) {
            return extension.asFailed(failureReason)
        }
        return extension
    }

    fun validate(extension: Extension.LoadedExtension): FailureReason? {
        if (extension.info.engineVersion != expectedVersion) {
            return FailureReason.VersionMismatch(
                expected = expectedVersion,
                found = extension.info.engineVersion
            )
        }

        if (extension.info.paper == null) {
            return FailureReason.NotPaperExtension
        }

        val missingDeps = extension.info.paper.dependencies
            .filter { !dependencyChecker.hasDependency(it) }

        if (missingDeps.isNotEmpty()) {
            return FailureReason.MissingExternalDependencies(missingDeps)
        }

        return null
    }
}

/** Final result after parsing, validation, and dependency resolution of all extensions. */
data class ExtensionLoadResult(
    val successful: List<Extension.LoadedExtension>,
    val failed: List<Extension.FailedExtension>
) {
    val isEmpty: Boolean = successful.isEmpty() && failed.isEmpty()
}

private data class ExtensionData(
    val extension: ExtensionInfo,
    val entries: List<EntryInfo>,
    val entryListeners: List<EntryListenerInfo>,
    val typewriterCommands: List<TypewriterCommandInfo>,
    val dependencyInjections: List<DependencyInjectionInfo>,
)

sealed interface Extension {
    val jarName: String
    val info: ExtensionInfo?

    /**
     * Represents a complete extension with all its components.
     *
     * @property info Core extension metadata
     * @property entries List of entry blueprints provided by this extension
     * @property entryListeners List of entry event listeners
     * @property typewriterCommands List of custom commands
     * @property dependencyInjections List of dependency injection definitions
     */
    data class LoadedExtension(
        override val info: ExtensionInfo,
        val entries: List<EntryInfo>,
        val entryListeners: List<EntryListenerInfo>,
        val typewriterCommands: List<TypewriterCommandInfo>,
        val dependencyInjections: List<DependencyInjectionInfo>,
        override val jarName: String,
        /** Raw JSON for legacy database compatibility. */
        val jsonText: String,
    ) : Extension {
        fun asFailed(reason: FailureReason): FailedExtension {
            return FailedExtension(jarName, info, reason)
        }
    }

    /** Extension that failed validation or dependency checks. */
    data class FailedExtension(
        override val jarName: String,
        override val info: ExtensionInfo?,
        val reason: FailureReason
    ) : Extension
}

sealed class FailureReason(val message: String) {
    /** Extension built for a different engine version with incompatible APIs. */
    class VersionMismatch(expected: String, found: String) :
        FailureReason("version mismatch, typewriter version is $expected but extension was made for $found")

    /** Extension targets a different platform. */
    data object NotPaperExtension :
        FailureReason("not a Paper extension")

    /** Missing required plugin dependencies (e.g., Vault, PlaceholderAPI). */
    class MissingExternalDependencies(dependencies: List<String>) :
        FailureReason("missing dependencies: ${dependencies.joinToString(", ")}")

    /** Missing required Typewriter extensions. */
    class MissingExtensionDependencies(dependencies: List<ExtensionDependencyInfo>) :
        FailureReason("missing extensions: ${dependencies.joinToString(", ") { "${it.namespace}:${it.name}" }}")

    /** Transitive Typewriter extensions dependency failed to load. */
    class ExtensionDependenciesFailed(dependencies: List<Extension.FailedExtension>) :
        FailureReason(
            "dependencies extensions: ${
                dependencies.joinToString(", ") {
                    "${it.info?.namespace}:${it.info?.name} failed to load because ${it.reason.message}"
                }
            }"
        )

    /** Malformed JSON syntax in extension.json. */
    class InvalidJson(error: String) :
        FailureReason("invalid JSON: $error")

    /** I/O errors reading the JAR file itself. */
    class ReadError(error: String) :
        FailureReason("read error: $error")

    /** JAR file missing the required extension.json manifest. */
    data object MissingJsonFile :
        FailureReason("missing extension.json file")

    /** Undetermined error occurred. */
    class Undetermined(error: String) :
        FailureReason(error)
}

private fun Extension.LoadedExtension.displayString(
    maxExtensionLength: Int,
    maxVersionLength: Int,
    maxDigits: Int
): String {
    val ext = info

    var display = "${ext.name}Extension".rightPad(maxExtensionLength + "Extension".length)
    display += " (${ext.version})".rightPad(maxVersionLength + 2)
    display += padCount("📚", entries.size, maxDigits)
    display += padCount("👂", entryListeners.size, maxDigits)
    display += padCount("🔌", dependencyInjections.size, maxDigits)

    val warnings = ext.flags.filter { it.warning.isNotBlank() }.joinToString { it.warning }
    if (warnings.isNotBlank()) {
        display += " ($warnings)"
    }

    return display
}

private fun Extension.FailedExtension.displayString(): String {
    val name = info?.let { "${it.name}Extension" } ?: jarName
    return "$name - (${reason.message})"
}

private fun padCount(prefix: String, count: Int, maxDigits: Int): String {
    val padding = " ".repeat((maxDigits - count.digits).coerceAtLeast(0))
    return " $prefix: $padding$count"
}

private fun String.rightPad(length: Int, padChar: Char = ' '): String {
    return if (this.length >= length) this else this + padChar.toString().repeat(length - this.length)
}

private val Int.digits: Int
    get() = if (this == 0) 1 else log10(abs(this.toDouble())).toInt() + 1


/**
 * Core metadata about an extension.
 *
 * @property name The display name of the extension
 * @property shortDescription A brief description of the extension's purpose
 * @property description A detailed description of the extension
 * @property version The extension's semantic version
 * @property engineVersion The required Typewriter engine version
 * @property namespace The unique namespace for this extension
 * @property flags Special flags indicating extension status (experimental, deprecated, etc.)
 * @property dependencies Other extensions this extension depends on
 * @property paper Paper-specific configuration and dependencies
 */
data class ExtensionInfo(
    val name: String = "",
    val shortDescription: String = "",
    val description: String = "",
    val version: String = "",
    val engineVersion: String = "",
    val namespace: String = "",
    val flags: List<ExtensionFlag> = emptyList(),
    val dependencies: List<ExtensionDependencyInfo> = emptyList(),
    val paper: PaperExtensionInfo? = null,
) {
    val key get() = "$namespace:$name"
}

/**
 * Identifies a dependency on another extension.
 *
 * @property namespace The namespace of the required extension
 * @property name The name of the required extension
 */
data class ExtensionDependencyInfo(
    val namespace: String = "",
    val name: String = "",
) {
    val key get() = "$namespace:$name"
}

/**
 * Paper platform-specific extension configuration.
 *
 * @property dependencies List of Paper plugin dependencies required by this extension
 */
data class PaperExtensionInfo(
    val dependencies: List<String> = emptyList(),
)

/**
 * Metadata for an entry blueprint provided by an extension.
 *
 * @property id The unique blueprint identifier
 * @property className The fully qualified class name implementing this entry
 */
data class EntryInfo(
    val id: String,
    val className: String,
)

/**
 * Metadata for an event listener on an entry.
 *
 * @property entryBlueprintId The blueprint ID this listener is attached to
 * @property entryClassName The entry class name
 * @property className The listener class name
 * @property methodName The listener method name
 * @property priority The event priority
 * @property ignoreCancelled Whether to ignore cancelled events
 * @property arguments The method arguments
 */
data class EntryListenerInfo(
    val entryBlueprintId: String,
    val entryClassName: String,
    val className: String,
    val methodName: String,
    val priority: ListenerPriority,
    val ignoreCancelled: Boolean,
    val arguments: List<String>,
)

/**
 * Metadata for a custom Typewriter command.
 *
 * @property className The class containing the command
 * @property methodName The method implementing the command logic
 */
data class TypewriterCommandInfo(
    val className: String,
    val methodName: String,
)

/**
 * Metadata for dialogue messenger implementations.
 *
 * @property entryBlueprintId The associated entry blueprint
 * @property entryClassName The entry class name
 * @property className The messenger class name
 * @property priority The messenger priority
 */
data class DialogueMessengerInfo(
    val entryBlueprintId: String,
    val entryClassName: String,
    val className: String,
    val priority: Int,
)

/**
 * Base interface for dependency injection definitions.
 *
 * @property className The class being injected
 * @property type The injection type (singleton or factory)
 * @property name Optional qualifier name for the injection
 */
sealed interface DependencyInjectionInfo {
    val className: String
    val type: SerializableType
    val name: String?
}

/**
 * Dependency injection for a class.
 */
data class DependencyInjectionClassInfo(
    override val className: String,
    override val type: SerializableType,
    override val name: String?,
) : DependencyInjectionInfo

/**
 * Dependency injection for a method that provides a dependency.
 */
data class DependencyInjectionMethodInfo(
    override val className: String,
    val methodName: String,
    override val type: SerializableType,
    override val name: String?,
) : DependencyInjectionInfo

/**
 * Specifies how a dependency should be instantiated and managed.
 */
enum class SerializableType {
    /**
     * Single instance shared across all consumers.
     */
    @SerializedName("singleton")
    SINGLETON,

    /**
     * New instance created for each consumer.
     */
    @SerializedName("factory")
    FACTORY,
}

/**
 * Special flags indicating an extension's support status or characteristics.
 */
enum class ExtensionFlag(val warning: String) {
    /**
     * The extension is not tested and may not work.
     */
    Untested("⚠\uFE0F UNTESTED"),

    /**
     * The extension is deprecated and should not be used.
     */
    Deprecated("⚠\uFE0F DEPRECATED"),

    /**
     * The extension is not supported and should be migrated away from.
     */
    Unsupported("⚠\uFE0F UNSUPPORTED"),
}