package com.typewritermc.imprint

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

const val IMPRINT_MANIFEST_PATH = "META-INF/typewriter/manifest.cbor"
const val IMPRINT_CONTRIBUTIONS_PATH = "META-INF/typewriter/contributions"
const val CURRENT_IMPRINT_FORMAT = 1

/** Canonical machine readable description embedded in every Imprint artifact. */
@Serializable
sealed interface ImprintManifest {
    val format: Int
    val id: ArtifactId
    val version: ArtifactVersion
    val contributions: List<GeneratedContribution>
}

/** Describes an engine and every Typewriter component bundled into its canonical JAR. */
@Serializable
@SerialName("engine")
data class EngineManifest(
    override val format: Int = CURRENT_IMPRINT_FORMAT,
    override val id: ArtifactId,
    override val version: ArtifactVersion,
    val directCapabilities: List<ArtifactRequirement>,
    val resolvedCapabilities: List<ResolvedArtifact>,
    val bundledComponents: List<ResolvedArtifact>,
    override val contributions: List<GeneratedContribution>,
) : ImprintManifest {
    init {
        require(resolvedCapabilities.all { it.kind == ArtifactKind.CAPABILITY }) {
            "An engine capability graph may contain only capability artifacts."
        }
        require(bundledComponents.all { it.kind != ArtifactKind.EXTENSION }) {
            "An engine cannot bundle extension descriptors."
        }
    }
}

/** Describes a reusable engine capability and its complete capability dependency graph. */
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

/** Describes the independently targeted source parts contained by one extension JAR. */
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
        require(sourceParts.firstOrNull() == CommonExtensionSourcePart) {
            "An extension manifest must begin with its common source part."
        }
        require(sourceParts.map(ExtensionSourcePart::name).distinct().size == sourceParts.size) {
            "Extension source part names must be unique."
        }
        validateSourcePartIncludes(sourceParts)
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

/** Encodes and decodes the canonical CBOR manifest format. */
@OptIn(ExperimentalSerializationApi::class)
object ImprintManifestCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(manifest: ImprintManifest): ByteArray = cbor.encodeToByteArray(manifest)

    fun decode(bytes: ByteArray): ImprintManifest {
        val manifest = cbor.decodeFromByteArray<ImprintManifest>(bytes)
        require(manifest.format == CURRENT_IMPRINT_FORMAT) {
            "Unsupported Imprint manifest format ${manifest.format}."
        }
        return manifest
    }
}
