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
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.encodeToByteArray

@OptIn(ExperimentalSerializationApi::class)
val ElementModelTest by testSuite {
    test("element contribution preserves typed icon and color values") {
        val descriptor = descriptor()
        val contribution =
            ElementDiscoveryContribution(
                descriptors =
                    listOf(
                        descriptor.copy(
                            searchDefinition =
                                ElementSearchDefinition(
                                    ElementSearchPolicy.ORDINARY_TEXT,
                                    listOf(
                                        ElementSearchPropertyOverride(
                                            descriptor.type,
                                            "title",
                                            ElementSearchMode.SUMMARY,
                                        ),
                                    ),
                                    listOf(descriptor.type),
                                ),
                        ),
                    ),
            )

        val decoded = ElementDiscoveryContributionCodec.decode(ElementDiscoveryContributionCodec.encode(contribution))

        decoded shouldBe contribution
    }

    test("element contribution decodes descriptors produced before search metadata") {
        val descriptor = descriptor()
        val legacyContribution =
            LegacyElementDiscoveryContribution(
                listOf(
                    LegacyElementDescriptor(
                        descriptor.id,
                        descriptor.type,
                        descriptor.name,
                        descriptor.description,
                        descriptor.icon,
                        descriptor.color,
                        descriptor.availability,
                    ),
                ),
            )

        val decoded = ElementDiscoveryContributionCodec.decode(legacyCbor.encodeToByteArray(legacyContribution))

        decoded.descriptors.single() shouldBe descriptor
        decoded.descriptors.single().searchDefinition shouldBe null
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
                        ElementDiscoveryContribution(descriptors = listOf(descriptor)),
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
                ElementDiscoveryContribution(descriptors = listOf(descriptor)),
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

@Serializable
private data class LegacyElementDiscoveryContribution(
    val descriptors: List<LegacyElementDescriptor>,
)

@Serializable
private data class LegacyElementDescriptor(
    val id: ElementTypeId,
    val type: ResolvedTypeRef,
    val name: String,
    val description: String,
    val icon: Icon,
    val color: Color,
    val availability: AvailabilityExpression,
)

@OptIn(ExperimentalSerializationApi::class)
private val legacyCbor = Cbor { encodeDefaults = true }

private fun descriptor(): ElementDescriptor {
    val id = DeclaredTypeId.parse("019d1c2a8f7b7cc18c2a4a7b2fd1e281")
    return ElementDescriptor(
        id = ElementTypeId(id),
        type = ResolvedTypeRef(TypeId.Declared(id), 1),
        name = "Synthetic Entry",
        description = "Verifies discovery",
        icon = Icon.Iconify("material-symbols:science"),
        color = Color.parseRgb("#7C4DFF"),
        availability = AvailabilityExpression.Always,
    )
}
