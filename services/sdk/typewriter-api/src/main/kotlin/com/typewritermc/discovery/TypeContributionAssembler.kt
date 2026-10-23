@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.PlacementDefinition
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.capability.id
import com.typewritermc.configuration.PortableConstantEncoder
import com.typewritermc.configuration.bindNative
import com.typewritermc.configuration.field
import com.typewritermc.configuration.name
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.PresentationTyping
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.isReady
import com.typewritermc.types.catalog.of
import com.typewritermc.types.entries
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableMapCopy
import com.typewritermc.types.ownsResources
import com.typewritermc.types.substitute
import com.typewritermc.types.template
import com.typewritermc.types.toWire
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.EffectiveFieldTemplate
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RoleFallback
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValuePath

/**
 * One contributed type declaration. Codegen supplies the complete [display] of every declared type and the
 * [searchKey] of every resource type; a declaration without a display publishes one derived from its type id.
 */
data class OwnedTypeDeclaration(
    val origin: ProviderOrigin,
    val definition: TypeDefinition,
    val display: TypeDisplay? = null,
    val nativeClass: kotlin.reflect.KClass<*>? = null,
    val searchKey: String? = null,
)

data class CatalogAssemblyContext(
    val generation: CatalogGeneration,
    val relations: List<RelationContract> = emptyList(),
    val endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    val capabilities: List<CapabilityDefinition> = emptyList(),
    val roleFallbacks: List<RoleFallback> = DEFAULT_ROLE_FALLBACKS,
)

val DEFAULT_ROLE_FALLBACKS: List<RoleFallback> =
    listOf(
        RoleFallback(role = PresentationRole.REFERENCE_PICKER_RESULT, parents = listOf(PresentationRole.REFERENCE_PREVIEW)),
    )

/**
 * One assembled catalog generation: the [editorCatalog] published to editors, the [checked] catalog and native
 * bindings it was built from, and the runtime facts the Realm and engines read beside it. [placementFields] maps each
 * type with a placement field to its path.
 */
data class CatalogAssembly(
    val editorCatalog: EditorCatalog,
    val checked: CheckedCatalog,
    val bindings: com.typewritermc.types.NativeBindingRegistry,
    val providers: OwnedProviderRegistry,
    val checks: List<OwnedCheckRecipe>,
    val placementFields: Map<TypeDefinitionId, ValuePath> = emptyMap(),
    val operations: com.typewritermc.operations.OperationCatalog = com.typewritermc.operations.OperationCatalog(),
    val callbackFailures: List<CatalogCallbackFailure> = emptyList(),
    val displays: com.typewritermc.authoring.ResourceDisplayCatalog = com.typewritermc.authoring.ResourceDisplayCatalog(),
) {
    /** The published relations. */
    val relations: List<RelationContract> get() = editorCatalog.relations

    /** The published endpoint bindings. */
    val endpointBindings: List<EndpointBindingTemplate> get() = editorCatalog.endpointBindings

    /** The published configuration recipes. */
    val configuration: List<ConfigurationRecipe> get() = editorCatalog.configuration
}

/** Identifies the authored callback whose runtime cause is retained by an assembly. */
sealed interface CatalogCallback {
    data class Configuration(
        val target: TypeDefinitionId,
    ) : CatalogCallback

    data class Presentation(
        val subject: TypeTemplate,
        val role: PresentationRole,
    ) : CatalogCallback

    data class Display(
        val target: skirout.editor.v1.type_catalog.ResourceTarget,
    ) : CatalogCallback
}

/** Runtime evidence for the Realm owner. Causes never enter the portable catalog. */
data class CatalogCallbackFailure(
    val origin: ProviderOrigin,
    val callback: CatalogCallback,
    val cause: Throwable,
)

