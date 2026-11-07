package com.typewritermc.realm.testing

import com.typewritermc.authoring.requireValid
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.realm.authoring.EmptyProviders
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.catalog.AuthoringCatalogLease
import com.typewritermc.realm.catalog.code
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.of
import com.typewritermc.types.requireValid
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.RelationId
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

/**
 * A one to one relation [id] whose endpoints [first] and [second] each hold one link and clear it when the resource on
 * the other side is deleted. [firstResource] and [secondResource] type the resources on each side.
 */
fun oneToOneRelation(
    id: String,
    first: EndpointId,
    second: EndpointId,
    firstResource: NamedTypeTemplate,
    secondResource: NamedTypeTemplate = firstResource,
): RelationContract =
    RelationContract.of(
        RelationId(value = id),
        EndpointDefinition(
            id = first,
            slot = EndpointSlot.FIRST,
            resource = firstResource,
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
        EndpointDefinition(
            id = second,
            slot = EndpointSlot.SECOND,
            resource = secondResource,
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
    )

/** The captured panel creation fixture [name] from the test resources, which `cargo xtask generate` writes from the panel. */
fun panelCreationFixture(name: String): ByteArray =
    requireNotNull(TestCatalogLease::class.java.getResourceAsStream("/creation/$name")) {
        "Missing panel creation fixture $name; `cargo xtask generate` writes it from the panel " +
            "(generator creation-fixtures)."
    }.use { it.readBytes() }

/** The captured panel catalog [snapshot]: a Library owning Books that own pages, each linking back to its owner. */
fun panelCreationCatalog(snapshot: EditorCatalog) =
    DefinitionCatalog(
        definitions = snapshot.types.map { it.definition.requireValid() },
        relations =
            snapshot.relations.map { relation ->
                RelationContract.of(
                    relation.id,
                    endpoint(relation.first),
                    endpoint(relation.second),
                    relation.families.toSet(),
                )
            },
    )

private fun endpoint(endpoint: EndpointDefinition): EndpointDefinition =
    EndpointDefinition(
        id = endpoint.id.requireValid(),
        slot =
            when (endpoint.slot) {
                skirout.editor.v1.catalog.EndpointSlot.FIRST -> EndpointSlot.FIRST
                skirout.editor.v1.catalog.EndpointSlot.SECOND -> EndpointSlot.SECOND
                else -> error("Unknown captured endpoint slot")
            },
        resource = endpoint.resource.requireValid(),
        cardinality =
            when (endpoint.cardinality) {
                skirout.editor.v1.catalog.EndpointCardinality.ONE -> EndpointCardinality.ONE
                skirout.editor.v1.catalog.EndpointCardinality.MANY -> EndpointCardinality.MANY
                else -> error("Unknown captured endpoint cardinality")
            },
        onDelete =
            when (endpoint.onDelete) {
                skirout.editor.v1.catalog.RelationDeletePolicy.RESTRICT -> RelationDeletePolicy.RESTRICT
                skirout.editor.v1.catalog.RelationDeletePolicy.CASCADE -> RelationDeletePolicy.CASCADE
                skirout.editor.v1.catalog.RelationDeletePolicy.CLEAR -> RelationDeletePolicy.CLEAR
                else -> error("Unknown captured deletion policy")
            },
    )

/**
 * Counts the leases still open on the catalog this Realm runs now; the count stays readable after the Realm is closed,
 * so a test can prove that closing released every lease.
 */
internal fun RealmFixture.openCatalogLeases(): () -> Int =
    when (val lease = views.read { it.catalog.code }) {
        is TestCatalogLease -> {
            { lease.openCount }
        }

        is CountedCatalogLease -> {
            { lease.openCount }
        }

        else -> {
            error("The catalog lease ${lease::class.simpleName} counts no leases.")
        }
    }
