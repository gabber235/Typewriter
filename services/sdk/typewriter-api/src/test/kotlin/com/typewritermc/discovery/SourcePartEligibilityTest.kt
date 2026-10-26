package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val SourcePartEligibilityTest by testSuite {
    val paper = artifact("fixture:paper", ArtifactKind.ENGINE)
    val folia = artifact("fixture:folia", ArtifactKind.ENGINE)
    val combat = artifact("fixture:combat", ArtifactKind.CAPABILITY)
    val audio = artifact("fixture:audio", ArtifactKind.CAPABILITY)
    val engine =
        EngineManifest(
            id = paper.id,
            version = paper.version,
            hostApi = VersionConstraint("^1"),
            runtimeEntrypointClass = "com.example.PaperEngine",
            directCapabilities = listOf(ArtifactRequirement(combat.id, VersionConstraint("^1"))),
            resolvedCapabilities = listOf(combat),
            bundledComponents = emptyList(),
            contributions = emptyList(),
        )
    val extension =
        ExtensionManifest(
            id = ArtifactId("fixture:extension"),
            version = ArtifactVersion("1.0.0"),
            sourceParts =
                listOf(
                    CommonExtensionSourcePart,
                    EngineExtensionSourcePart("paper", requirement(paper), paper),
                    EngineExtensionSourcePart("folia", requirement(folia), folia),
                    CapabilityExtensionSourcePart("combat", listOf(requirement(combat)), listOf(combat)),
                    CapabilityExtensionSourcePart("audio", listOf(requirement(audio)), listOf(audio)),
                    CapabilityExtensionSourcePart(
                        "combat_on_folia",
                        listOf(requirement(combat)),
                        listOf(combat),
                        includes = listOf("folia"),
                    ),
                ),
            buildProvenance = emptyList(),
            contributions = emptyList(),
        )

    fun eligibility(selected: Set<ArtifactId>) =
        SourcePartEligibilityResolver
            .resolve(DeploymentSelection(engine, selected), listOf(extension))
            .associate { it.sourcePart to it.eligibility }

    test("with its extension selected, each source part is eligible exactly when its engine, capabilities and includes are") {
        eligibility(setOf(extension.id)) shouldBe
            mapOf(
                "common" to Eligibility.Eligible,
                "paper" to Eligibility.Eligible,
                "folia" to Eligibility.Ineligible(listOf("Engine fixture:paper does not match fixture:folia.")),
                "combat" to Eligibility.Eligible,
                "audio" to Eligibility.Ineligible(listOf("Engine fixture:paper lacks capabilities fixture:audio.")),
                "combat_on_folia" to Eligibility.Ineligible(listOf("Included source parts are ineligible: folia.")),
            )
    }

    test("every source part of an unselected extension is ineligible with the reason") {
        eligibility(emptySet()).values.toSet() shouldBe
            setOf(Eligibility.Ineligible(listOf("Extension fixture:extension is not selected.")))
    }
}

private fun artifact(
    id: String,
    kind: ArtifactKind,
) = ResolvedArtifact(ArtifactId(id), ArtifactVersion("1.0.0"), kind)

private fun requirement(artifact: ResolvedArtifact) = ArtifactRequirement(artifact.id, VersionConstraint("^1"))
