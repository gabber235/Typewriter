package com.typewritermc.imprint

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

/** JAR entry containing the canonical CBOR manifest. */
const val IMPRINT_MANIFEST_PATH = "META-INF/typewriter/manifest.cbor"

/** JAR directory containing raw processor contributions before manifest generation. */
const val IMPRINT_CONTRIBUTIONS_PATH = "META-INF/typewriter/contributions"

/** Intermediate KSP output naming the hosted runtime entrypoints before manifest generation. */
const val IMPRINT_RUNTIME_ENTRYPOINTS_PATH = "META-INF/typewriter/hosted-runtime-entrypoints.cbor"

/** Current envelope version accepted by [ImprintManifestCodec]. */
const val CURRENT_IMPRINT_FORMAT = 1

/**
 * Canonical artifact description embedded at [IMPRINT_MANIFEST_PATH]. Shared by Gradle packaging, loader
 * validation, and discovery so artifact identity and generated contributions travel with the bytes they describe.
 * The format version governs this envelope independently of each producer's contribution payload format.
 */
@Serializable
sealed interface ImprintManifest {
    val format: Int
    val id: ArtifactId
    val version: ArtifactVersion
    val contributions: List<GeneratedContribution>
}

/**
 * Manifest for a runtime started through the stable loader API. [hostApi] declares the compatible host contract
 * range; it is independent of the artifact version. Packaging validates that hosted artifacts expose exactly one
 * generated runtime entrypoint.
 */
@Serializable
sealed interface HostedArtifactManifest : ImprintManifest {
    val hostApi: VersionConstraint
    val runtimeEntrypointClass: String
}

/** Describes the Realm runtime hosted beside the panel engine. */
@Serializable
@SerialName("realm")
data class RealmManifest(
    override val format: Int = CURRENT_IMPRINT_FORMAT,
    override val id: ArtifactId,
    override val version: ArtifactVersion,
    override val hostApi: VersionConstraint,
    override val runtimeEntrypointClass: String,
    override val contributions: List<GeneratedContribution>,
) : HostedArtifactManifest {
    init {
        require(runtimeEntrypointClass.isNotBlank()) {
            "A Realm manifest must declare a runtime entrypoint class."
        }
    }
}

/**
 * Manifest for an engine and its bundled component graph. Direct capabilities preserve declared constraints,
 * resolved capabilities record exact selections, and bundled components describe packaged Typewriter components.
 * Contributions include discovery metadata assembled for the canonical engine JAR.
 */
@Serializable
@SerialName("engine")
data class EngineManifest(
    override val format: Int = CURRENT_IMPRINT_FORMAT,
    override val id: ArtifactId,
    override val version: ArtifactVersion,
    override val hostApi: VersionConstraint,
    override val runtimeEntrypointClass: String,
    val directCapabilities: List<ArtifactRequirement>,
    val resolvedCapabilities: List<ResolvedArtifact>,
    val bundledComponents: List<ResolvedArtifact>,
    override val contributions: List<GeneratedContribution>,
) : HostedArtifactManifest {
    init {
        require(runtimeEntrypointClass.isNotBlank()) {
            "An engine manifest must declare a runtime entrypoint class."
        }
        require(resolvedCapabilities.all { it.kind == ArtifactKind.CAPABILITY }) {
            "An engine capability graph may contain only capability artifacts."
        }
        require(bundledComponents.all { it.kind != ArtifactKind.EXTENSION }) {
            "An engine cannot bundle extension descriptors."
        }
    }
}

/**
 * Manifest for a reusable engine capability. Direct requirements retain compatibility constraints and resolved
 * capabilities describe the complete selected dependency graph. Capabilities contribute contracts and generated
 * metadata to engines rather than serving as independently hosted runtimes.
 */
@Serializable
@SerialName("capability")
data class CapabilityManifest(
    override val format: Int = CURRENT_IMPRINT_FORMAT,
    override val id: ArtifactId,
    override val version: ArtifactVersion,
    val directRequirements: List<ArtifactRequirement>,
    val resolvedCapabilities: List<ResolvedArtifact>,
    override val contributions: List<GeneratedContribution>,
) : ImprintManifest {
    init {
        require(resolvedCapabilities.all { it.kind == ArtifactKind.CAPABILITY }) {
            "A capability graph may contain only capability artifacts."
        }
    }
}

