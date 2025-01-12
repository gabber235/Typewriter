package com.typewritermc.moduleplugin

import com.typewritermc.loader.ExtensionFlag
import kotlinx.serialization.MissingFieldException
import kotlinx.serialization.Serializable

@Serializable
open class TypewriterModuleConfiguration {
    /**
     * The namespace of the module.
     * This must be tied to your organization.
     */
    var namespace: String = ""

    val flags: MutableList<ExtensionFlag> = mutableListOf()

    var engine: TypewriterEngineConfiguration? = null
    var extension: TypewriterExtensionConfiguration? = null

    /**
     * Adds a flag to the module.
     */
    fun flag(flag: ExtensionFlag) {
        flags.add(flag)
    }

    fun engine(block: TypewriterEngineConfiguration.() -> Unit) {
        engine = TypewriterEngineConfiguration().apply(block)
    }

    fun extension(block: TypewriterExtensionConfiguration.() -> Unit) {
        extension = TypewriterExtensionConfiguration().apply(block)
    }
}

const val MIN_NAMESPACE_LENGTH = 5
const val MAX_NAMESPACE_LENGTH = 20
val NAMESPACE_REGEX = Regex("^([a-z0-9])+\$")
private fun String.validateAsNamespace(path: String) {
    if (isBlank()) {
        throw MissingFieldException(path)
    }
    if (!NAMESPACE_REGEX.matches(this)) {
        throw IllegalArgumentException("Namespace must only contain lowercase letters and numbers.")
    }
    if (length !in MIN_NAMESPACE_LENGTH..MAX_NAMESPACE_LENGTH) {
        throw FieldOutsideRangeException(path, MIN_NAMESPACE_LENGTH, MAX_NAMESPACE_LENGTH)
    }
}

fun TypewriterModuleConfiguration.validate() {
    namespace.validateAsNamespace("namespace")

    if (engine != null && extension != null) {
        throw IllegalArgumentException("Cannot have both engine and extension set for the same module.")
    }

    engine?.validate()
    extension?.validate()
}

@Serializable
class TypewriterEngineConfiguration(
)

enum class ReleaseChannel(val url: String? = null) {
    RELEASE("https://maven.typewritermc.com/releases"),
    BETA("https://maven.typewritermc.com/beta"),
    NONE
}

private fun TypewriterEngineConfiguration.validate() {
}

@Serializable
data class TypewriterExtensionConfiguration(
    /**
     * The name of the extension.
     */
    var name: String = "",
    /**
     * A short description of the extension.
     */
    var shortDescription: String = "",
    /**
     * A longer description of the extension.
     */
    var description: String = "",
    /**
     * The engine version of the extension.
     * This is used to determine which engine version to load the extension for.
     */
    var engineVersion: String = "",
    /**
     * The release channel to use for the engine and other dependencies.
     */
    var channel: ReleaseChannel = ReleaseChannel.RELEASE,
    /**
     * Dependencies on other extensions.
     */
    var dependencies: ExtensionDependencyConfiguration? = null,
    /**
     * The paper extension configuration.
     */
    var paper: PaperExtensionConfiguration? = null
) {
    fun dependencies(block: ExtensionDependencyConfiguration.() -> Unit) {
        dependencies = ExtensionDependencyConfiguration().apply(block)
    }
    fun paper(block: PaperExtensionConfiguration.() -> Unit) {
        paper = PaperExtensionConfiguration().apply(block)
    }

    fun paper() {
        paper = PaperExtensionConfiguration()
    }
}

private const val MIN_NAME_LENGTH = 5
private const val MAX_NAME_LENGTH = 25
private const val MIN_SHORT_DESCRIPTION_LENGTH = 10
private const val MAX_SHORT_DESCRIPTION_LENGTH = 80
private const val MIN_DESCRIPTION_LENGTH = 100
private const val MAX_DESCRIPTION_LENGTH = 2000
private val NAME_REGEX = Regex("^([a-zA-Z0-9])+\$")
private val FORBIDDEN_WORDS = listOf("Adapter", "Extension")

private fun String.validateAsExtensionName(path: String) {
    if (isBlank()) {
        throw MissingFieldException(path)
    }
    if (length !in MIN_NAME_LENGTH..MAX_NAME_LENGTH) {
        throw FieldOutsideRangeException(path, MIN_NAME_LENGTH, MAX_NAME_LENGTH)
    }
    if (!NAME_REGEX.matches(this)) {
        throw IllegalArgumentException("Extension name '$this' must be alphanumeric.")
    }
    for (word in FORBIDDEN_WORDS) {
        if (this.contains(word, ignoreCase = true)) {
            throw IllegalArgumentException("Extension name '$this' cannot contain '$word'")
        }
    }
}

internal fun TypewriterExtensionConfiguration.validate() {
    name.validateAsExtensionName("extension.name")

    if (shortDescription.isBlank()) {
        throw MissingFieldException("extension.shortDescription")
    }
    if (shortDescription.length !in MIN_SHORT_DESCRIPTION_LENGTH..MAX_SHORT_DESCRIPTION_LENGTH) {
        throw FieldOutsideRangeException(
            "extension.shortDescription",
            MIN_SHORT_DESCRIPTION_LENGTH,
            MAX_SHORT_DESCRIPTION_LENGTH
        )
    }

    if (description.isBlank()) {
        throw MissingFieldException("extension.description")
    }
    if (description.length !in MIN_DESCRIPTION_LENGTH..MAX_DESCRIPTION_LENGTH) {
        throw FieldOutsideRangeException("extension.description", MIN_DESCRIPTION_LENGTH, MAX_DESCRIPTION_LENGTH)
    }

    if (engineVersion.isBlank()) {
        throw MissingFieldException("extension.engineVersion")
    }

    dependencies?.validate()
    paper?.validate()
}

@Serializable
data class ExtensionDependencyConfiguration(
    val dependencies: MutableList<ExtensionDependency> = mutableListOf(),
) {
    fun dependency(namespace: String, name: String) {
        dependencies.add(ExtensionDependency(namespace, name))
    }
}

@Serializable
data class ExtensionDependency(
    val namespace: String,
    val name: String,
)

private fun ExtensionDependencyConfiguration.validate() {
    dependencies.forEach { it.validate() }
}

private fun ExtensionDependency.validate() {
    namespace.validateAsNamespace("extension.dependencies.namespace")
    name.validateAsExtensionName("extension.dependencies.name")
}

@Serializable
data class PaperExtensionConfiguration(
    val dependencies: MutableList<String> = mutableListOf(),
) {
    /**
     * Adds a dependency to the paper extension.
     * If the dependency is not found, the extension will not be loaded.
     */
    fun dependency(dependency: String) {
        dependencies.add(dependency)
    }
}

internal fun PaperExtensionConfiguration.validate() {
    val invalidDependencies = dependencies.filter {
        !Regex("^([a-zA-Z0-9])+\$").matches(it)
    }
    if (invalidDependencies.isNotEmpty()) {
        throw IllegalArgumentException("Invalid dependency(s): ${invalidDependencies.joinToString(", ")}")
    }
}

class MissingFieldException(field: String) : Exception("Field '$field' is is not set, yet is required.")
class FieldOutsideRangeException(field: String, min: Int, max: Int) :
    Exception("Field '$field' must be between $min and $max characters.")
