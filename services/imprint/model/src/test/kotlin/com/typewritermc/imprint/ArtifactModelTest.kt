package com.typewritermc.imprint

import com.typewritermc.imprint.testing.sampleManifests
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val ArtifactModelTest by testSuite {
    test("caret constraint follows semantic compatibility") {
        val constraint = VersionConstraint("^1.3")

        constraint.accepts(ArtifactVersion("1.14.8")) shouldBe true
        constraint.accepts(ArtifactVersion("1.0.3")) shouldBe false
    }

    test("a caret constraint resolves Gradle dependencies up to, not including, the next major prerelease") {
        // The Gradle plugin hands this range to dependency resolution, so it is a contract with Gradle.
        VersionConstraint("^1.3").mavenRange shouldBe "[1.3.0,2.0.0-0)"
    }

    test("tilde and partial constraints stay within one minor line") {
        VersionConstraint("~1.3").accepts(ArtifactVersion("1.14.8")) shouldBe false
        VersionConstraint("1.3").accepts(ArtifactVersion("1.14.8")) shouldBe false
        VersionConstraint("~1.3").accepts(ArtifactVersion("1.3.9")) shouldBe true
    }

    test("constraints support comparisons alternatives and prereleases") {
        val constraint = VersionConstraint(">=1.2.0 <2.0.0 || ^3.1.0-rc.1")

        constraint.accepts(ArtifactVersion("1.8.0")) shouldBe true
        constraint.accepts(ArtifactVersion("3.1.0-rc.2")) shouldBe true
        constraint.accepts(ArtifactVersion("2.5.0")) shouldBe false
    }

    test("constraint intersections reject disjoint ranges") {
        VersionConstraint("^1.3").intersect(VersionConstraint("^2")) shouldBe null
        VersionConstraint("^1.3").intersect(VersionConstraint(">=1.14")) shouldNotBe null
    }

    sampleManifests().forEach { manifest ->
        test("the manifest codec preserves every field of a populated ${manifest::class.simpleName}") {
            val decoded = ImprintManifestCodec.decode(ImprintManifestCodec.encode(manifest))

            decoded::class shouldBe manifest::class
            // Contribution payloads are byte arrays, so equal manifests are compared by their canonical encoding.
            ImprintManifestCodec.encode(decoded).toList() shouldBe ImprintManifestCodec.encode(manifest).toList()
        }
    }

    test("hyphenated contribution identities survive the manifest codec") {
        val contribution =
            GeneratedContribution(
                source = ContributionSourceId("artifact:typewritermc:items"),
                sourcePart = "main",
                producer = ProducerId("future-producer"),
                name = ContributionName("core/collection-projections.cbor"),
                payload = byteArrayOf(1, 2, 3),
            )
        val manifest =
            CapabilityManifest(
                id = ArtifactId("typewritermc:items"),
                version = ArtifactVersion("1.0.0"),
                directRequirements = emptyList(),
                resolvedCapabilities = emptyList(),
                contributions = listOf(contribution),
            )

        val decoded = ImprintManifestCodec.decode(ImprintManifestCodec.encode(manifest))
        val actual = decoded.contributions.single()
        actual.producer shouldBe contribution.producer
        actual.name shouldBe contribution.name
        actual.payload.toList() shouldBe contribution.payload.toList()
    }

    test("contribution names reject path traversal and separators") {
        listOf("", "../file.cbor", "core//file.cbor", "core\\file.cbor", "/file.cbor", "core/space name.cbor").forEach { name ->
            shouldThrow<IllegalArgumentException> { ContributionName(name) }
        }
        shouldThrow<IllegalArgumentException> { ProducerId("core/types") }
    }

    test("hosted manifests require a runtime entrypoint") {
        shouldThrow<IllegalArgumentException> {
            RealmManifest(
                id = ArtifactId("typewritermc:realm"),
                version = ArtifactVersion("1.0.0"),
                hostApi = VersionConstraint("^1"),
                runtimeEntrypointClass = " ",
                contributions = emptyList(),
            )
        }
    }

    test("manifest decoder rejects a non current format") {
        val manifest =
            CapabilityManifest(
                format = 999,
                id = ArtifactId("typewritermc:items"),
                version = ArtifactVersion("1.2.3"),
                directRequirements = emptyList(),
                resolvedCapabilities = emptyList(),
                contributions = emptyList(),
            )

        shouldThrow<IllegalArgumentException> {
            ImprintManifestCodec.decode(ImprintManifestCodec.encode(manifest))
        }
    }
}
