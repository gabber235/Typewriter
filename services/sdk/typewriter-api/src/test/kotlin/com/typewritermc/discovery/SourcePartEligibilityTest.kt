package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EnabledPlugin
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.PluginRequirement
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
                    CommonExtensionSourcePart(),
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

    test("with its extension selected, each source part is eligible exactly when its engine, capabilities and includes are") {
        SourcePartEligibilityResolver
            .resolve(DeploymentSelection(engine, setOf(extension.id), EnginePlugins.Reported(emptyList())), listOf(extension))
            .associate { it.sourcePart to it.eligibility } shouldBe
            mapOf(
                "common" to Eligibility.Eligible,
                "paper" to Eligibility.Eligible,
                "folia" to Eligibility.Ineligible(listOf(IneligibleReason.EngineMismatch(paper.id, folia.id))),
                "combat" to Eligibility.Eligible,
                "audio" to Eligibility.Ineligible(listOf(IneligibleReason.MissingCapabilities(paper.id, listOf(audio.id)))),
                "combat_on_folia" to Eligibility.Ineligible(listOf(IneligibleReason.IncludedPartsIneligible(listOf("folia")))),
            )
    }

    test("every source part of an unselected extension is ineligible with the reason") {
        SourcePartEligibilityResolver
            .resolve(DeploymentSelection(engine, emptySet(), EnginePlugins.Reported(emptyList())), listOf(extension))
            .associate { it.sourcePart to it.eligibility }
            .values
            .toSet() shouldBe
            setOf(Eligibility.Ineligible(listOf(IneligibleReason.ExtensionNotSelected(extension.id))))
    }

    val vault = PluginRequirement("Vault", VersionConstraint("^1.7"))
    val placeholders = PluginRequirement("PlaceholderAPI")
    val integrations =
        ExtensionManifest(
            id = ArtifactId("fixture:integrations"),
            version = ArtifactVersion("1.0.0"),
            sourceParts =
                listOf(
                    CommonExtensionSourcePart(),
                    EngineExtensionSourcePart("paper", requirement(paper), paper),
                    EngineExtensionSourcePart("vault", requirement(paper), paper, plugins = listOf(vault)),
                    EngineExtensionSourcePart("placeholders", requirement(paper), paper, plugins = listOf(placeholders)),
                    EngineExtensionSourcePart(
                        "vault_quests",
                        requirement(paper),
                        paper,
                        includes = listOf("vault"),
                        plugins = listOf(vault),
                    ),
                ),
            buildProvenance = emptyList(),
            contributions = emptyList(),
        )
    val eligible = Eligibility.Eligible
    val parts = listOf("common", "paper", "vault", "placeholders", "vault_quests")
    listOf(
        Triple(
            "an engine with both plugins in range, versioned as real plugins are, runs every part",
            listOf(EnabledPlugin("Vault", "1.7.3-b131"), EnabledPlugin("PlaceholderAPI", "2.11.6-SNAPSHOT")),
            listOf(eligible, eligible, eligible, eligible, eligible),
        ),
        Triple(
            "an engine without the plugins runs no part that needs one, including a part that inherits one",
            emptyList(),
            listOf(
                eligible,
                eligible,
                Eligibility.Ineligible(listOf(IneligibleReason.MissingPlugin("Vault"))),
                Eligibility.Ineligible(listOf(IneligibleReason.MissingPlugin("PlaceholderAPI"))),
                Eligibility.Ineligible(listOf(IneligibleReason.MissingPlugin("Vault"))),
            ),
        ),
        Triple(
            "an engine with a plugin version outside the range runs no part that needs that range",
            listOf(EnabledPlugin("Vault", "1.6.0"), EnabledPlugin("PlaceholderAPI", "2.11.6")),
            listOf(
                eligible,
                eligible,
                Eligibility.Ineligible(listOf(IneligibleReason.PluginVersionOutOfRange("Vault", VersionConstraint("^1.7"), "1.6.0"))),
                eligible,
                Eligibility.Ineligible(listOf(IneligibleReason.PluginVersionOutOfRange("Vault", VersionConstraint("^1.7"), "1.6.0"))),
            ),
        ),
        Triple(
            "a plugin version without a number fails only parts that declare a range",
            listOf(EnabledPlugin("Vault", "dev-build"), EnabledPlugin("PlaceholderAPI", "dev-build")),
            listOf(
                eligible,
                eligible,
                Eligibility.Ineligible(listOf(IneligibleReason.UnparseableVersion("Vault", VersionConstraint("^1.7"), "dev-build"))),
                eligible,
                Eligibility.Ineligible(listOf(IneligibleReason.UnparseableVersion("Vault", VersionConstraint("^1.7"), "dev-build"))),
            ),
        ),
        Triple(
            "a short plugin version counts its missing numbers as zero",
            listOf(EnabledPlugin("Vault", "v1.7"), EnabledPlugin("PlaceholderAPI", "2")),
            listOf(eligible, eligible, eligible, eligible, eligible),
        ),
    ).forEach { (requirement, enabled, expected) ->
        test(requirement) {
            SourcePartEligibilityResolver
                .resolve(DeploymentSelection(engine, setOf(integrations.id), EnginePlugins.Reported(enabled)), listOf(integrations))
                .associate { it.sourcePart to it.eligibility } shouldBe parts.zip(expected).toMap()
        }
    }

    test("a selection that does not check plugins runs every part whatever plugins it needs") {
        SourcePartEligibilityResolver
            .resolve(DeploymentSelection(engine, setOf(integrations.id), EnginePlugins.Unchecked), listOf(integrations))
            .map { it.eligibility }
            .toSet() shouldBe setOf(eligible)
    }
}
