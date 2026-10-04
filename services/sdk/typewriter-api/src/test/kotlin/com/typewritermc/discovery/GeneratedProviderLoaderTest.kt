package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import java.nio.file.Files
import java.nio.file.Path
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream

val GeneratedProviderLoaderTest by testSuite {
    test("identical shadow copies retain one physical provider owner") {
        val root = Files.createTempDirectory("generated-provider-identical")
        val first = providerArtifact(root.resolve("first.jar"), "main")
        val second = providerArtifact(root.resolve("second.jar"), "main")

        GeneratedProviderLoader()
            .load(
                artifacts =
                    listOf(
                        GeneratedProviderArtifact(ArtifactId("test:first"), first),
                        GeneratedProviderArtifact(ArtifactId("test:second"), second),
                    ),
                facts = DeploymentFacts(),
            ).use { deployment ->
                deployment.providers.registrars
                    .single()
                    .origin.artifact shouldBe ArtifactId("test:first")
            }
    }

    test("shadow copies with conflicting index metadata are rejected") {
        val root = Files.createTempDirectory("generated-provider-metadata")
        val first = providerArtifact(root.resolve("first.jar"), "main")
        val second = providerArtifact(root.resolve("second.jar"), "other")

        shouldThrow<IllegalArgumentException> {
            GeneratedProviderLoader().load(
                artifacts =
                    listOf(
                        GeneratedProviderArtifact(ArtifactId("test:first"), first),
                        GeneratedProviderArtifact(ArtifactId("test:second"), second),
                    ),
                facts = DeploymentFacts(),
            )
        }.message shouldBe
            "Generated provider class com.typewritermc.discovery.ShadowRegistrar has conflicting index metadata in " +
            "test:first, test:second."
    }

    test("shadow copies with conflicting class families are rejected") {
        val root = Files.createTempDirectory("generated-provider-classes")
        val first = providerArtifact(root.resolve("first.jar"), "main")
        val second = providerArtifact(root.resolve("second.jar"), "main", corruptClass = true)

        shouldThrow<IllegalArgumentException> {
            GeneratedProviderLoader().load(
                artifacts =
                    listOf(
                        GeneratedProviderArtifact(ArtifactId("test:first"), first),
                        GeneratedProviderArtifact(ArtifactId("test:second"), second),
                    ),
                facts = DeploymentFacts(),
            )
        }.message shouldBe
            "Generated provider class com.typewritermc.discovery.ShadowRegistrar has conflicting physical definitions in " +
            "test:first, test:second."
    }

    test("shadow copies with conflicting referenced classes are rejected") {
        val root = Files.createTempDirectory("generated-provider-references")
        val first = providerArtifact(root.resolve("first.jar"), "main", referencedClass = byteArrayOf(1))
        val second = providerArtifact(root.resolve("second.jar"), "main", referencedClass = byteArrayOf(2))

        shouldThrow<IllegalArgumentException> {
            GeneratedProviderLoader().load(
                artifacts =
                    listOf(
                        GeneratedProviderArtifact(ArtifactId("test:first"), first),
                        GeneratedProviderArtifact(ArtifactId("test:second"), second),
                    ),
                facts = DeploymentFacts(),
            )
        }.message shouldBe
            "Generated provider class com.typewritermc.discovery.ShadowRegistrar has artifacts with conflicting shared " +
            "classes: fixture/Referenced.class."
    }

    test("every pair of shadow copies is checked for conflicting referenced classes") {
        val root = Files.createTempDirectory("generated-provider-reference-pairs")
        val first = providerArtifact(root.resolve("first.jar"), "main")
        val second = providerArtifact(root.resolve("second.jar"), "main", referencedClass = byteArrayOf(1))
        val third = providerArtifact(root.resolve("third.jar"), "main", referencedClass = byteArrayOf(2))

        shouldThrow<IllegalArgumentException> {
            GeneratedProviderLoader().load(
                artifacts =
                    listOf(
                        GeneratedProviderArtifact(ArtifactId("test:first"), first),
                        GeneratedProviderArtifact(ArtifactId("test:second"), second),
                        GeneratedProviderArtifact(ArtifactId("test:third"), third),
                    ),
                facts = DeploymentFacts(),
            )
        }.message shouldBe
            "Generated provider class com.typewritermc.discovery.ShadowRegistrar has artifacts with conflicting shared " +
            "classes: fixture/Referenced.class."
    }
}

class ShadowRegistrar : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() = Unit
}

private fun providerArtifact(
    path: Path,
    sourcePart: String,
    corruptClass: Boolean = false,
    referencedClass: ByteArray? = null,
): Path {
    val providerName = ShadowRegistrar::class.java.name
    val classPath = providerName.replace('.', '/') + ".class"
    val classBytes = requireNotNull(ShadowRegistrar::class.java.getResourceAsStream("/$classPath")).use { it.readBytes() }
    if (corruptClass) classBytes[classBytes.lastIndex] = (classBytes.last() + 1).toByte()
    JarOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(JarEntry(GENERATED_PROVIDER_INDEX_PATH))
        archive.write("registrar\t$providerName\t$sourcePart\n".encodeToByteArray())
        archive.closeEntry()
        archive.putNextEntry(JarEntry(classPath))
        archive.write(classBytes)
        archive.closeEntry()
        referencedClass?.let { bytes ->
            archive.putNextEntry(JarEntry("fixture/Referenced.class"))
            archive.write(bytes)
            archive.closeEntry()
        }
    }
    return path
}