/**
 * Manifest for independently targeted source parts packaged in one extension JAR. Common must be first, names must
 * be unique, and explicit includes must reference existing parts without cycles or redundant common inclusion.
 * Build provenance records compilation selections; runtime source eligibility is evaluated against the deployment
 * catalog.
 */
@Serializable
@SerialName("extension")
data class ExtensionManifest(
    override val format: Int = CURRENT_IMPRINT_FORMAT,
    override val id: ArtifactId,
    override val version: ArtifactVersion,
    val sourceParts: List<ExtensionSourcePart>,
    val buildProvenance: List<ResolvedArtifact>,
    override val contributions: List<GeneratedContribution>,
) : ImprintManifest {
    init {
        require(sourceParts.firstOrNull() is CommonExtensionSourcePart) {
            "An extension manifest must begin with its common source part."
        }
        require(sourceParts.map(ExtensionSourcePart::name).distinct().size == sourceParts.size) {
            "Extension source part names must be unique."
        }
        validateSourcePartIncludes(sourceParts)
        validateSourcePartPlugins(sourceParts)
    }
}

/** Each plugin keeps the one version range it was declared with, and an including part needs every included plugin. */
private fun validateSourcePartPlugins(sourceParts: List<ExtensionSourcePart>) {
    sourceParts
        .flatMap(ExtensionSourcePart::plugins)
        .groupBy(PluginRequirement::name)
        .forEach { (name, requirements) ->
            require(requirements.map(PluginRequirement::version).distinct().size == 1) {
                "Plugin $name is required with different version ranges."
            }
        }
    val partsByName = sourceParts.associateBy(ExtensionSourcePart::name)
    sourceParts.forEach { sourcePart ->
        val needed = sourcePart.plugins.map(PluginRequirement::name).toSet()
        sourcePart.includes.forEach { includedName ->
            partsByName.getValue(includedName).plugins.firstOrNull { it.name !in needed }?.let { missing ->
                throw IllegalArgumentException(
                    "Extension source part ${sourcePart.name} includes $includedName but does not need its plugin ${missing.name}.",
                )
            }
        }
    }
}

private fun validateSourcePartIncludes(sourceParts: List<ExtensionSourcePart>) {
    val partsByName = sourceParts.associateBy(ExtensionSourcePart::name)
    sourceParts.forEach { sourcePart ->
        require(sourcePart.includes.distinct().size == sourcePart.includes.size) {
            "Extension source part ${sourcePart.name} contains duplicate includes."
        }
        sourcePart.includes.forEach { includedName ->
            require(includedName != COMMON_SOURCE_PART) { "The common source part is already included implicitly." }
            require(includedName != sourcePart.name) { "An extension source part cannot include itself." }
            require(partsByName[includedName] != null) { "Included extension source part $includedName does not exist." }
        }
    }

    val visiting = mutableListOf<String>()
    val visited = mutableSetOf<String>()

    fun visit(name: String) {
        require(name !in visiting) {
            "Cyclic extension source part inclusion: ${(visiting + name).joinToString(" > ")}"
        }
        if (!visited.add(name)) return

        visiting += name
        partsByName.getValue(name).includes.forEach(::visit)
        visiting.removeLast()
    }
    sourceParts.forEach { visit(it.name) }
}

/**
 * CBOR boundary for canonical artifact manifests. Encoding includes default fields so the envelope is explicit.
 * Decoding constructs the typed manifest, applies its model invariants, and rejects unsupported format versions.
 * Malformed data and invariant failures propagate to the caller; this codec performs no signature or digest
 * verification.
 */
@OptIn(ExperimentalSerializationApi::class)
object ImprintManifestCodec {
    private val cbor = Cbor { encodeDefaults = true }

    /** Encodes [manifest] for storage at [IMPRINT_MANIFEST_PATH]. */
    fun encode(manifest: ImprintManifest): ByteArray = cbor.encodeToByteArray(manifest)

    /** Decodes and validates one manifest, rejecting formats other than [CURRENT_IMPRINT_FORMAT]. */
    fun decode(bytes: ByteArray): ImprintManifest {
        val manifest = cbor.decodeFromByteArray<ImprintManifest>(bytes)
        require(manifest.format == CURRENT_IMPRINT_FORMAT) {
            "Unsupported Imprint manifest format ${manifest.format}."
        }
        return manifest
    }
}
