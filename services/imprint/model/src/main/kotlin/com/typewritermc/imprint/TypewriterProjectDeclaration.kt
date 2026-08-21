package com.typewritermc.imprint

/** Identifies which public Imprint contract one Gradle project publishes. */
enum class TypewriterProjectKind(
    val displayName: String,
) {
    ENGINE("engine"),
    ENGINE_CAPABILITY("engine capability"),
    EXTENSION("extension"),
}

/**
 * Canonical build declaration shared by Imprint configuration, publication, and code generation.
 *
 * Engines and engine capabilities populate [capabilities]. Extensions populate [targets], while capability source sets
 * are derived from those targets and recorded later in [TypewriterExtensionManifest].
 */
data class TypewriterProjectDeclaration(
    val kind: TypewriterProjectKind,
    val id: String,
    val version: String,
    val capabilities: List<TypewriterEngineCapabilityReference> = emptyList(),
    val targets: List<TypewriterRuntimeTarget> = emptyList(),
)

/** Requests one engine capability at the minimum compatible API version used during build resolution. */
data class TypewriterEngineCapabilityReference(
    val id: String,
    val version: String,
)

/** Identifies the runtime boundary that owns one generated extension source set. */
enum class TypewriterRuntimeTargetKind {
    REALM,
    PANEL,
    ENGINE,
}

/**
 * Selects a runtime contract that an extension release compiles against.
 *
 * Engine targets derive their complete transitive capability set. Extension declarations never select capabilities
 * directly.
 */
data class TypewriterRuntimeTarget(
    val kind: TypewriterRuntimeTargetKind,
    val id: String,
    val version: String,
)
