package com.typewritermc.imprint

import kotlinx.serialization.Serializable

/**
 * Stores deterministic compile time discovery and compatibility metadata inside one extension JAR.
 *
 * The same extension JAR may be mounted into separate child runtimes. Readers must reject unsupported [format] values,
 * select only compatible [targets] and [capabilities], and instantiate only activators for the selected source sets.
 */
@Serializable
data class TypewriterExtensionManifest(
    val format: Int = CURRENT_FORMAT,
    val id: String,
    val version: String,
    val targets: List<String>,
    val capabilities: List<String>,
    val activators: List<TypewriterActivatorReference>,
    val dependencies: List<String> = emptyList(),
    val schemas: List<String> = emptyList(),
) {
    companion object {
        const val CURRENT_FORMAT = 1
    }
}

/** Points to one generated activator without requiring runtime classpath scanning. */
@Serializable
data class TypewriterActivatorReference(
    val sourceSet: String,
    val id: String,
    val className: String,
)

/**
 * Carries activators discovered during one KSP source set execution into the final manifest task.
 *
 * Index files are intermediate build artifacts. Their entries are sorted and checked for duplicate identifiers before
 * the extension manifest is published.
 */
@Serializable
data class TypewriterActivatorIndex(
    val format: Int = CURRENT_FORMAT,
    val activators: List<TypewriterActivatorReference>,
) {
    companion object {
        const val CURRENT_FORMAT = 1
    }
}
