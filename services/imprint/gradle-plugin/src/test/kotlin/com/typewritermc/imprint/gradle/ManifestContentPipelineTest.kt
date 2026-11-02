package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.gradle.testing.contribution
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

val ManifestContentPipelineTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val context =
        ManifestAssemblyContext(
            artifactId = ArtifactId("typewritermc:realm"),
            artifactVersion = ArtifactVersion("1.0.0"),
            artifactKind = ArtifactKind.REALM,
        )

    test("source order does not change canonical manifest content") {
        val first = manifestContentSource(contribution("z.cbor"), runtimeEntrypoints = listOf("fixture.Runtime"))
        val second = manifestContentSource(contribution("a.cbor"))

        val forward = realmContentPipeline(first, second).assemble(context)
        val reverse = realmContentPipeline(second, first).assemble(context)

        forward.contributions.map { it.name.value } shouldContainExactly listOf("a.cbor", "z.cbor")
        reverse.contributions.map { it.name.value } shouldContainExactly listOf("a.cbor", "z.cbor")
        forward.runtimeEntrypoints shouldBe reverse.runtimeEntrypoints
    }

    test("duplicate contribution keys fail before canonicalization") {
        val duplicate = contribution("duplicate.cbor")
        val failure =
            shouldThrow<IllegalArgumentException> {
                libraryContentPipeline(manifestContentSource(duplicate) + manifestContentSource(duplicate)).assemble(context)
            }

        failure.message shouldBe
            "Duplicate Imprint contribution keys: [artifact:typewritermc:realm, main, types, duplicate.cbor]."
    }

    test("hosted and library pipelines enforce runtime entrypoint policy") {
        shouldThrow<IllegalArgumentException> {
            realmContentPipeline(manifestContentSource(contribution("local.cbor")), manifestContentSource()).assemble(context)
        }.message shouldBe "A hosted artifact must declare exactly one runtime entrypoint, but found 0."

        shouldThrow<IllegalArgumentException> {
            libraryContentPipeline(manifestContentSource(runtimeEntrypoints = listOf("fixture.Runtime"))).assemble(context)
        }.message shouldBe "Only hosted Imprint artifacts may declare a runtime entrypoint."
    }
}