/**
 * Builds one catalog generation's published editor model and executable SDK services from owned contributions.
 *
 * A structural catalog first supplies schemas for collecting configuration and presentation recipes. Declaration
 * failures then quarantine affected types and required dependents before final native bindings and operations are
 * assembled. Unavailable declarations remain visible with diagnostics in the published catalog.
 * Provider callbacks remain in the returned registry rather than the portable catalog; the caller must retain
 * their deployment separately when catalog consumers outlive deployment replacement.
 */
fun CatalogContributions.assemble(context: CatalogAssemblyContext): CatalogAssembly {
    val standardDeclarations = StandardTypes.definitions.map { OwnedTypeDeclaration(STANDARD_TYPE_ORIGIN, it) }
    val assembledDeclarations = standardDeclarations + declarations
    val definitions = assembledDeclarations.map(OwnedTypeDeclaration::definition)
    val declarationGroups = assembledDeclarations.groupBy { it.definition.id }
    val definitionIndex = declarationGroups.mapNotNull { (id, owned) -> owned.singleOrNull()?.definition?.let { id to it } }.toMap()
    val duplicateDiagnostics =
        declarationGroups.filterValues { it.size > 1 }.map { (id, owned) ->
            DeclarationDiagnostic.of(
                affected = id,
                code = "duplicate_definition",
                origins = owned.map { DeclarationOrigin(owner = it.origin.owner) },
            )
        }
    val reservedDeclarations =
        assembledDeclarations.filter {
            (it.definition.id.typeId as? TypeId.QualifiedWrapper)?.value?.namespace ==
                com.typewritermc.expression.CANONICAL_READ_NAMESPACE ||
                OpaqueParameters.isReserved(it.definition.id)
        }
    val reservedDiagnostics =
        reservedDeclarations.map { owned ->
            DeclarationDiagnostic.of(
                affected = owned.definition.id,
                code = "reserved_intrinsic_type_identity",
                origins = listOf(DeclarationOrigin(owner = owned.origin.owner)),
            )
        }
    val symbolicDiagnostics =
        definitionIndex.values.flatMap { definition -> definition.templateFields(definitionIndex).diagnostics }
    val providerRegistry = ImmutableOwnedProviderRegistry(configurations, presentations, nativeBindings, checks)
    val structural = DefaultCheckedCatalog(context.generation, definitions, quarantine = reservedDiagnostics)
    val resourceTypes = assembledDeclarations.filter { it.searchKey != null }.mapTo(linkedSetOf()) { it.definition.id }
    val publishedRelations = (relations + context.relations).distinctBy(RelationContract::id)
    val structureDiagnostics = realmStructureDiagnostics(assembledDeclarations, resourceTypes, publishedRelations, structural)
    val structuralBindings =
        com.typewritermc.types.FactoryNativeBindingRegistry(structural, nativeBindings.map(OwnedNativeBinding::factory))
    val constants = PortableConstantEncoder { expected, value -> encodeConstant(expected, value, structural, structuralBindings) }
    val collectionResults = configurations.map { collectConfiguration(it, constants) }
    val collectedCandidates = collectionResults.filterIsInstance<ConfigurationCollectionResult.Collected>().map { it.value }
    val configurationFailures = collectionResults.filterIsInstance<ConfigurationCollectionResult.Failed>()
    val ruleDiagnostics = configurationRuleDiagnostics(collectedCandidates, definitionIndex, structural)
    val opaqueParameters = OpaqueParameters(definitionIndex.values)
    // Presentation expressions and resource displays of generic types check against opaque stand ins of free parameters.
    val presentationCatalog =
        DefaultCheckedCatalog(context.generation, definitions + opaqueParameters.definitions, quarantine = reservedDiagnostics)
    val presentationTyping = PresentationTyping(presentationCatalog::resolve, opaqueParameters)
    val materialCollection =
        collectPresentationMaterials(
            presentations,
            assembledDeclarations,
            nativeBindings,
            definitionIndex,
            structural,
            presentationTyping,
            resourceTypes,
            publishedRelations.ownershipEndpoints(),
        )
    val directFailures =
        configurationFailures.map { it.diagnostic } +
            duplicateDiagnostics + reservedDiagnostics + symbolicDiagnostics + ruleDiagnostics +
            materialCollection.failures + structureDiagnostics
    val checked = DefaultCheckedCatalog(context.generation, definitions, quarantine = directFailures)
    val bindingRegistry =
        com.typewritermc.types.FactoryNativeBindingRegistry(checked, nativeBindings.map(OwnedNativeBinding::factory))
    val collected = collectedCandidates.filter { checked.isReady(it.owned.target) }
    val recipes = collected.flatMap { it.configuration.recipes }
    val simpleChecks =
        collected.flatMap { result ->
            result.configuration.checks.map { OwnedCheckRecipe(result.owned.origin, it.bindNative(bindingRegistry)) }
        }
    val diagnostics = declarationGroups.keys.flatMap { checked.definition(it).diagnostics() }
    val searchKeys = declarationGroups.mapNotNull { (id, owned) -> owned.first().searchKey?.let { id to it } }.toMap()
    // Every resource is inside the realm root and its sections, so they scope no search and publish no keyword.
    val scopeKeys = searchKeys.filterKeys { id -> !checked.isRealmStructure(id) }
    val searchKeyConflicts =
        publishedRelations
            .ownerTypes()
            .filter { it in scopeKeys }
            .groupBy(scopeKeys::getValue)
            .filterValues { it.size > 1 }
    val searchKeyDiagnostics =
        searchKeyConflicts.values.flatten().sortedBy { it.canonicalText }.map { id ->
            DeclarationDiagnostic.of(
                id,
                "duplicate_search_key",
                declarationGroups.getValue(id).map { DeclarationOrigin(owner = it.origin.owner) },
            )
        }
    val conflictingKeys = searchKeyConflicts.values.flatten().toSet()
    val displayCollection =
        collectResourceDisplays(displays, definitionIndex, searchKeys.keys.sortedBy { it.canonicalText }, checked, presentationTyping)
    val placementDiagnostics = mutableListOf<DeclarationDiagnostic>()
    val placementFields = linkedMapOf<TypeDefinitionId, ValuePath>()
    val published =
        declarationGroups.entries.sortedBy { it.key.canonicalText }.map { (id, owned) ->
            val definition = owned.first().definition
            val status = checked.definition(id)
            val ready = status == DeclarationStatus.READY
            val ancestry = if (ready) definition.transitiveAncestors(definitionIndex) else emptyList()
            val effectiveFields = if (ready) definition.effectiveFields(definitionIndex, recipes) else emptyList()
            val placementField =
                effectiveFields.placementField(checked) {
                    placementDiagnostics +=
                        DeclarationDiagnostic.of(
                            id,
                            "ambiguous_placement_field",
                            owned.map { DeclarationOrigin(owner = it.origin.owner) }.distinct(),
                        )
                }
            placementField?.let { placementFields[id] = it }
            PublishedType(
                definition = definition,
                status = status,
                effectiveFields = effectiveFields,
                ancestorTemplates = ancestry,
                display = (owned.first().display ?: id.derivedDisplay()).toWire(),
                searchKey = scopeKeys[id]?.takeUnless { id in conflictingKeys },
                placementField = placementField,
            )
        }
    val publishedPresentations =
        presentations.filter { owned ->
            when (val target = owned.descriptor.target) {
                is PresentationTarget.NamedWrapper -> checked.isReady(target.value)
                is PresentationTarget.RepresentationWrapper -> true
                else -> unknownVariant(target)
            }
        }
    val boundOperations =
        com.typewritermc.operations.bindOperations(
            operations,
            checked,
            bindingRegistry,
            publishedPresentations,
        )
    val publishedBindings = (endpointBindings + context.endpointBindings).distinct()
    val editorCatalog =
        EditorCatalog(
            generation = context.generation,
            types = published,
            relations = publishedRelations,
            resourceDisplays = displayCollection.displays.map { it.formulas },
            presentations = publishedPresentations.map { it.descriptor },
            presentationMaterials =
                materialCollection.materials
                    .filter { collected ->
                        checked.isReady(collected.subject) &&
                            when (val target = collected.target) {
                                is PresentationTarget.NamedWrapper -> checked.isReady(target.value)
                                is PresentationTarget.RepresentationWrapper -> true
                                else -> unknownVariant(target)
                            }
                    }.map(CollectedPresentationMaterial::material),
            configuration = recipes,
            diagnostics =
                diagnostics + placementDiagnostics + boundOperations.diagnostics + searchKeyDiagnostics + displayCollection.diagnostics +
                    materialCollection.rejected,
            endpointBindings = publishedBindings,
            capabilities =
                (context.capabilities + boundOperations.capabilities)
                    .sortedBy { it.id.value },
            recommendations = typeRecommendations(definitionIndex, checked),
            roleFallbacks = context.roleFallbacks,
            resourceOperations = boundOperations.definitions,
            realmRoot = RealmRootDefinition.id,
        )
    return CatalogAssembly(
        editorCatalog,
        checked,
        bindingRegistry,
        providerRegistry,
        simpleChecks,
        placementFields = placementFields.immutableMapCopy(),
        operations = boundOperations,
        callbackFailures =
            (configurationFailures.map { it.evidence } + materialCollection.callbackFailures + displayCollection.callbackFailures)
                .immutableListCopy(),
        displays = com.typewritermc.authoring.ResourceDisplayCatalog(displayCollection.displays, published),
    )
}

