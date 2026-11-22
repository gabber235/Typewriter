package com.typewritermc.realm.testing

import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedDynamic
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.engine.pages.StaticPage
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.COMMON_SOURCE_PART
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.library.Book
import com.typewritermc.operations.OperationDeclaration
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogLease
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.types.qualified
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.net.URI
import java.net.URL
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.zip.ZipFile
import kotlin.reflect.KClass

/**
 * What a test Realm loads: the [realm] artifacts it loads itself, the extension [artifacts], and test only
 * [declarations], [operations], [configurations] and [dynamics] added with the first loaded declaration's origin before
 * assembly, as an extension's own registrations are.
 */
data class RealmCatalog(
    val realm: List<GeneratedProviderArtifact> = listOf(typewriterApi),
    val artifacts: List<GeneratedProviderArtifact> = emptyList(),
    val declarations: (CatalogContributions) -> List<OwnedTypeDeclaration> = { emptyList() },
    val operations: (ProviderOrigin) -> List<OperationDeclaration> = { emptyList() },
    val configurations: (ProviderOrigin) -> List<OwnedConfiguration> = { emptyList() },
    val dynamics: List<DynamicProvider> = emptyList(),
) : FixtureCatalog {
    override fun activate(generation: String): ActiveCatalog {
        val store = RealmCatalogStore().apply { replace(incarnation(generation)) }
        return ActiveCatalog(CountedCatalogLease(store.captureCurrent(), AtomicInteger(1)), store)
    }

    /** The catalog discovery assembles from these artifacts, as Realm activation does. */
    fun incarnation(generation: String): RealmCatalogIncarnation {
        val deployment =
            GeneratedProviderLoader().load(
                realm + artifacts,
                DeploymentFacts(),
                DiscoveryDomains.Realm,
                runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
            )
        val loaded = deployment.providers.contributions
        val origin = loaded.declarations.first().origin
        val contributions =
            loaded.copy(
                declarations = loaded.declarations + declarations(loaded),
                operations = loaded.operations + operations(origin),
                configurations = loaded.configurations + configurations(origin),
                dynamics =
                    loaded.dynamics +
                        dynamics.mapIndexed { index, provider ->
                            OwnedDynamic(
                                origin,
                                RuleOrigin(owner = TypeDefinitionId.qualified("test-dynamic", "provider-$index"), ordinal = 0),
                                provider,
                            )
                        },
            )
        val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = generation)))
        check(assembly.operations.failures.isEmpty()) { assembly.operations.failures.joinToString { it.cause.stackTraceToString() } }
        return RealmCatalogIncarnation(assembly, deployment)
    }

    companion object {
        /** The typewriter API artifact, which declares the core types. */
        val typewriterApi = GeneratedProviderArtifact(ArtifactId("typewriter"), Book::class.ownArtifact())

        /** The engine core artifact, which declares the core pages. */
        val engineCore = GeneratedProviderArtifact(ArtifactId("engine-core"), StaticPage::class.ownArtifact())

        /** The extension artifact [id] whose classes include [type], loaded the way Realm loads extensions. */
        fun extension(
            id: String,
            type: KClass<*>,
        ) = GeneratedProviderArtifact(ArtifactId(id), type.codeSource(), acceptedSourceParts = setOf(COMMON_SOURCE_PART))
    }
}

private fun KClass<*>.codeSource(): Path =
    Path.of(
        java.protectionDomain.codeSource.location
            .toURI(),
    )

/**
 * The classpath entry of the project that declares this class. A hosted artifact on the classpath bundles the class too
 * and may come first, so the entry is the one without an Imprint manifest, never whichever the class loader picked.
 */
private fun KClass<*>.ownArtifact(): Path {
    val resource = java.name.replace('.', '/') + ".class"
    val entries =
        java.classLoader
            .getResources(resource)
            .toList()
            .map { it.classpathEntry(resource) }
            .distinct()
    return entries.singleOrNull { !it.holds(IMPRINT_MANIFEST_PATH) }
        ?: error("$resource must come from exactly one classpath entry without an Imprint manifest, not from $entries")
}

private fun URL.classpathEntry(resource: String): Path =
    when (protocol) {
        "jar" -> Path.of(URI(path.substringBefore("!/")))
        "file" -> generateSequence(Path.of(toURI())) { it.parent }.elementAt(resource.split('/').size)
        else -> error("$this is neither a JAR nor a directory entry")
    }

private fun Path.holds(entry: String): Boolean =
    if (Files.isDirectory(this)) {
        Files.exists(resolve(entry))
    } else {
        ZipFile(toFile()).use { it.getEntry(entry) != null }
    }

/** A lease on a Realm's catalog that counts how many of its retains are still open, so a test can see one leak. */
internal class CountedCatalogLease(
    private val delegate: RealmCatalogLease,
    private val open: AtomicInteger,
) : RealmCatalogLease by delegate {
    private val closed = AtomicBoolean(false)

    /** How many leases of this catalog are open now. */
    val openCount: Int get() = open.get()

    override fun retain(): RealmCatalogLease = CountedCatalogLease(delegate.retain() as RealmCatalogLease, open.apply { incrementAndGet() })

    override fun close() {
        if (closed.compareAndSet(false, true)) open.decrementAndGet()
        delegate.close()
    }
}
