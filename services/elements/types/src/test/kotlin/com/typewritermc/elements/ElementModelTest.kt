package com.typewritermc.elements

import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ContributionName
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.Eligibility
import com.typewritermc.discovery.ProducerId
import com.typewritermc.discovery.SourcePartCatalogEntry
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.Color
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ElementModelTest by testSuite {
    test("element contribution preserves typed icon and color values") {
        val contribution = ElementDiscoveryContribution(descriptors = listOf(descriptor()), facets = emptyList())

        val decoded = ElementDiscoveryContributionCodec.decode(ElementDiscoveryContributionCodec.encode(contribution))

        decoded shouldBe contribution
    }

    test("availability expressions evaluate deployment facts") {
        val expression =
            AvailabilityExpression.All(
                listOf(
                    AvailabilityExpression.Fact("minecraft", "1.21.11"),
                    AvailabilityExpression.Not(AvailabilityExpression.Fact("feature.preview", "disabled")),
                ),
            )

        expression.evaluate(DeploymentFacts(mapOf("minecraft" to "1.21.11"))) shouldBe true
        expression.evaluate(DeploymentFacts(mapOf("minecraft" to "1.20.6"))) shouldBe false
    }

    test("ineligible source parts retain their element metadata") {
        val origin = ArtifactId("example:extension")
        val descriptor = descriptor()
        val catalog =
            ElementCatalogAssembler.assemble(
                listOf(
                    KeyedElementContribution(
                        ContributionKey(origin, "paper", ProducerId("elements"), ContributionName("catalog.cbor")),
                        ElementDiscoveryContribution(descriptors = listOf(descriptor), facets = emptyList()),
                    ),
                ),
                listOf(
                    SourcePartCatalogEntry(
                        origin,
                        "paper",
                        Eligibility.Ineligible(listOf("Paper engine is not selected.")),
                    ),
                ),
            )

        catalog.entries.single().descriptor shouldBe descriptor
        catalog.entries.single().eligible shouldBe false
        catalog.entries.single().ineligibilityReasons shouldBe listOf("Paper engine is not selected.")
    }

    test("deployment facts determine element availability independently from eligibility") {
        val origin = ArtifactId("example:extension")
        val descriptor = descriptor().copy(availability = AvailabilityExpression.Fact("feature.preview", "enabled"))
        val contribution =
            KeyedElementContribution(
                ContributionKey(origin, "common", ProducerId("elements"), ContributionName("catalog.cbor")),
                ElementDiscoveryContribution(descriptors = listOf(descriptor), facets = emptyList()),
            )

        val unavailable =
            ElementCatalogAssembler.assemble(
                listOf(contribution),
                listOf(SourcePartCatalogEntry(origin, "common", Eligibility.Eligible)),
                DeploymentFacts(),
            )
        val available =
            ElementCatalogAssembler.assemble(
                listOf(contribution),
                listOf(SourcePartCatalogEntry(origin, "common", Eligibility.Eligible)),
                DeploymentFacts(mapOf("feature.preview" to "enabled")),
            )

        unavailable.entries.single().eligible shouldBe true
        unavailable.entries.single().available shouldBe false
        available.entries.single().available shouldBe true
    }
}

private fun descriptor(): ElementDescriptor {
    val id = DeclaredTypeId.parse("019d1c2a8f7b7cc18c2a4a7b2fd1e281")
    return ElementDescriptor(
        id = ElementTypeId(id),
        kind = ElementKind.ENTRY,
        type = ResolvedTypeRef(TypeId.Declared(id), 1),
        name = "Synthetic Entry",
        description = "Verifies discovery",
        icon = Icon.Iconify("material-symbols:science"),
        color = Color.parseRgb("#7C4DFF"),
        availability = AvailabilityExpression.Always,
    )
}
