package com.typewritermc.discovery

import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.NativeBindingFactory
import java.lang.reflect.Modifier
import java.net.URL
import java.net.URLClassLoader
import java.nio.file.Files
import java.nio.file.Path
import java.security.MessageDigest
import java.util.jar.JarFile

data class GeneratedProviderArtifact(
    val artifact: ArtifactId,
    val path: Path,
    val source: ContributionSourceId = ContributionSourceId(artifact.value),
    val acceptedSourceParts: Set<String>? = null,
)

fun interface GeneratedProviderInstantiator {
    fun instantiate(providerClass: Class<*>): Any

    companion object {
        val PublicZeroArgument =
            GeneratedProviderInstantiator { providerClass ->
                providerClass.fields
                    .singleOrNull { field ->
                        field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type == providerClass
                    }?.let { return@GeneratedProviderInstantiator it.get(null) }
                val constructor = providerClass.getDeclaredConstructor()
                require(Modifier.isPublic(constructor.modifiers)) {
                    "Generated provider ${providerClass.name} requires a public zero argument constructor."
                }
                constructor.newInstance()
            }

        fun resolving(resolve: (Class<*>) -> Any): GeneratedProviderInstantiator =
            GeneratedProviderInstantiator { providerClass ->
                providerClass.fields
                    .singleOrNull { field ->
                        field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type == providerClass
                    }?.let { return@GeneratedProviderInstantiator it.get(null) }
                val constructors = providerClass.constructors.filter { Modifier.isPublic(it.modifiers) }
                require(constructors.size == 1) {
                    "Generated provider ${providerClass.name} requires one public constructor."
                }
                val constructor = constructors.single()
                constructor.newInstance(*constructor.parameterTypes.map(resolve).toTypedArray())
            }
    }
}

data class OwnedRealmCapability(
    val origin: ProviderOrigin,
    val provider: RealmCapabilityProvider,
)

data class OwnedRuntimeRegistrar(
    val origin: ProviderOrigin,
    val descriptor: RuntimeRegistrarDescriptor,
    val registrar: RuntimeRegistrar,
)

data class OwnedCollectionProjection(
    val origin: ProviderOrigin,
    val specification: com.typewritermc.presentation.CollectionProjectionSpec,
)

data class LoadedGeneratedProviders(
    val contributions: CatalogContributions,
    val capabilities: List<OwnedRealmCapability>,
    val registrars: List<OwnedRuntimeRegistrar>,
    val collectionProjections: List<OwnedCollectionProjection>,
)

class GeneratedProviderDeployment internal constructor(
    val providers: LoadedGeneratedProviders,
    val facts: DeploymentFacts,
    private val classLoader: URLClassLoader,
) : AutoCloseable {
    private val lock = Any()
    private var references = 1
    private var closeRequested = false

    fun retain(): ProviderLease =
        synchronized(lock) {
            check(references > 0) { "Generated provider deployment is closed." }
            references += 1
            DeploymentLease(this)
        }

    override fun close() {
        release(owner = true)
    }

    private fun release(owner: Boolean) {
        val closeClassLoader =
            synchronized(lock) {
                if (owner) {
                    if (closeRequested) return
                    closeRequested = true
                }
                check(references > 0) { "Generated provider deployment reference count is invalid." }
                references -= 1
                references == 0
            }
        if (closeClassLoader) classLoader.close()
    }

    private class DeploymentLease(
        private var deployment: GeneratedProviderDeployment?,
    ) : ProviderLease {
        override fun close() {
            val current = synchronized(this) { deployment.also { deployment = null } } ?: return
            current.release(owner = false)
        }
    }
}

class RetainedOwnedProviderRegistry(
    private val delegate: OwnedProviderRegistry,
    private val deployment: GeneratedProviderDeployment,
) : OwnedProviderRegistry {
    override fun retain(origin: ProviderOrigin): ProviderLease {
        val provider = delegate.retain(origin)
        val incarnation =
            try {
                deployment.retain()
            } catch (failure: Throwable) {
                runCatching { provider.close() }.exceptionOrNull()?.let(failure::addSuppressed)
                throw failure
            }
        return CombinedProviderLease(provider, incarnation)
    }

    override fun configurations(): List<OwnedConfiguration> = delegate.configurations()

    override fun presentations(): List<OwnedPresentation> = delegate.presentations()

    override fun nativeBindings(): List<OwnedNativeBinding> = delegate.nativeBindings()

    override fun checks(): List<OwnedCheck> = delegate.checks()
}

