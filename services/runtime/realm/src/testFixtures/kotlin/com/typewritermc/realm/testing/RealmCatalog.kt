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
import com.typewritermc.library.Book
import com.typewritermc.operations.OperationDeclaration
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.types.qualified
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.nio.file.Path
import kotlin.reflect.KClass

/**
 * What a test Realm loads: the core typewriter artifact, the extension [artifacts], and test only [declarations],
 * [operations], [configurations] and [dynamics] added with the core artifact's origin before assembly, as an
 * extension's own registrations are.
 */
data class RealmCatalog(
    val artifacts: List<GeneratedProviderArtifact> = emptyList(),
    val declarations: (CatalogContributions) -> List<OwnedTypeDeclaration> = { emptyList() },
    val operations: (ProviderOrigin) -> List<OperationDeclaration> = { emptyList() },
    val configurations: (ProviderOrigin) -> List<OwnedConfiguration> = { emptyList() },
    val dynamics: List<DynamicProvider> = emptyList(),
) : FixtureCatalog {
    override fun activate(generation: String): ActiveCatalog {
        val store = RealmCatalogStore().apply { replace(incarnation(generation)) }
        return ActiveCatalog(store.captureCurrent(), store)
    }

    /** The catalog discovery assembles from these artifacts, as Realm activation does. */
    fun incarnation(generation: String): RealmCatalogIncarnation {
        val deployment =
            GeneratedProviderLoader().load(
                listOf(GeneratedProviderArtifact(ArtifactId("typewriter"), Book::class.codeSource())) + artifacts,
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
        /** The engine core artifact, which declares the core pages. */
        val engineCore = GeneratedProviderArtifact(ArtifactId("engine-core"), StaticPage::class.codeSource())

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
