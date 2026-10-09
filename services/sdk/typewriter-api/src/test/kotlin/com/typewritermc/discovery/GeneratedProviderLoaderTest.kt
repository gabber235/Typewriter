package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionSourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import java.nio.file.Files
import java.nio.file.Path
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import kotlin.reflect.KClass

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
                domain = DiscoveryDomains.Execution,
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
                domain = DiscoveryDomains.Execution,
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
                domain = DiscoveryDomains.Execution,
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
                domain = DiscoveryDomains.Execution,
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
                domain = DiscoveryDomains.Execution,
            )
        }.message shouldBe
            "Generated provider class com.typewritermc.discovery.ShadowRegistrar has artifacts with conflicting shared " +
            "classes: fixture/Referenced.class."
    }

    test("rejects duplicate eligible registrar identity within one contribution source") {
        val root = Files.createTempDirectory("generated-registrar-identity")
        val first = providerArtifact(root.resolve("first.jar"), "common")
        val second = providerArtifact(root.resolve("second.jar"), "execution", providerClass = DuplicateRegistrarProvider::class)
        val source = ContributionSourceId("fixture")

        shouldThrow<IllegalArgumentException> {
            GeneratedProviderLoader().load(
                artifacts =
                    listOf(
                        GeneratedProviderArtifact(ArtifactId("fixture:first"), first, source),
                        GeneratedProviderArtifact(ArtifactId("fixture:second"), second, source),
                    ),
                facts = DeploymentFacts(),
                domain = DiscoveryDomains.Execution,
            )
        }
    }

    listOf(DiscoveryDomains.Realm, DiscoveryDomains.Execution).forEach { domain ->
        test("binds only eligible registrars for ${domain.value} with their declared identity") {
            val root = Files.createTempDirectory("generated-registrar-domains")
            val execution = providerArtifact(root.resolve("execution.jar"), "execution")
            val realm = providerArtifact(root.resolve("realm.jar"), "realm", providerClass = RealmFixtureRegistrarProvider::class)
            val constructed = mutableListOf<String>()
            val instantiator =
                GeneratedProviderInstantiator { type ->
                    constructed += type.name
                    GeneratedProviderInstantiator.PublicZeroArgument.instantiate(type)
                }
            GeneratedProviderLoader()
                .load(
                    artifacts =
                        listOf(
                            GeneratedProviderArtifact(ArtifactId("fixture:execution"), execution),
                            GeneratedProviderArtifact(ArtifactId("fixture:realm"), realm),
                        ),
                    facts = DeploymentFacts(),
                    domain = domain,
                    instantiator = instantiator,
                ).use { deployment ->
                    val selected = deployment.providers.registrars.single()
                    selected.descriptor.id shouldBe if (domain == DiscoveryDomains.Realm) "realm.runtime" else "shadow.runtime"
                    selected.descriptor.domains shouldBe setOf(domain)
                    val eligible = if (domain == DiscoveryDomains.Realm) RealmFixtureRegistrar::class else ExecutionFixtureRegistrar::class
                    val excluded = if (domain == DiscoveryDomains.Realm) ExecutionFixtureRegistrar::class else RealmFixtureRegistrar::class
                    constructed.count { it == eligible.java.name } shouldBe 1
                    constructed.count { it == excluded.java.name } shouldBe 0
                }
        }
    }
}

class ShadowRegistrar : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor("shadow.runtime", setOf(DiscoveryDomains.Execution))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        instantiator.instantiate(ExecutionFixtureRegistrar::class.java) as RuntimeRegistrar
}

class DuplicateRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor("shadow.runtime", setOf(DiscoveryDomains.Execution))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        instantiator.instantiate(ExecutionFixtureRegistrar::class.java) as RuntimeRegistrar
}

class RealmFixtureRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor("realm.runtime", setOf(DiscoveryDomains.Realm))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        instantiator.instantiate(RealmFixtureRegistrar::class.java) as RuntimeRegistrar
}

class ExecutionFixtureRegistrar : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() = Unit
}

class RealmFixtureRegistrar : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() = Unit
}

private fun providerArtifact(
    path: Path,
    sourcePart: String,
    corruptClass: Boolean = false,
    referencedClass: ByteArray? = null,
    providerClass: KClass<*> = ShadowRegistrar::class,
): Path {
    val providerName = providerClass.java.name
    val classPath = providerName.replace('.', '/') + ".class"
    val classBytes = requireNotNull(providerClass.java.getResourceAsStream("/$classPath")).use { it.readBytes() }
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
