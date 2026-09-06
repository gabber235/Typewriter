package com.typewritermc.imprint

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val ArtifactModelTest by testSuite {
    test("caret constraint follows semantic compatibility") {
        val constraint = VersionConstraint("^1.3")

        constraint.accepts(ArtifactVersion("1.14.8")) shouldBe true
        constraint.accepts(ArtifactVersion("1.0.3")) shouldBe false
        constraint.mavenRange shouldBe "[1.3.0,2.0.0-0)"
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

    test("canonical manifest codec preserves sealed artifact variants") {
        val manifest =
            CapabilityManifest(
                id = ArtifactId("typewritermc:items"),
                version = ArtifactVersion("1.2.3"),
                directRequirements = emptyList(),
                resolvedCapabilities = emptyList(),
                contributions = emptyList(),
            )

        ImprintManifestCodec.decode(ImprintManifestCodec.encode(manifest)) shouldBe manifest
    }
}