/**
 * Structural rules that keep every resource reachable from the realm root. A realm section type must be concrete
 * without type parameters (generic_realm_section), because the realm creates its single instance; every other
 * concrete resource type except the root must be the member endpoint of an ownership relation
 * (unowned_resource_type), so each of its resources has an owner.
 */
private fun realmStructureDiagnostics(
    declarations: List<OwnedTypeDeclaration>,
    resourceTypes: Set<TypeDefinitionId>,
    relations: List<RelationContract>,
    catalog: CheckedCatalog,
): List<DeclarationDiagnostic> {
    val members = relations.filter { it.ownsResources }.map { it.second.resource.definition }
    return declarations
        .filter {
            it.definition.id in resourceTypes &&
                (it.definition.representation as? RepresentationTemplate.RecordWrapper)?.value?.abstract_ == false
        }.mapNotNull { owned ->
            val id = owned.definition.id
            val origins = listOf(DeclarationOrigin(owner = owned.origin.owner))
            when {
                id == RealmRootDefinition.id -> {
                    null
                }

                catalog.isNominalSubtype(id, RealmSectionDefinition.id) && owned.definition.parameters.isNotEmpty() -> {
                    DeclarationDiagnostic.of(id, "generic_realm_section", origins)
                }

                members.none { member -> catalog.isNominalSubtype(id, member) } -> {
                    DeclarationDiagnostic.of(id, "unowned_resource_type", origins)
                }

                else -> {
                    null
                }
            }
        }
}

