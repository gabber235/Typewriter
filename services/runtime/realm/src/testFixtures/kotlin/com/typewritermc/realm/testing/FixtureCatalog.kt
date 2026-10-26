package com.typewritermc.realm.testing

import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.authoring.EmptyProviders
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import com.typewritermc.types.NativeBindingFactory
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.TypeDefinition

/** The catalog a [RealmFixture] activates on each start. */
sealed interface FixtureCatalog {
    /** Activates the catalog as generation [generation]. */
    fun activate(generation: String): ActiveCatalog
}

/** An activated catalog: the lease the Realm reads through, and what has to close once the Realm lets it go. */
class ActiveCatalog(
    val lease: AuthoringCatalogLease,
    val owner: AutoCloseable? = null,
)

/**
 * A catalog of hand written [definitions] and [relations], for rules no real catalog reaches: a relation with a
 * restricting delete policy, a set of a scalar, a link whose endpoint is a type parameter. Use `definitions {}` to
 * write them; content of real types belongs in a [RealmCatalog] with setups.
 */
data class DefinitionCatalog(
    val definitions: List<TypeDefinition>,
    val relations: List<RelationContract> = emptyList(),
    val providers: OwnedProviderRegistry = EmptyProviders,
    val checks: List<OwnedCheckRecipe> = emptyList(),
    val configuration: List<ConfigurationRecipe> = emptyList(),
    val nativeBindingFactories: List<NativeBindingFactory> = emptyList(),
) : FixtureCatalog {
    override fun activate(generation: String): ActiveCatalog = ActiveCatalog(lease(CatalogGeneration(value = generation)))

    /** A lease on this catalog as [generation], for tests that drive a view store directly. */
    fun lease(generation: CatalogGeneration = CatalogGeneration(value = "catalog")): AuthoringCatalogLease =
        TestCatalogLease(generation, providers, checks, configuration, definitions, nativeBindingFactories, relations)
}
