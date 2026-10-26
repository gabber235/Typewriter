package com.typewritermc.loader.deployment

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.ArtifactProvenance
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val DeploymentResolutionTest by testSuite {
    test("resolution picks the newest version of every artifact that the selected hosts support") {
        val result =
            resolve(
                realm("1.0.0"),
                realm("1.2.0"),
                realm("1.3.0", hostApi = "^2"),
                engine(PAPER, "1.0.0"),
                engine(PAPER, "1.4.0"),
                engine(PAPER, "2.0.0"),
                engine(PANEL, "1.1.0"),
            )

        val content = result.shouldBeInstanceOf<ResolutionResult.Resolved>().content
        content.realm.coordinate.version shouldBe ArtifactVersion("1.2.0")
        content.primaryEngine.coordinate.version shouldBe ArtifactVersion("1.4.0")
        content.panelEngine.coordinate.version shouldBe ArtifactVersion("1.1.0")
    }

    listOf(
        Refusal(
            "no Realm artifact was imported",
            listOf(engine(PAPER, "1.0.0"), engine(PANEL, "1.0.0")),
            "Accepted candidates must contain exactly one Realm artifact identity.",
        ),
        Refusal(
            "two Realm artifact identities were imported",
            listOf(realm("1.0.0"), realm("1.0.0", id = "typewritermc:other-realm"), engine(PAPER, "1.0.0"), engine(PANEL, "1.0.0")),
            "Accepted candidates must contain exactly one Realm artifact identity.",
        ),
        Refusal(
            "no Realm artifact supports the Realm host API",
            listOf(realm("1.0.0", hostApi = "^2"), engine(PAPER, "1.0.0"), engine(PANEL, "1.0.0")),
            "No Realm artifact supports the Realm host API.",
        ),
        Refusal(
            "no primary engine supports the primary host API",
            listOf(realm("1.0.0"), engine(PAPER, "1.0.0", hostApi = "^2"), engine(PANEL, "1.0.0")),
            "No compatible primary engine satisfies $PAPER ^1.",
        ),
        Refusal(
            "no panel engine satisfies the Realm's panel requirement",
            listOf(realm("1.0.0"), engine(PAPER, "1.0.0"), engine(PANEL, "2.0.0")),
            "No compatible panel engine satisfies $PANEL ^1.",
        ),
    ).forEach { (name, candidates, problem) ->
        test("resolution is refused when $name") {
            resolve(*candidates.toTypedArray()).shouldBeInstanceOf<ResolutionResult.Rejected>().problems shouldContain problem
        }
    }

    test("resolution is refused when one artifact would deploy in two versions") {
        // The panel and the primary engine are the same artifact, but their requirements select different versions.
        val result =
            resolveDeployment(
                CandidateIndex(listOf(realm("1.0.0"), engine(PAPER, "1.0.0"), engine(PAPER, "2.0.0"))),
                selection,
                PrimaryEngineTarget(ArtifactId(PAPER), VersionConstraint("^1")),
                RealmLoaderIntent(ArtifactRequirement(ArtifactId(PAPER), VersionConstraint("^2"))),
            )

        result shouldBe ResolutionResult.Rejected(listOf("Deployment artifact $PAPER resolved to multiple versions."))
    }

    test("an engine whose capability requirement differs from its resolved capability graph is refused at import") {
        shouldThrow<IllegalArgumentException> {
            engine(PAPER, "1.0.0", direct = listOf(requirement(ITEMS, "^2")), resolved = listOf(capability(ITEMS, "1.5.0")))
        }.message shouldBe "Engine capability requirement $ITEMS does not match its resolved graph."
        shouldThrow<IllegalArgumentException> {
            engine(PAPER, "1.0.0", direct = listOf(requirement(ITEMS, "^1")), resolved = emptyList())
        }.message shouldBe "Engine capability requirement $ITEMS does not match its resolved graph."
    }

    test("an engine whose capability graph lists one capability twice is refused at import") {
        shouldThrow<IllegalArgumentException> {
            engine(PAPER, "1.0.0", resolved = listOf(capability(ITEMS, "1.5.0"), capability(ITEMS, "1.6.0")))
        }.message shouldBe "Engine capability graph contains duplicate artifact identities."
    }
}

private data class Refusal(
    val name: String,
    val candidates: List<ArtifactCandidate>,
    val problem: String,
)

private const val PAPER = "typewritermc:paper"
private const val PANEL = "typewritermc:panel"
private const val ITEMS = "typewritermc:items"
private val REALM_HOST = ServiceId("realm-host")
private val PRIMARY_HOST = ServiceId("primary-host")

/** A Realm host and a primary engine host that both run host API 1.0.0. */
private val selection =
    RealmDeploymentSelection(
        realmService = REALM_HOST,
        primaryEngineServices = setOf(PRIMARY_HOST),
        serviceApis = mapOf(REALM_HOST to ArtifactVersion("1.0.0"), PRIMARY_HOST to ArtifactVersion("1.0.0")),
    )

private fun resolve(vararg candidates: ArtifactCandidate) =
    resolveDeployment(
        CandidateIndex(candidates.toList()),
        selection,
        PrimaryEngineTarget(ArtifactId(PAPER), VersionConstraint("^1")),
        RealmLoaderIntent(ArtifactRequirement(ArtifactId(PANEL), VersionConstraint("^1"))),
    )

private fun realm(
    version: String,
    hostApi: String = "^1",
    id: String = "typewritermc:realm",
) = candidate(
    ArtifactKind.REALM,
    RealmManifest(
        id = ArtifactId(id),
        version = ArtifactVersion(version),
        hostApi = VersionConstraint(hostApi),
        runtimeEntrypointClass = "fixture.Realm",
        contributions = emptyList(),
    ),
)

private fun engine(
    id: String,
    version: String,
    hostApi: String = "^1",
    direct: List<ArtifactRequirement> = emptyList(),
    resolved: List<ResolvedArtifact> = emptyList(),
) = candidate(
    ArtifactKind.ENGINE,
    EngineManifest(
        id = ArtifactId(id),
        version = ArtifactVersion(version),
        hostApi = VersionConstraint(hostApi),
        runtimeEntrypointClass = "fixture.Engine",
        directCapabilities = direct,
        resolvedCapabilities = resolved,
        bundledComponents = emptyList(),
        contributions = emptyList(),
    ),
)

private fun requirement(
    id: String,
    constraint: String,
) = ArtifactRequirement(ArtifactId(id), VersionConstraint(constraint))

private fun capability(
    id: String,
    version: String,
) = ResolvedArtifact(ArtifactId(id), ArtifactVersion(version), ArtifactKind.CAPABILITY)

private fun candidate(
    kind: ArtifactKind,
    manifest: ImprintManifest,
): ArtifactCandidate {
    val bytes = "${manifest.id.value}@${manifest.version.value}".encodeToByteArray()
    return ArtifactCandidate(
        artifact =
            DeploymentArtifact(
                ArtifactCoordinate(manifest.id, manifest.version),
                kind,
                ArtifactDigest.sha256(bytes),
                bytes.size.toLong(),
            ),
        manifest = manifest,
        provenance = ArtifactProvenance.LocalInbox("manual/${manifest.id.value}.jar", 1),
        importRevision = 1,
    )
}
