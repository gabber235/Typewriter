package com.typewritermc.realm.testing

import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.COMMON_SOURCE_PART
import com.typewritermc.library.Book
import com.typewritermc.operations.OperationDeclaration
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import skirout.editor.v1.type_catalog.CatalogGeneration
import java.nio.file.Path
import kotlin.reflect.KClass

/**
 * What a test Realm loads: the core typewriter artifact, the extension [artifacts], and test only [declarations] and
 * [operations] added with the core artifact's origin before assembly.
 */
data class RealmCatalog(
    val artifacts: List<GeneratedProviderArtifact> = emptyList(),
    val declarations: (CatalogContributions) -> List<OwnedTypeDeclaration> = { emptyList() },
    val operations: (ProviderOrigin) -> List<OperationDeclaration> = { emptyList() },
) {
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
            )
        val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = generation)))
        check(assembly.operations.failures.isEmpty()) { assembly.operations.failures.joinToString { it.cause.stackTraceToString() } }
        return RealmCatalogIncarnation(assembly, deployment)
    }

    companion object {
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
