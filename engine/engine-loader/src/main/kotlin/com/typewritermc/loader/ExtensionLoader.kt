package com.typewritermc.loader

import com.google.gson.Gson
import com.google.gson.JsonArray
import com.google.gson.JsonParser
import com.google.gson.annotations.SerializedName
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.io.File
import java.net.URLClassLoader
import java.util.logging.Logger
import java.util.zip.ZipFile
import kotlin.jvm.java
import kotlin.math.abs
import kotlin.math.log10

class ExtensionLoader : KoinComponent {
    private val version: String by inject(named("version"))
    private val logger: Logger by inject()
    private val dependencyChecker: DependencyChecker by inject()
    private val gson: Gson by inject(named("dataSerializer"))
    private val globalClassloader: ClassLoader by inject(named("globalClassloader"))
    private var classLoader: URLClassLoader? = null
    var extensions: List<Extension> = emptyList()
        private set
    private var entryClasses: Map<String, Class<*>> = emptyMap()

    // This value is not reset when the extensions are reloaded. Since we don't want to show the big message every time.
    private var hasShownLoadedMessage = false


    // TODO: Remove this when the database update is implemented
    var extensionJson: JsonArray = JsonArray()

    fun load(jars: List<File>) {
        jars.forEach { assert(it.exists() && it.canRead() && it.endsWith(".jar")) }

        if (classLoader != null) {
            unload()
        }
        classLoader = URLClassLoader(jars.map { it.toURI().toURL() }.toTypedArray(), globalClassloader)

        // In all the jars, there is a file called "extension.json"
        val extensionJsonTexts = jars.mapNotNull { jar ->
            ZipFile(jar).use { zip ->
                val jsonEntry = zip.getEntry("extension.json")
                if (jsonEntry == null) {
                    logger.severe("No extension.json file found in jar: ${jar.name}, is this a valid Typewriter extension?")
                    return@mapNotNull null
                }
                zip.getInputStream(jsonEntry).bufferedReader().use { it.readText() }
            }
        }


        // TODO: Remove this when the database update is implemented
        extensionJson = JsonArray()

        val possibleExtensions =

            extensionJsonTexts.map { extensionJson ->
                gson.fromJson(extensionJson, Extension::class.java) to extensionJson
            }.filter { (extension, _) ->
                if (extension.extension.engineVersion != version) {
                    logger.warning("Extension '${extension.extension.name}Extension' was made for Typewriter ${extension.extension.engineVersion} but you are using Typewriter $version. Ignoring extension.")
                    return@filter false
                }

                val paper = extension.extension.paper
                if (paper == null) {
                    logger.warning("Extension '${extension.extension.name}Extension' does not seem to be a paper extension. Ignoring extension.")
                    return@filter false
                }

                val dependencies = paper.dependencies
                val missingDependencies = dependencies.filter { !dependencyChecker.hasDependency(it) }
                if (missingDependencies.isNotEmpty()) {
                    val missing = missingDependencies.joinToString(", ")
                    logger.warning(
                        "Extension '${extension.extension.name}Extension' is missing external dependencies: '${missing}'. Ignoring extension."
                    )
                    return@filter false
                }

                true
            }

        extensions = possibleExtensions
            .filter { (extension, _) ->
                // Check if the extension dependencies are met
                val missingDependencies =
                    extension.extension.dependencies.filter { (namespace, name) ->
                        possibleExtensions.none { (extension, _) ->
                            extension.extension.namespace == namespace && extension.extension.name == name
                        }
                    }

                if (missingDependencies.isNotEmpty()) {
                    val missing = missingDependencies.joinToString(", ") { "${it.namespace}:${it.name}Extension" }
                    logger.warning(
                        "Extension '${extension.extension.name}Extension' is missing extension dependencies: '${missing}'. Ignoring extension."
                    )
                    return@filter false
                }
                true
            }
            .map { (extension, extensionJson) ->
                // TODO: Remove this when the database update is implemented
                this.extensionJson.add(JsonParser.parseString(extensionJson))

                extension
            }

        if (hasShownLoadedMessage) return
        hasShownLoadedMessage = true

        if (extensions.isEmpty()) {
            logger.warning(
                """
                |
                |${"-".repeat(15)}{ No Extensions Loaded }${"-".repeat(15)}
                |
                |No extensions were loaded.
                |You should always have at least the BasicExtension loaded.
                |
                |${"-".repeat(50)}
                """.trimMargin()
            )
        } else {
            val unsupportedMessage = if (extensions.any { it.extension.flags.contains(ExtensionFlag.Unsupported) }) {
                "\nThere are unsupported extensions loaded. You won't get any support for these and should migrate them away from.\n"
            } else {
                ""
            }
            val maxExtensionLength = extensions.maxOf { it.extension.name.length }
            val maxVersionLength = extensions.maxOf { it.extension.version.length }
            val maxDigits = extensions.maxOf { it.entries.size.digits }
            val extensionsDisplay = extensions.sortedBy { it.extension.name }
                .joinToString("\n") { it.displayString(maxExtensionLength, maxVersionLength, maxDigits) }
            logger.info(
                """
                |
                |${"-".repeat(15)}{ Loaded Extensions }${"-".repeat(15)}
                |
                |${extensionsDisplay}
                |$unsupportedMessage
                |${"-".repeat(50)}
                """.trimMargin()
            )
        }
    }

