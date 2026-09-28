package com.typewritermc.discovery.runtime

import com.typewritermc.discovery.TYPE_DISCOVERY_PRODUCER
import com.typewritermc.discovery.TypeDiscoveryContribution
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.ProducerId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ManifestDiscoveryReaderTest by testSuite {
    test("generated hyphenated contributions cross the manifest and discovery boundary") {
        val origin = ArtifactId("typewritermc:example")
        val known =
            GeneratedContribution(
                origin = origin,
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
                origin = origin,
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
        unknownContribution.name shouldBe unknown.name
        unknownContribution.producer shouldBe unknown.producer
    }
}
