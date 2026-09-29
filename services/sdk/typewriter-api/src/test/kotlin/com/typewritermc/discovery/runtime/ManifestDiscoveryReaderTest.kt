package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.TYPE_DISCOVERY_PRODUCER
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.ProducerId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val ManifestDiscoveryReaderTest by testSuite {
    test("generated hyphenated contributions cross the manifest and discovery boundary") {
        val origin = ArtifactId("typewritermc:example")
        val known =
            GeneratedContribution(
                source = ContributionSourceId("artifact:${origin.value}"),
                sourcePart = "main",
                producer = TYPE_DISCOVERY_PRODUCER,
                name = ContributionName("core/collection-projections.cbor"),
                payload =
                    TypeDiscoveryContributionCodec.encode(
                        TypeDiscoveryContribution(
                            definitions = emptyList(),
                            prototypeBindings = emptyList(),
                            executableBindings = emptyList(),
                        ),
                    ),
            )
        val unknown =
            GeneratedContribution(
                source = ContributionSourceId("artifact:${origin.value}"),
                sourcePart = "main",
                producer = ProducerId("future-producer"),
                name = ContributionName("other/data-file.cbor"),
                payload = byteArrayOf(7),
            )
        val manifest =
            CapabilityManifest(
                id = origin,
                version = ArtifactVersion("1.0.0"),
                directRequirements = emptyList(),
                resolvedCapabilities = emptyList(),
                contributions = listOf(known, unknown),
            )

        val read = ManifestDiscoveryReader.read(listOf(ImprintManifestCodec.decode(ImprintManifestCodec.encode(manifest))))
        val knownKey = read.types.single().key
        val unknownContribution = read.unknown.single()

        knownKey.name shouldBe known.name
        knownKey.producer shouldBe TYPE_DISCOVERY_PRODUCER
        unknownContribution.contribution.name shouldBe unknown.name
        unknownContribution.contribution.producer shouldBe unknown.producer
    }

    test("equal embedded copies resolve once and retain every carrier") {
        val payload = TypeDiscoveryContributionCodec.encode(
            TypeDiscoveryContribution(definitions = emptyList(), prototypeBindings = emptyList(), executableBindings = emptyList()),
        )
        val contribution = GeneratedContribution(
            source = ContributionSourceId("bundle:platform"),
            sourcePart = "main",
            producer = TYPE_DISCOVERY_PRODUCER,
            name = ContributionName("declared.cbor"),
            payload = payload,
        )
        val first = capability("realm", contribution)
        val second = capability("paper", contribution)

        val read = ManifestDiscoveryReader.read(listOf(first, second))

        read.types.single().carriers shouldBe setOf(first.id, second.id)
        read.types.single().key.source shouldBe ContributionSourceId("bundle:platform")
    }

    test("different bytes for one logical contribution fail with both carriers") {
        val contribution = GeneratedContribution(
            source = ContributionSourceId("bundle:platform"),
            sourcePart = "main",
            producer = TYPE_DISCOVERY_PRODUCER,
            name = ContributionName("declared.cbor"),
            payload = byteArrayOf(1),
        )

        val failure = shouldThrow<IllegalArgumentException> {
            ManifestDiscoveryReader.read(
                listOf(capability("realm", contribution), capability("paper", contribution.copy(payload = byteArrayOf(2)))),
            )
        }

        failure.message?.contains("realm") shouldBe true
        failure.message?.contains("paper") shouldBe true
    }
}

private fun capability(id: String, contribution: GeneratedContribution) =
    CapabilityManifest(
        id = ArtifactId(id),
        version = ArtifactVersion("1.0.0"),
        directRequirements = emptyList(),
        resolvedCapabilities = emptyList(),
        contributions = listOf(contribution),
    )
