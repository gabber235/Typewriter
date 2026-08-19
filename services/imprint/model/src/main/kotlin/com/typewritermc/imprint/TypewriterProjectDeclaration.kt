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
    val layers: List<TypewriterEngineLayerReference> = emptyList(),
    val targets: List<TypewriterRuntimeTarget> = emptyList(),
)

data class TypewriterEngineLayerReference(
    val id: String,
    val version: String,
)

enum class TypewriterRuntimeTargetKind {
    REALM,
    PANEL,
    ENGINE,
}

data class TypewriterRuntimeTarget(
    val kind: TypewriterRuntimeTargetKind,
    val id: String,
    val version: String,
)