private class CombinedProviderLease(
    private var first: ProviderLease?,
    private var second: ProviderLease?,
) : ProviderLease {
    override fun close() {
        val leases =
            synchronized(this) {
                val current = listOfNotNull(first, second)
                first = null
                second = null
                current
            }
        val failures = leases.mapNotNull { runCatching { it.close() }.exceptionOrNull() }
        if (failures.isNotEmpty()) {
            val failure = failures.first()
            failures.drop(1).forEach(failure::addSuppressed)
            throw failure
        }
    }
}

object GeneratedProviderIndex {
    fun parse(content: String): List<GeneratedProviderIndexEntry> {
        val kinds = GeneratedProviderKind.entries.associateBy(GeneratedProviderKind::key)
        val entries =
            content
                .lineSequence()
                .map(String::trim)
                .filter(String::isNotEmpty)
                .mapIndexed { index, line ->
                    val columns = line.split('\t')
                    require(columns.size == 3 && columns.none(String::isBlank)) {
                        "Generated provider index line ${index + 1} must contain kind, provider class, and source part."
                    }
                    val kind =
                        requireNotNull(kinds[columns[0]]) {
                            "Generated provider index line ${index + 1} uses unknown kind ${columns[0]}."
                        }
                    require(columns[1].matches(QUALIFIED_CLASS_PATTERN)) {
                        "Generated provider index line ${index + 1} has an invalid provider class."
                    }
                    require(columns[2].matches(SOURCE_PART_PATTERN)) {
                        "Generated provider index line ${index + 1} has an invalid source part."
                    }
                    GeneratedProviderIndexEntry(kind, columns[1], columns[2])
                }.toList()
        require(entries.distinct().size == entries.size) { "Generated provider index contains duplicate rows." }
        return entries
    }
}