    fun entryClass(blueprintId: String): Class<*>? {
        val entryClass = entryClasses[blueprintId]
        if (entryClass != null) return entryClass

        val entryClassName = extensions.firstNotNullOfOrNull { extension ->
            extension.entries.firstOrNull { it.id == blueprintId }?.className
        }

        if (entryClassName == null) {
            return null
        }

        return loadClass(entryClassName)
    }

    fun loadClass(className: String): Class<*> {
        classLoader?.let {
            return it.loadClass(className)
        }
        throw IllegalStateException("ExtensionLoader tried to load a class before it was initialized")
    }

    fun unload() {
        classLoader?.close()
        classLoader = null
        extensions = emptyList()
        entryClasses = emptyMap()
    }
}

data class Extension(
    val extension: ExtensionInfo,
    val entries: List<EntryInfo>,
    val entryListeners: List<EntryListenerInfo>,
    val typewriterCommands: List<TypewriterCommandInfo>,
    val dependencyInjections: List<DependencyInjectionInfo>,
)

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
)

data class ExtensionDependencyInfo(
    val namespace: String = "",
    val name: String = "",
)

data class PaperExtensionInfo(
    val dependencies: List<String> = emptyList(),
)

/**
 * Returns a string that can be used to display information about the adapter.
 * It is nicely formatted to align the information between adapters.
 */
fun Extension.displayString(maxAdapterLength: Int, maxVersionLength: Int, maxDigits: Int): String {
    var display = "${extension.name}Extension".rightPad(maxAdapterLength + "Extension".length)
    display += " (${extension.version})".rightPad(maxVersionLength + 2)
    display += padCount("📚", entries.size, maxDigits)
    display += padCount("👂", entryListeners.size, maxDigits)
    display += padCount("🔌", dependencyInjections.size, maxDigits)

    extension.flags.filter { it.warning.isNotBlank() }.joinToString { it.warning }.let {
        if (it.isNotBlank()) {
            display += " ($it)"
        }
    }

    return display
}

private fun padCount(prefix: String, count: Int, maxDigits: Int): String {
    return " ${prefix}: ${" ".repeat((maxDigits - count.digits).coerceAtLeast(0))}$count"
}

private fun String.rightPad(length: Int, padChar: Char = ' '): String {
    return if (this.length >= length) this else this + padChar.toString().repeat(length - this.length)
}

private val Int.digits: Int
    get() = if (this == 0) 1 else log10(abs(this.toDouble())).toInt() + 1

data class EntryInfo(
    val id: String,
    val className: String,
)

data class EntryListenerInfo(
    val entryBlueprintId: String,
    val entryClassName: String,
    val className: String,
    val methodName: String,
    val priority: ListenerPriority,
    val ignoreCancelled: Boolean,
    val arguments: List<String>,
)

data class TypewriterCommandInfo(
    val className: String,
    val methodName: String,
)

data class DialogueMessengerInfo(
    val entryBlueprintId: String,
    val entryClassName: String,
    val className: String,
    val priority: Int,
)

sealed interface DependencyInjectionInfo {
    val className: String
    val type: SerializableType
    val name: String?
}

data class DependencyInjectionClassInfo(
    override val className: String,
    override val type: SerializableType,
    override val name: String?,
) : DependencyInjectionInfo

data class DependencyInjectionMethodInfo(
    override val className: String,
    val methodName: String,
    override val type: SerializableType,
    override val name: String?,
) : DependencyInjectionInfo


enum class SerializableType {
    @SerializedName("singleton")
    SINGLETON,

    @SerializedName("factory")
    FACTORY,
}

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
