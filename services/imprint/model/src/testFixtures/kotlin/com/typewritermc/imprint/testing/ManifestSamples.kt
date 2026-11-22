package com.typewritermc.imprint.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.EntryTypeId
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ExtensionSourcePart
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.PluginRequirement
import com.typewritermc.imprint.ProducerId
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint

/** One manifest of every kind, with their requirements, contributions and source parts, for codec and validation tests. */
fun sampleManifests(): List<ImprintManifest> {
    val engine = ResolvedArtifact(ArtifactId("typewritermc:paper"), ArtifactVersion("1.4.0"), ArtifactKind.ENGINE)
    val items = ResolvedArtifact(ArtifactId("typewritermc:items"), ArtifactVersion("1.2.3"), ArtifactKind.CAPABILITY)
    val core = ResolvedArtifact(ArtifactId("typewritermc:core"), ArtifactVersion("1.1.0"), ArtifactKind.CAPABILITY)
    val itemsRequirement = ArtifactRequirement(items.id, VersionConstraint("^1.2"))
    val vault = PluginRequirement("Vault", VersionConstraint("^1.7"))
    val contribution =
        GeneratedContribution(
            source = ContributionSourceId("artifact:typewritermc:items"),
            sourcePart = "main",
            producer = ProducerId("core"),
            name = ContributionName("core/types.cbor"),
            payload = byteArrayOf(1, 2, 3),
        )
    return listOf(
        RealmManifest(
            id = ArtifactId("typewritermc:realm"),
            version = ArtifactVersion("1.0.0"),
            hostApi = VersionConstraint("^1"),
            runtimeEntrypointClass = "example.RealmEntrypoint",
            contributions = listOf(contribution),
        ),
        EngineManifest(
            id = engine.id,
            version = engine.version,
            hostApi = VersionConstraint("^1"),
            runtimeEntrypointClass = "example.EngineEntrypoint",
            directCapabilities = listOf(itemsRequirement),
            resolvedCapabilities = listOf(items, core),
            bundledComponents = listOf(items),
            contributions = listOf(contribution),
        ),
        CapabilityManifest(
            id = items.id,
            version = items.version,
            directRequirements = listOf(ArtifactRequirement(core.id, VersionConstraint(">=1.0 <2"))),
            resolvedCapabilities = listOf(core),
            contributions = listOf(contribution),
        ),
        ExtensionManifest(
            id = ArtifactId("typewritermc:quests"),
            version = ArtifactVersion("0.3.0"),
            sourceParts =
                listOf(
                    CommonExtensionSourcePart(handledEntries = listOf(EntryTypeId("{\"common\"}"))),
                    EngineExtensionSourcePart(
                        "paper",
                        ArtifactRequirement(engine.id, VersionConstraint("^1.4")),
                        engine,
                        plugins = listOf(vault),
                        handledEntries = listOf(EntryTypeId("{\"paper\"}")),
                    ),
                    CapabilityExtensionSourcePart(
                        "items",
                        listOf(itemsRequirement),
                        listOf(items),
                        includes = listOf("paper"),
                        plugins = listOf(PluginRequirement("PlaceholderAPI"), vault),
                    ),
                ),
            buildProvenance = listOf(engine, items),
            contributions = listOf(contribution),
        ),
    )
}

private val samplePaper = ResolvedArtifact(ArtifactId("typewritermc:paper"), ArtifactVersion("1.4.0"), ArtifactKind.ENGINE)

/** An engine source part targeting the sample Paper engine. */
fun enginePart(
    name: String,
    includes: List<String> = emptyList(),
    plugins: List<PluginRequirement> = emptyList(),
    handledEntries: List<EntryTypeId> = emptyList(),
): EngineExtensionSourcePart =
    EngineExtensionSourcePart(
        name = name,
        requirement = ArtifactRequirement(samplePaper.id, VersionConstraint("^1.4")),
        resolved = samplePaper,
        includes = includes,
        plugins = plugins,
        handledEntries = handledEntries,
    )

/** An extension manifest holding common and [parts], so tests can check the manifest's rules across parts. */
fun extensionManifest(vararg parts: ExtensionSourcePart): ExtensionManifest =
    ExtensionManifest(
        id = ArtifactId("typewritermc:quests"),
        version = ArtifactVersion("1.0.0"),
        sourceParts = listOf(CommonExtensionSourcePart()) + parts,
        buildProvenance = listOf(samplePaper),
        contributions = emptyList(),
    )
