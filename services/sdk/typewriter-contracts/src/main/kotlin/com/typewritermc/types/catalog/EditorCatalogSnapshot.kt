package com.typewritermc.types.catalog

import com.typewritermc.authoring.ValuePath
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.RuleId
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.RelationContract
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot
import skirout.editor.v1.expression.ExpressionNode

/**
 * One declared type as published to editors.
 *
 * [searchKey] is the search scope keyword of a resource type. It is null for every type that is not a resource and for
 * the realm root and its sections, which every resource sits inside.
 * [placementField] is the single effective field typed as a placement; editors and Realm read and write layout
 * through it instead of assuming a field name. It is null when the type has no placement field.
 */
data class PublishedType(
    val definition: TypeDefinition,
    val status: DeclarationStatus,
    val effectiveFields: List<EffectiveFieldTemplate>,
    val ancestorTemplates: List<TypeTemplate.Named>,
    val display: TypeDisplay,
    val searchKey: String? = null,
    val placementField: ValuePath? = null,
)

/**
 * Compiled name, accent and icon formulas of one declared resource display. Each formula reads only the subject
 * resource through the configured value binding; editors evaluate the most specific formulas for a resource.
 */
data class ResourceDisplayFormulas(
    val target: ResourceTarget,
    val label: ExpressionNode,
    val accent: ExpressionNode,
    val icon: ExpressionNode,
)

data class EffectiveFieldTemplate(
    val key: String,
    val owner: FieldOwner,
    val type: TypeTemplate,
    val rules: List<RuleId>,
)

data class TypeRecommendation(
    val type: TypeUse.Named,
    val occurrences: Long,
)

/**
 * Publishes a generation's declarative authoring model to editor clients without executable provider callbacks.
 * Includes unavailable type entries and diagnostics so consumers can explain missing capabilities as well as render
 * valid definitions. Presentation materials and operation definitions travel with the same generation's schema.
 */
data class EditorCatalogSnapshot(
    val generation: CatalogGeneration,
    val types: List<PublishedType>,
    val relations: List<RelationContract>,
    val resourceDisplays: List<ResourceDisplayFormulas>,
    val presentations: List<PresentationDescriptor>,
    val presentationMaterials: List<PresentationMaterial>,
    val configuration: List<ConfigurationRecipe>,
    val diagnostics: List<DeclarationDiagnostic>,
    val endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val recommendations: List<TypeRecommendation> = emptyList(),
    val roleFallbacks: List<RoleFallback> = emptyList(),
    val resourceOperations: List<com.typewritermc.operations.ResourceOperationDefinition> = emptyList(),
    /** The realm root type. The realm keeps exactly one instance of it, which owns every section. */
    val realmRoot: TypeDefinitionId,
)

fun EditorCatalogSnapshot.toWire(): EditorCatalogWireSnapshot = SkirTypeCodec.encode(this).getOrThrow()
