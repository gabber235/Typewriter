package com.typewritermc.imprint

import kotlinx.serialization.Serializable

@Serializable
data class TypewriterExtensionManifest(
    val format: Int = CURRENT_FORMAT,
    val id: String,
    val version: String,
    val targets: List<String>,
    val layers: List<String>,
    val activators: List<TypewriterActivatorReference>,
    val dependencies: List<String> = emptyList(),
    val schemas: List<String> = emptyList(),
) {
    companion object {
        const val CURRENT_FORMAT = 1
    }
}

@Serializable
data class TypewriterActivatorReference(
    val sourceSet: String,
    val id: String,
    val className: String,
)

@Serializable
data class TypewriterActivatorIndex(
    val format: Int = CURRENT_FORMAT,
    val activators: List<TypewriterActivatorReference>,
) {
    companion object {
        const val CURRENT_FORMAT = 1
    }
}