class GeneratedProviderLoader {
    fun load(
        artifacts: List<GeneratedProviderArtifact>,
        facts: DeploymentFacts,
        domain: DiscoveryDomainId,
        acceptedKinds: Set<GeneratedProviderKind> = GeneratedProviderKind.entries.toSet(),
        instantiator: GeneratedProviderInstantiator = GeneratedProviderInstantiator.PublicZeroArgument,
        capabilityOwners: CapabilityOwnerResolver? = null,
        parentClassLoader: ClassLoader = requireNotNull(javaClass.classLoader),
    ): GeneratedProviderDeployment {
        require(artifacts.map(GeneratedProviderArtifact::artifact).distinct().size == artifacts.size) {
            "Generated provider artifacts must have unique identities."
        }
        val indexed =
            artifacts
                .flatMap { artifact ->
                    readIndex(artifact)
                        .filter { entry ->
                            entry.kind in acceptedKinds &&
                                (artifact.acceptedSourceParts == null || entry.sourcePart in artifact.acceptedSourceParts)
                        }.map { entry -> IndexedProvider(artifact, entry) }
                }
        val canonical = canonicalProviders(indexed)
        val classLoader =
            GeneratedProviderClassLoader(
                artifacts.map { it.path.toUri().toURL() }.toTypedArray(),
                parentClassLoader,
                canonical.mapTo(linkedSetOf()) { it.entry.providerClass },
            )
        return try {
            val loaded =
                canonical
                    .map { indexedProvider ->
                        val artifact = indexedProvider.artifact
                        val entry = indexedProvider.entry
                        val providerClass = Class.forName(entry.providerClass, false, classLoader)
                        requirePhysicalOwner(providerClass, artifact)
                        requireProviderType(providerClass, entry.kind)
                        LoadedProvider(entry, origin(artifact, entry), instantiator.instantiate(providerClass))
                    }.sortedWith(compareBy({ it.origin.artifact.value }, { it.entry.sourcePart }, { it.entry.providerClass }))
            GeneratedProviderDeployment(assemble(loaded, capabilityOwners, domain, instantiator), facts, classLoader)
        } catch (failure: Throwable) {
            runCatching { classLoader.close() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }

    private fun requirePhysicalOwner(
        providerClass: Class<*>,
        artifact: GeneratedProviderArtifact,
    ) {
        val location =
            requireNotNull(providerClass.protectionDomain?.codeSource?.location) {
                "Generated provider ${providerClass.name} has no physical code source."
            }
        val actual = Path.of(location.toURI()).toRealPath()
        val expected = artifact.path.toRealPath()
        require(actual == expected) {
            "Generated provider ${providerClass.name} was indexed by ${artifact.artifact} at $expected but loaded from $actual."
        }
    }

    private fun requireProviderType(
        providerClass: Class<*>,
        kind: GeneratedProviderKind,
    ) {
        val expected =
            when (kind) {
                GeneratedProviderKind.Type -> GeneratedTypeProvider::class.java
                GeneratedProviderKind.NativeBinding -> NativeBindingFactory::class.java
                GeneratedProviderKind.Resource -> GeneratedResourceProvider::class.java
                GeneratedProviderKind.Relation -> GeneratedRelationProvider::class.java
                GeneratedProviderKind.EndpointBindings -> GeneratedEndpointBindingsProvider::class.java
                GeneratedProviderKind.Configuration -> GeneratedConfigurationProvider::class.java
                GeneratedProviderKind.Presentation -> GeneratedPresentationProvider::class.java
                GeneratedProviderKind.Check -> GeneratedCheckProvider::class.java
                GeneratedProviderKind.Capability -> GeneratedCapabilityProvider::class.java
                GeneratedProviderKind.Registrar -> GeneratedRuntimeRegistrarProvider::class.java
                GeneratedProviderKind.CollectionProjection -> GeneratedCollectionProjectionProvider::class.java
            }
        require(expected.isAssignableFrom(providerClass)) {
            "Generated ${kind.key} provider ${providerClass.name} must implement ${expected.name}."
        }
    }

    private fun readIndex(artifact: GeneratedProviderArtifact): List<GeneratedProviderIndexEntry> {
        val content =
            if (Files.isDirectory(artifact.path)) {
                val resource = artifact.path.resolve(GENERATED_PROVIDER_INDEX_PATH)
                if (Files.exists(resource)) Files.readString(resource) else ""
            } else {
                JarFile(artifact.path.toFile()).use { archive ->
                    val entry = archive.getJarEntry(GENERATED_PROVIDER_INDEX_PATH) ?: return emptyList()
                    archive.getInputStream(entry).bufferedReader().use { it.readText() }
                }
            }
        return GeneratedProviderIndex.parse(content)
    }

    private fun canonicalProviders(indexed: List<IndexedProvider>): List<IndexedProvider> {
        val classDigests = mutableMapOf<Path, Map<String, ByteArray>>()
        return indexed
            .groupBy { it.entry.providerClass }
            .values
            .map { copies ->
                val first = copies.first()
                if (copies.size == 1) return@map first
                val metadata = copies.map(IndexedProvider::entry).distinct()
                require(metadata.size == 1) {
                    "Generated provider class ${first.entry.providerClass} has conflicting index metadata in " +
                        copies.joinToString { it.artifact.artifact.value } + "."
                }
                val expected = readProviderClassFamily(first)
                val conflicting =
                    copies.drop(1).filter { copy ->
                        !sameClassFamily(expected, readProviderClassFamily(copy))
                    }
                require(conflicting.isEmpty()) {
                    "Generated provider class ${first.entry.providerClass} has conflicting physical definitions in " +
                        copies.joinToString { it.artifact.artifact.value } + "."
                }
                val artifactCopies = copies.map(IndexedProvider::artifact).distinctBy(GeneratedProviderArtifact::path)
                val sharedConflicts =
                    artifactCopies.indices
                        .flatMap { firstIndex ->
                            val firstArtifact = artifactCopies[firstIndex]
                            val firstDigests =
                                classDigests.getOrPut(firstArtifact.path) { readClassDigests(firstArtifact) }
                            (firstIndex + 1 until artifactCopies.size).flatMap { secondIndex ->
                                val secondArtifact = artifactCopies[secondIndex]
                                conflictingClasses(
                                    firstDigests,
                                    classDigests.getOrPut(secondArtifact.path) { readClassDigests(secondArtifact) },
                                )
                            }
                        }.distinct()
                        .sorted()
                require(sharedConflicts.isEmpty()) {
                    "Generated provider class ${first.entry.providerClass} has artifacts with conflicting shared classes: " +
                        sharedConflicts.take(20).joinToString() + "."
                }
                first
            }
    }

    private fun readProviderClassFamily(provider: IndexedProvider): Map<String, ByteArray> {
        val providerPath = provider.entry.providerClass.replace('.', '/')
        val classFile = "$providerPath.class"
        val nestedPrefix = "$providerPath\$"
        val family =
            if (Files.isDirectory(provider.artifact.path)) {
                val directory = provider.artifact.path.resolve(providerPath.substringBeforeLast('/'))
                if (!Files.isDirectory(directory)) {
                    emptyMap()
                } else {
                    Files.list(directory).use { entries ->
                        entries
                            .iterator()
                            .asSequence()
                            .filter { path ->
                                val relative =
                                    provider.artifact.path
                                        .relativize(path)
                                        .toString()
                                        .replace('\\', '/')
                                relative == classFile ||
                                    (relative.startsWith(nestedPrefix) && relative.endsWith(".class"))
                            }.associate { path ->
                                provider.artifact.path
                                    .relativize(path)
                                    .toString()
                                    .replace('\\', '/') to Files.readAllBytes(path)
                            }
                    }
                }
            } else {
                JarFile(provider.artifact.path.toFile()).use { archive ->
                    archive
                        .entries()
                        .asSequence()
                        .filter { entry ->
                            entry.name == classFile ||
                                (entry.name.startsWith(nestedPrefix) && entry.name.endsWith(".class"))
                        }.associate { entry -> entry.name to archive.getInputStream(entry).use { it.readBytes() } }
                }
            }
        require(classFile in family) {
            "Generated provider ${provider.entry.providerClass} is indexed by ${provider.artifact.artifact} but has no class file."
        }
        return family
    }

    private fun sameClassFamily(
        expected: Map<String, ByteArray>,
        actual: Map<String, ByteArray>,
    ): Boolean = expected.keys == actual.keys && expected.all { (name, bytes) -> bytes.contentEquals(actual.getValue(name)) }

    private fun readClassDigests(artifact: GeneratedProviderArtifact): Map<String, ByteArray> =
        if (Files.isDirectory(artifact.path)) {
            Files.walk(artifact.path).use { entries ->
                entries
                    .iterator()
                    .asSequence()
                    .filter { path -> Files.isRegularFile(path) && path.fileName.toString().endsWith(".class") }
                    .associate { path ->
                        artifact.path
                            .relativize(path)
                            .toString()
                            .replace('\\', '/') to sha256(Files.readAllBytes(path))
                    }
            }
        } else {
            JarFile(artifact.path.toFile()).use { archive ->
                archive
                    .entries()
                    .asSequence()
                    .filter { entry -> !entry.isDirectory && entry.name.endsWith(".class") }
                    .associate { entry -> entry.name to archive.getInputStream(entry).use { sha256(it.readBytes()) } }
            }
        }

    private fun conflictingClasses(
        expected: Map<String, ByteArray>,
        actual: Map<String, ByteArray>,
    ): List<String> =
        expected.keys
            .intersect(actual.keys)
            .filter { name -> !expected.getValue(name).contentEquals(actual.getValue(name)) }

    private fun sha256(bytes: ByteArray): ByteArray = MessageDigest.getInstance("SHA-256").digest(bytes)

    private fun origin(
        artifact: GeneratedProviderArtifact,
        entry: GeneratedProviderIndexEntry,
    ): ProviderOrigin {
        val key =
            ContributionKey(
                source = artifact.source,
                sourcePart = entry.sourcePart,
                producer = GENERATED_PROVIDER_PRODUCER,
                name = ContributionName(entry.providerClass.replace('$', '_')),
            )
        return ProviderOrigin(
            owner = DeclarationOwner(key, entry.providerClass),
            artifact = artifact.artifact,
            sourcePart = entry.sourcePart,
        )
    }

    private fun assemble(
        loaded: List<LoadedProvider>,
        capabilityOwners: CapabilityOwnerResolver?,
        domain: DiscoveryDomainId,
        instantiator: GeneratedProviderInstantiator,
    ): LoadedGeneratedProviders {
        val declarations = mutableListOf<OwnedTypeDeclaration>()
        val relations = mutableListOf<com.typewritermc.types.RelationContract>()
        val resources = mutableListOf<com.typewritermc.authoring.AuthoringResourceDefinition>()
        val endpointBindings = mutableListOf<com.typewritermc.types.EndpointBindingTemplate>()
        val configurations = mutableListOf<OwnedConfiguration>()
        val presentations = mutableListOf<OwnedPresentation>()
        val nativeBindings = mutableListOf<OwnedNativeBinding>()
        val checks = mutableListOf<Pair<LoadedProvider, GeneratedCheckProvider>>()
        val capabilities = mutableListOf<OwnedRealmCapability>()
        val registrars = mutableListOf<OwnedRuntimeRegistrar>()
        val registrarIds = mutableSetOf<Pair<ContributionSourceId, String>>()
        val collectionProjections = mutableListOf<OwnedCollectionProjection>()

        loaded.forEach { loadedProvider ->
            val origin = loadedProvider.origin
            when (loadedProvider.entry.kind) {
                GeneratedProviderKind.Type -> {
                    val provider = loadedProvider.require<GeneratedTypeProvider>()
                    declarations += OwnedTypeDeclaration(origin, provider.definition, provider.display)
                }

                GeneratedProviderKind.NativeBinding -> {
                    nativeBindings += OwnedNativeBinding(origin, loadedProvider.require<NativeBindingFactory>())
                }

                GeneratedProviderKind.Resource -> {
                    resources += loadedProvider.require<GeneratedResourceProvider>().definition
                }

                GeneratedProviderKind.Relation -> {
                    relations += loadedProvider.require<GeneratedRelationProvider>().contract
                }

                GeneratedProviderKind.EndpointBindings -> {
                    endpointBindings +=
                        loadedProvider.require<GeneratedEndpointBindingsProvider>().bindings
                }

                GeneratedProviderKind.Configuration -> {
                    val provider = loadedProvider.require<GeneratedConfigurationProvider>()
                    configurations += OwnedConfiguration(origin, provider.target, provider)
                }

                GeneratedProviderKind.Presentation -> {
                    val provider = loadedProvider.require<GeneratedPresentationProvider>()
                    presentations += OwnedPresentation(origin, provider.descriptor(origin), provider)
                }

                GeneratedProviderKind.Check -> {
                    checks += loadedProvider to loadedProvider.require<GeneratedCheckProvider>()
                }

                GeneratedProviderKind.Capability -> {
                    val factory = loadedProvider.require<GeneratedCapabilityProvider>()
                    capabilities +=
                        OwnedRealmCapability(
                            origin,
                            factory.bind(
                                requireNotNull(capabilityOwners) {
                                    "Capability providers require an owner resolver."
                                },
                            ),
                        )
                }

                GeneratedProviderKind.Registrar -> {
                    val provider = loadedProvider.require<GeneratedRuntimeRegistrarProvider>()
                    if (domain in provider.descriptor.domains) {
                        require(registrarIds.add(origin.owner.source.source to provider.descriptor.id)) {
                            "Duplicate runtime registrar ${provider.descriptor.id} in contribution source ${origin.owner.source.source}."
                        }
                        registrars += OwnedRuntimeRegistrar(origin, provider.descriptor, provider.bind(instantiator))
                    }
                }

                GeneratedProviderKind.CollectionProjection -> {
                    collectionProjections +=
                        OwnedCollectionProjection(
                            origin,
                            loadedProvider.require<GeneratedCollectionProjectionProvider>().specification,
                        )
                }
            }
        }
        val ownedChecks =
            checks.groupBy { it.second.target }.flatMap { (target, providers) ->
                providers.sortedBy { it.first.origin.owner.localIdentity }.mapIndexed { ordinal, (loadedProvider, provider) ->
                    OwnedCheck(loadedProvider.origin, RuleOrigin(target, ordinal), provider)
                }
            }
        return LoadedGeneratedProviders(
            contributions =
                CatalogContributions(
                    declarations = declarations,
                    relations = relations,
                    resources = resources,
                    endpointBindings = endpointBindings,
                    configurations = configurations,
                    presentations = presentations,
                    nativeBindings = nativeBindings,
                    checks = ownedChecks,
                ),
            capabilities = capabilities,
            registrars = registrars,
            collectionProjections = collectionProjections,
        )
    }
}

private class GeneratedProviderClassLoader(
    urls: Array<URL>,
    parent: ClassLoader,
    private val providerClasses: Set<String>,
) : URLClassLoader(urls, parent) {
    override fun loadClass(
        name: String,
        resolve: Boolean,
    ): Class<*> =
        synchronized(getClassLoadingLock(name)) {
            findLoadedClass(name)?.let { return@synchronized it }
            if (name in providerClasses || providerClasses.any { provider -> name.startsWith("$provider\$") }) {
                runCatching { findClass(name) }.getOrNull()?.let { providerClass ->
                    if (resolve) resolveClass(providerClass)
                    return@synchronized providerClass
                }
            }
            super.loadClass(name, resolve)
        }
}

private data class LoadedProvider(
    val entry: GeneratedProviderIndexEntry,
    val origin: ProviderOrigin,
    val instance: Any,
) {
    inline fun <reified T : Any> require(): T =
        requireNotNull(instance as? T) {
            "Generated ${entry.kind.key} provider ${entry.providerClass} must implement ${T::class.qualifiedName}."
        }
}

private data class IndexedProvider(
    val artifact: GeneratedProviderArtifact,
    val entry: GeneratedProviderIndexEntry,
)

private val QUALIFIED_CLASS_PATTERN = Regex("[A-Za-z_$][A-Za-z0-9_$]*(\\.[A-Za-z_$][A-Za-z0-9_$]*)+")
private val SOURCE_PART_PATTERN = Regex("[A-Za-z][A-Za-z0-9_]*")
private val GENERATED_PROVIDER_PRODUCER = ProducerId("sdk")
