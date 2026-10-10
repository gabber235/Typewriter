package com.typewritermc.discovery

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionSourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import java.lang.reflect.InvocationTargetException
import java.nio.file.Files
import java.nio.file.Path
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import kotlin.reflect.KClass

val GeneratedProviderLoaderTest by testSuite {
    test("deployment owners share constructor dependencies and borrowed services") {
        val service = FixtureRuntimeService()
        val owners =
            DeploymentRuntimeOwners(
                requireNotNull(OwnerConsumer::class.java.classLoader),
                mapOf(FixtureRuntimeServiceContract::class.java to service),
            )

        val first = owners.resolve(OwnerConsumer::class.java) as OwnerConsumer
        val second = owners.resolve(OwnerConsumer::class.java) as OwnerConsumer

        first shouldBe second
        first.service shouldBe service
    }

    test("deployment owners reject missing services and constructor cycles") {
        val owners = DeploymentRuntimeOwners(requireNotNull(OwnerConsumer::class.java.classLoader), emptyMap())

        shouldThrow<IllegalArgumentException> { owners.resolve(OwnerConsumer::class.java) }
        shouldThrow<IllegalArgumentException> { owners.resolve(CycleOwnerA::class.java) }
    }

    test("deployment owners enforce exact deployment class identity") {
        val ownerClass = OwnerConsumer::class.java
        val deploymentLoader = requireNotNull(ownerClass.classLoader)
        val binaryName = ownerClass.name
        val resourceName = binaryName.replace('.', '/') + ".class"
        val bytecode = requireNotNull(deploymentLoader.getResourceAsStream(resourceName)).use { it.readBytes() }
        val foreignClass =
            object : ClassLoader(deploymentLoader) {
                override fun loadClass(
                    name: String,
                    resolve: Boolean,
                ): Class<*> {
                    if (name != binaryName) return super.loadClass(name, resolve)
                    val loaded = findLoadedClass(name)
                    val defined = loaded ?: defineClass(name, bytecode, 0, bytecode.size)
                    if (resolve) resolveClass(defined)
                    return defined
                }
            }.loadClass(binaryName)
        val owners = DeploymentRuntimeOwners(deploymentLoader, emptyMap())

        shouldThrow<IllegalArgumentException> { owners.resolve(foreignClass) }.message shouldBe
            "Runtime owner $binaryName belongs to a different deployment."
    }

    test("deployment owners clear constructor resolution after failure") {
        val owners =
            DeploymentRuntimeOwners(
                requireNotNull(FailingOwner::class.java.classLoader),
                emptyMap(),
            )

        repeat(2) {
            shouldThrow<InvocationTargetException> { owners.resolve(FailingOwner::class.java) }
                .cause
                ?.message shouldBe "construction failed"
        }
    }

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
            ExecutionFixtureRegistrar.constructions = 0
            RealmFixtureRegistrar.constructions = 0
            GeneratedProviderLoader()
                .load(
                    artifacts =
                        listOf(
                            GeneratedProviderArtifact(ArtifactId("fixture:execution"), execution),
                            GeneratedProviderArtifact(ArtifactId("fixture:realm"), realm),
                        ),
                    facts = DeploymentFacts(),
                    domain = domain,
                ).use { deployment ->
                    val selected = deployment.providers.registrars.single()
                    selected.descriptor.id shouldBe if (domain == DiscoveryDomains.Realm) "realm.runtime" else "shadow.runtime"
                    selected.descriptor.domains shouldBe setOf(domain)
                    val eligibleConstructions =
                        if (domain == DiscoveryDomains.Realm) {
                            RealmFixtureRegistrar.constructions
                        } else {
                            ExecutionFixtureRegistrar.constructions
                        }
                    val excludedConstructions =
                        if (domain == DiscoveryDomains.Realm) {
                            ExecutionFixtureRegistrar.constructions
                        } else {
                            RealmFixtureRegistrar.constructions
                        }
                    eligibleConstructions shouldBe 1
                    excludedConstructions shouldBe 0
                }
        }
    }
}

private interface FixtureRuntimeServiceContract

private class FixtureRuntimeService : FixtureRuntimeServiceContract

private class OwnerConsumer(
    val service: FixtureRuntimeServiceContract,
)

private class CycleOwnerA(
    val next: CycleOwnerB,
)

private class CycleOwnerB(
    val next: CycleOwnerA,
)

private class FailingOwner {
    init {
        error("construction failed")
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
    init {
        constructions += 1
    }

    context(scope: RuntimeScope)
    override suspend fun register() = Unit

    companion object {
        var constructions = 0
    }
}

class RealmFixtureRegistrar : RuntimeRegistrar {
    init {
        constructions += 1
    }

    context(scope: RuntimeScope)
    override suspend fun register() = Unit

    companion object {
        var constructions = 0
    }
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
