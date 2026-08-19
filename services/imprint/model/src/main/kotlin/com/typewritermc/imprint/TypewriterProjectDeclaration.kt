package com.typewritermc.imprint

enum class TypewriterProjectKind(
    val displayName: String,
) {
    ENGINE("engine"),
    ENGINE_LAYER("engine layer"),
    EXTENSION("extension"),
}

data class TypewriterProjectDeclaration(
    val kind: TypewriterProjectKind,
    val id: String,
    val version: String,
)
