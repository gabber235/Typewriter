package com.typewritermc.engine

import de.infix.testBalloon.framework.core.testSuite
import io.github.z4kn4fein.semver.VersionFormatException
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.shouldBe

val SemanticVersionTest by testSuite {
    test("parses the complete semantic version syntax") {
        val version = SemanticVersion.parse("1.2.3-alpha.1+build.42")

        version.major shouldBe 1
        version.minor shouldBe 2
        version.patch shouldBe 3
        version.preRelease shouldBe "alpha.1"
        version.buildMetadata shouldBe "build.42"
        version.toString() shouldBe "1.2.3-alpha.1+build.42"
    }

    test("orders prerelease versions before releases") {
        SemanticVersion.parse("1.2.3-rc.1") shouldBeLessThan SemanticVersion.parse("1.2.3")
    }

    test("rejects abbreviated and invalid semantic versions") {
        shouldThrow<VersionFormatException> { SemanticVersion.parse("1.2") }
        shouldThrow<VersionFormatException> { SemanticVersion.parse("1.2.3.4") }
        shouldThrow<VersionFormatException> { SemanticVersion.parse("1.2.3-01") }
    }

    test("version requirements accept prerelease and build metadata") {
        val requirement = VersionRequirement(SemanticVersion.parse("1.2.3-alpha.1"))

        requirement.accepts(SemanticVersion.parse("1.2.3-alpha.2")) shouldBe true
        requirement.accepts(SemanticVersion.parse("1.2.3+local")) shouldBe true
        requirement.accepts(SemanticVersion.parse("2.0.0")) shouldBe false
    }
}
