package com.typewritermc.realm.catalog

import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.ResourceDisplayCatalog
import com.typewritermc.discovery.OwnedCheckRecipe
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.formula.ContentReferences
import com.typewritermc.operations.OperationCatalog
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.ownsResources
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath

/**
 * Retains every executable catalog service used by one immutable authoring view.
 *
 * The catalog owner supplies a lease that can be retained independently. Closing a view releases only the
 * retain acquired for that view. Provider callbacks therefore cannot unload while a retained view is
 * still evaluating.
 */
interface AuthoringCatalogLease : AutoCloseable {
    val generation: CatalogGeneration
    val checked: CheckedCatalog
    val nativeBindings: NativeBindingRegistry
    val providers: OwnedProviderRegistry
    val checks: List<OwnedCheckRecipe>
    val relations: List<RelationContract>
    val configuration: List<ConfigurationRecipe>
    val operations: OperationCatalog

    /** The realm root type of this catalog, whose single instance owns every realm section. */
    val realmRoot: TypeDefinitionId
        get() = RealmRootDefinition.id

    /** The published placement field of each declared type that has one; other types are absent. */
    val placementFields: Map<TypeDefinitionId, ValuePath>

    /**
     * What extension code contributes to this code catalog, collected on first read. Every lease of one code catalog
     * answers with the same instance, and it stays open while any lease of the catalog does.
     */
    val extensions: ExtensionCatalog

    /** The resource displays that name resources; a catalog without declared displays names none. */
    val displays: ResourceDisplayCatalog
        get() = ResourceDisplayCatalog()

    /** The code types formulas name by their display name; a catalog that publishes no displays names none. */
    val formulaTypeNames: Map<String, List<TypeUse>>
        get() = emptyMap()

    fun retain(): AuthoringCatalogLease
}

/** Identifies the relations of this catalog that belong to the resource ownership family. */
val AuthoringCatalogLease.ownershipRelationIds: Set<RelationId>
    get() = relations.filter { it.ownsResources }.mapTo(hashSetOf(), RelationContract::id)

/**
 * The relations an author links resources with: every non owning relation except the content references, which say
 * where content names a resource and are read as usages.
 */
val AuthoringCatalogLease.graphLinkRelationIds: Set<RelationId>
    get() = relations.filter { !it.ownsResources && it.id != ContentReferences.id }.mapTo(hashSetOf(), RelationContract::id)
