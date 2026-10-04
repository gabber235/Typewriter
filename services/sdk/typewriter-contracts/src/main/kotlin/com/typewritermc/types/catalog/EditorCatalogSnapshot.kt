package com.typewritermc.types.catalog

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.InitializationDescriptor
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
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot

data class PublishedType(
    val definition: TypeDefinition,
    val status: DeclarationStatus,
    val effectiveFields: List<EffectiveFieldTemplate>,
    val ancestorTemplates: List<TypeTemplate.Named>,
    val display: TypeDisplay? = null,
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

data class EditorCatalogSnapshot(
    val generation: CatalogGeneration,
    val types: List<PublishedType>,
    val relations: List<RelationContract>,
    val resourceDefinitions: List<AuthoringResourceDefinition>,
    val presentations: List<PresentationDescriptor>,
    val presentationMaterials: List<PresentationMaterial>,
    val configuration: List<ConfigurationRecipe>,
    val diagnostics: List<DeclarationDiagnostic>,
    val initialization: List<InitializationDescriptor>,
    val endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val recommendations: List<TypeRecommendation> = emptyList(),
    val roleFallbacks: List<RoleFallback> = emptyList(),
)

fun EditorCatalogSnapshot.toWire(): EditorCatalogWireSnapshot = SkirTypeCodec.encode(this).getOrThrow()