/** The owner side endpoints of ownership relations: the link fields that hold owned resources. */
private fun List<RelationContract>.ownershipEndpoints(): Set<EndpointId> = filter { it.ownsResources }.mapTo(linkedSetOf()) { it.first.id }

/** The owner endpoint types of ownership relations: the first endpoint, which holds the owned resources. */
private fun List<RelationContract>.ownerTypes(): Set<TypeDefinitionId> =
    filter { it.ownsResources }.mapTo(linkedSetOf()) { it.first.resource.definition }

/** Whether [id] is the realm root or a realm section type, which the realm creates and every resource sits inside. */
private fun CheckedCatalog.isRealmStructure(id: TypeDefinitionId): Boolean =
    id == RealmRootDefinition.id || isNominalSubtype(id, RealmRootDefinition.id) || isNominalSubtype(id, RealmSectionDefinition.id)

/** The display of a declaration codegen did not supply one for: its name from the type id, default icon and color. */
private fun TypeDefinitionId.derivedDisplay(): TypeDisplay =
    TypeDisplay(
        name =
            when (val id = typeId) {
                is TypeId.QualifiedWrapper -> id.value.name.substringAfterLast('.')
                is TypeId.DeclaredWrapper -> "Type"
                else -> unknownVariant(id)
            },
        description = "",
        icon = TypeDisplay.DEFAULT_ICON,
        color = TypeDisplay.DEFAULT_COLOR,
    )

