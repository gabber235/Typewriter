package com.typewritermc.imprint.gradle

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.GeneratedContribution
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

val ManifestContentPipelineTest by testSuite {
    val context =
        ManifestAssemblyContext(
            artifactId = ArtifactId("typewritermc:realm"),
            artifactVersion = ArtifactVersion("1.0.0"),
            artifactKind = ArtifactKind.REALM,
        )

    test("source order does not change canonical manifest content") {
        val first = source(contribution("z.cbor"), runtimeEntrypoints = listOf("fixture.Runtime"))
        val second = source(contribution("a.cbor"))

        val forward = realmContentPipeline(first, second).assemble(context)
        val reverse = realmContentPipeline(second, first).assemble(context)

        forward.contributions.map(GeneratedContribution::name) shouldContainExactly listOf("a.cbor", "z.cbor")
        reverse.contributions.map(GeneratedContribution::name) shouldContainExactly listOf("a.cbor", "z.cbor")
        forward.runtimeEntrypoints shouldBe reverse.runtimeEntrypoints
    }

    test("duplicate contribution keys fail before canonicalization") {
        val duplicate = contribution("duplicate.cbor")
        val failure =
            shouldThrow<IllegalArgumentException> {
                libraryContentPipeline(source(duplicate) + source(duplicate)).assemble(context)
            }

        failure.message shouldBe
            "Duplicate Imprint contribution keys: [typewritermc:realm, main, types, duplicate.cbor]."
    }

    test("hosted and library pipelines enforce runtime entrypoint policy") {
        shouldThrow<IllegalArgumentException> {
            realmContentPipeline(source(contribution("local.cbor")), source()).assemble(context)
        }.message shouldBe "A hosted artifact must declare exactly one runtime entrypoint, but found 0."

        shouldThrow<IllegalArgumentException> {
            libraryContentPipeline(source(runtimeEntrypoints = listOf("fixture.Runtime"))).assemble(context)
        }.message shouldBe "Only hosted Imprint artifacts may declare a runtime entrypoint."
    }
}

private fun source(
    vararg contributions: GeneratedContribution,
    runtimeEntrypoints: List<String> = emptyList(),
): ManifestContentSource =
    ManifestContentSource {
        ManifestContent(
            contributions = contributions.toList(),
            runtimeEntrypoints = runtimeEntrypoints,
        )
    }

private fun contribution(name: String): GeneratedContribution =
    GeneratedContribution(
        origin = ArtifactId("typewritermc:realm"),
        sourcePart = "main",
        producer = "types",
        name = name,
        payload = name.encodeToByteArray(),
    )
