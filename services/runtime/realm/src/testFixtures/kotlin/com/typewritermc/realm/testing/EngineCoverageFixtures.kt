package com.typewritermc.realm.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EntryTypeId
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineCoverage
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.SourcePartKey
import com.typewritermc.realm.checking.EntryHandlers
import com.typewritermc.realm.checking.follow
import com.typewritermc.types.canonicalText
import kotlinx.coroutines.flow.flowOf
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

/** One Paper source part of the deployed extension: the entry types its handlers run, and what the engines decided for it. */
data class EnginePart(
    val name: String,
    val handles: List<TypeDefinitionId>,
    val disposition: SourcePartDisposition,
)

/**
 * Deploys one extension made of [parts] and reports what the Realm's engines run, as the Realm's host does after each
 * resolution, then waits until the checks settled.
 */
suspend fun RealmFixture.engines(vararg parts: EnginePart) {
    val extension = ArtifactId("fixture:engine-parts")
    val paper = ArtifactId("fixture:paper")
    val manifest =
        ExtensionManifest(
            id = extension,
            version = ArtifactVersion("1.0.0"),
            sourceParts =
                listOf(CommonExtensionSourcePart()) +
                    parts.map { part ->
                        EngineExtensionSourcePart(
                            name = part.name,
                            requirement = ArtifactRequirement(paper, VersionConstraint("^1")),
                            resolved = ResolvedArtifact(paper, ArtifactVersion("1.0.0"), ArtifactKind.ENGINE),
                            handledEntries = part.handles.map { EntryTypeId(it.canonicalText) },
                        )
                    },
            buildProvenance = emptyList(),
            contributions = emptyList(),
        )
    val coverage = EngineCoverage(parts.associate { SourcePartKey(extension, it.name) to it.disposition })
    views.follow(flowOf(coverage), EntryHandlers(listOf(manifest)))
    settle()
}

/** The messages of the warnings on [resource] once the checks settled. */
suspend fun RealmFixture.warningsOn(resource: ResourceId): List<String> {
    settle()
    return checks.findings().flatMap { it.findings }.filter {
        it.primary?.resource == resource && it.severity == DiagnosticSeverity.WARNING
    }.map { it.message }
}