/**
 * The single effective field typed as a [com.typewritermc.authoring.Placement], or null when there is none.
 *
 * Fields typed as a placement subtype count, so a sealed placement base and a concrete placement are found alike.
 * More than one candidate is ambiguous: [onAmbiguous] reports it and no field is published.
 */
private fun List<EffectiveFieldTemplate>.placementField(
    checked: CheckedCatalog,
    onAmbiguous: () -> Unit,
): ValuePath? {
    val fields = filter { field -> field.type.isPlacement(checked) }
    if (fields.size > 1) onAmbiguous()
    return fields.singleOrNull()?.let { field -> ValuePath.root.field(field.key) }
}

private fun TypeTemplate.isPlacement(checked: CheckedCatalog): Boolean =
    this is TypeTemplate.NamedWrapper && checked.isNominalSubtype(value.definition, PlacementDefinition.id)

internal fun TypeDefinition.templateAt(
    path: RelativeFieldPattern,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): TypeTemplate? {
    var current: TypeTemplate = id.template(parameters.map { it.key.template })
    path.segments.forEach { segment ->
        current = current.unwrapNullable()
        current =
            when (segment) {
                is FieldPatternSegment.FieldWrapper -> {
                    current.field(segment.name, definitions)
                }

                FieldPatternSegment.ITEMS -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.SequenceWrapper)?.value?.item?.substitute(arguments)
                    }
                }

                FieldPatternSegment.KEYS -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.key?.substitute(arguments)
                    }
                }

                FieldPatternSegment.VALUES -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.value?.substitute(arguments)
                    }
                }

                else -> {
                    unknownVariant(segment)
                }
            } ?: return null
    }
    return current
}

internal fun TypeTemplate.unwrapNullable(): TypeTemplate = if (this is TypeTemplate.NullableWrapper) value.value else this

internal fun TypeTemplate.field(
    name: String,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): TypeTemplate? {
    val named = this as? TypeTemplate.NamedWrapper ?: return null
    val definition = definitions[named.value.definition] ?: return null
    val arguments =
        definition.parameters
            .map(TypeParameter::key)
            .zip(named.value.arguments)
            .toMap()
    return definition
        .templateFields(definitions)
        .fields
        .singleOrNull { it.owner.name == name }
        ?.type
        ?.substitute(arguments)
}

internal fun TypeTemplate.representation(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): Pair<RepresentationTemplate, Map<ParameterKey, TypeTemplate>>? {
    val named = this as? TypeTemplate.NamedWrapper ?: return null
    val definition = definitions[named.value.definition] ?: return null
    return definition.representation to
        definition.parameters
            .map(TypeParameter::key)
            .zip(named.value.arguments)
            .toMap()
}

private val STANDARD_TYPE_ORIGIN =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    contributionKey(
                        source = ContributionSourceId("typewritermc:core"),
                        sourcePart = "main",
                        producer = ProducerId("sdk"),
                        name = ContributionName("standard_types"),
                    ),
                localIdentity = "StandardTypes",
            ),
        artifact = ArtifactId("typewritermc:core"),
        sourcePart = "main",
    )
