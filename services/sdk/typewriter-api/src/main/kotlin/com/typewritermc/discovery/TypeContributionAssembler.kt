@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.PlacementDefinition
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.field
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.configuration.ConfigurationRecipe
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.DefaultPortableRuleCompiler
import com.typewritermc.configuration.DefaultPredicateReasoner
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.PortableConstantEncoder
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.configuration.bindNative
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.CheckedPresentationTemplate
import com.typewritermc.presentation.NestedPresentationSlot
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationNestedTemplate
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.presentation.inferInheritableNodes
import com.typewritermc.presentation.selectMostSpecificDescriptors
import com.typewritermc.presentation.validateInheritableNodes
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.RelationContract
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationOrigin
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.isReady
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.endpoint
import com.typewritermc.types.entries
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.floatScalar
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.immutableMapCopy
import com.typewritermc.types.integerScalar
import com.typewritermc.types.isValid
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.ownsResources
import com.typewritermc.types.parameterKeys
import com.typewritermc.types.portableOrNull
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.substitute
import com.typewritermc.types.template
import com.typewritermc.types.toWire
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import com.typewritermc.types.validOrNull
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.EffectiveFieldTemplate
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
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
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val roleFallbacks: List<RoleFallback> = DEFAULT_ROLE_FALLBACKS,
)

val DEFAULT_ROLE_FALLBACKS: List<RoleFallback> =
    listOf(
        RoleFallback(PresentationRole.REFERENCE_PICKER_RESULT, listOf(PresentationRole.REFERENCE_PREVIEW)),
    )

/**
 * One assembled catalog generation: the [editorCatalog] published to editors, the [checked] catalog and native
 * bindings it was built from, and the runtime facts the Realm and engines read beside it. [relations],
 * [endpointBindings] and [configuration] are the published relations, endpoint bindings and configuration recipes;
 * [placementFields] maps each type with a placement field to its path.
 */
data class CatalogAssembly(
    val editorCatalog: EditorCatalog,
    val checked: CheckedCatalog,
    val bindings: com.typewritermc.types.NativeBindingRegistry,
    val providers: OwnedProviderRegistry,
    val checks: List<OwnedCheckRecipe>,
    val relations: List<RelationContract> = emptyList(),
    val endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    val configuration: List<ConfigurationRecipe> = emptyList(),
    val placementFields: Map<TypeDefinitionId, ValuePath> = emptyMap(),
    val operations: com.typewritermc.operations.OperationCatalog = com.typewritermc.operations.OperationCatalog(),
    val callbackFailures: List<CatalogCallbackFailure> = emptyList(),
    val displays: com.typewritermc.authoring.ResourceDisplayCatalog = com.typewritermc.authoring.ResourceDisplayCatalog(),
)

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
        val target: com.typewritermc.types.ResourceTarget,
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
            DeclarationDiagnostic(
                affected = id,
                code = "duplicate_definition",
                origins = owned.map { DeclarationOrigin(it.origin.owner) },
            )
        }
    val reservedDeclarations =
        assembledDeclarations.filter {
            (it.definition.id.typeId as? TypeId.QualifiedWrapper)?.value?.namespace ==
                com.typewritermc.expression.CANONICAL_READ_NAMESPACE
        }
    val reservedDiagnostics =
        reservedDeclarations.map { owned ->
            DeclarationDiagnostic(
                affected = owned.definition.id,
                code = "reserved_intrinsic_type_identity",
                origins = listOf(DeclarationOrigin(owned.origin.owner)),
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
    val materialCollection =
        collectPresentationMaterials(
            presentations,
            assembledDeclarations,
            nativeBindings,
            definitionIndex,
            structural,
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
            DeclarationDiagnostic(id, "duplicate_search_key", declarationGroups.getValue(id).map { DeclarationOrigin(it.origin.owner) })
        }
    val conflictingKeys = searchKeyConflicts.values.flatten().toSet()
    val displayCollection = collectResourceDisplays(displays, definitionIndex, searchKeys.keys.sortedBy { it.canonicalText }, checked)
    val placementDiagnostics = mutableListOf<DeclarationDiagnostic>()
    val placementFields = linkedMapOf<TypeDefinitionId, ValuePath>()
    val published =
        declarationGroups.entries.sortedBy { it.key.canonicalText }.map { (id, owned) ->
            val definition = owned.first().definition
            val status = checked.definition(id)
            val ready = status == DeclarationStatus.Ready
            val ancestry = if (ready) definition.transitiveAncestors(definitionIndex) else emptyList()
            val effectiveFields = if (ready) definition.effectiveFields(definitionIndex, recipes) else emptyList()
            val placementField =
                effectiveFields.placementField(checked) {
                    placementDiagnostics +=
                        DeclarationDiagnostic(
                            id,
                            "ambiguous_placement_field",
                            owned.map { DeclarationOrigin(it.origin.owner) }.distinct(),
                        )
                }
            placementField?.let { placementFields[id] = it }
            PublishedType(
                definition = definition,
                status = SkirTypeCodec.encode(status).getOrThrow(),
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
                is PresentationTarget.Named -> checked.isReady(target.type)
                is PresentationTarget.Representation -> true
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
    // The relations, displays, presentations, configuration, diagnostics, bindings, capabilities and fallbacks are
    // still Kotlin catalog models; SkirTypeCodec encodes them into the published catalog.
    val editorCatalog =
        EditorCatalog(
            generation = context.generation,
            types = published,
            relations = publishedRelations.map { SkirTypeCodec.encode(it).getOrThrow() },
            resourceDisplays = displayCollection.displays.map { SkirTypeCodec.encode(it.formulas).getOrThrow() },
            presentations = publishedPresentations.map { SkirTypeCodec.encode(it.descriptor).getOrThrow() },
            presentationMaterials =
                materialCollection.materials
                    .filter { collected ->
                        checked.isReady(collected.subject) &&
                            when (val target = collected.target) {
                                is PresentationTarget.Named -> checked.isReady(target.type)
                                is PresentationTarget.Representation -> true
                            }
                    }.map(CollectedPresentationMaterial::material),
            configuration = recipes.map { SkirTypeCodec.encode(it).getOrThrow() },
            diagnostics =
                (diagnostics + placementDiagnostics + boundOperations.diagnostics + searchKeyDiagnostics + displayCollection.diagnostics)
                    .map { SkirTypeCodec.encode(it).getOrThrow() },
            endpointBindings = publishedBindings.map { SkirTypeCodec.encode(it).getOrThrow() },
            capabilities =
                (context.capabilities + boundOperations.capabilities)
                    .sortedBy { it.id.value }
                    .map { SkirTypeCodec.encode(it).getOrThrow() },
            recommendations = typeRecommendations(definitionIndex, checked),
            roleFallbacks = context.roleFallbacks.map { SkirTypeCodec.encode(it).getOrThrow() },
            resourceOperations = boundOperations.definitions,
            realmRoot = RealmRootDefinition.id,
        )
    return CatalogAssembly(
        editorCatalog,
        checked,
        bindingRegistry,
        providerRegistry,
        simpleChecks,
        relations = publishedRelations.immutableListCopy(RelationContract::immutableCopy),
        endpointBindings = publishedBindings.immutableListCopy(EndpointBindingTemplate::immutableCopy),
        configuration = recipes.immutableListCopy(ConfigurationRecipe::immutableCopy),
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
            val origins = listOf(DeclarationOrigin(owned.origin.owner))
            when {
                id == RealmRootDefinition.id -> {
                    null
                }

                catalog.isNominalSubtype(id, RealmSectionDefinition.id) && owned.definition.parameters.isNotEmpty() -> {
                    DeclarationDiagnostic(id, "generic_realm_section", origins)
                }

                members.none { member -> catalog.isNominalSubtype(id, member) } -> {
                    DeclarationDiagnostic(id, "unowned_resource_type", origins)
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

private data class CollectedOwnedConfiguration(
    val owned: OwnedConfiguration,
    val configuration: com.typewritermc.configuration.CollectedConfiguration,
)

/** One published material with the subject and target whose readiness in the final catalog decides its publication. */
private class CollectedPresentationMaterial(
    val subject: TypeTemplate,
    val target: PresentationTarget,
    val material: PresentationMaterial,
)

private data class PresentationMaterialCollection(
    val materials: List<CollectedPresentationMaterial>,
    val failures: List<DeclarationDiagnostic>,
    val callbackFailures: List<CatalogCallbackFailure>,
)

private fun collectPresentationMaterials(
    presentations: List<OwnedPresentation>,
    declarations: List<OwnedTypeDeclaration>,
    nativeBindings: List<OwnedNativeBinding>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    resourceTypes: Set<TypeDefinitionId>,
    ownershipEndpoints: Set<EndpointId>,
): PresentationMaterialCollection {
    val materials = mutableListOf<CollectedPresentationMaterial>()
    val failures = mutableListOf<DeclarationDiagnostic>()
    val callbackFailures = mutableListOf<CatalogCallbackFailure>()
    val nativeTypes =
        (
            declarations.mapNotNull { owned ->
                val native = owned.nativeClass ?: return@mapNotNull null
                val definition = definitions[owned.definition.id] ?: return@mapNotNull null
                if (catalog.declaration(definition.id) !is Resolution.Ready) return@mapNotNull null
                native to definition.id.namedTemplate(definition.parameters.map { it.key.template })
            } +
                nativeBindings
                    .mapNotNull { owned ->
                        val native = owned.factory.nativeClass ?: return@mapNotNull null
                        val definition = definitions[owned.factory.definition] ?: return@mapNotNull null
                        if (catalog.declaration(definition.id) !is Resolution.Ready) return@mapNotNull null
                        native to definition.id.namedTemplate(definition.parameters.map { it.key.template })
                    }
        ).groupBy(Pair<kotlin.reflect.KClass<*>, NamedTypeTemplate>::first)
            .mapNotNull { (native, declarations) ->
                declarations
                    .map { it.second }
                    .distinct()
                    .singleOrNull()
                    ?.let { native to it }
            }.toMap()
    presentations.forEach { owned ->
        val target = owned.descriptor.target
        val subjects = target.presentationSubjects(definitions)
        if (subjects.isEmpty() && target is PresentationTarget.Named) {
            failures +=
                DeclarationDiagnostic(
                    affected = target.type.definition,
                    code = "invalid_presentation_target",
                    origins = listOf(DeclarationOrigin(owned.descriptor.owner)),
                )
        }
        subjects.forEach { subject ->
            val template = subject.presentationTemplate(definitions, catalog)
            owned.descriptor.roles.sortedBy { it.kind.ordinal }.forEach { role ->
                try {
                    val result = owned.provider.build(PresentationBuildBinding(template, role, nativeTypes, ownershipEndpoints))
                    val inferred = result.layout.inferInheritableNodes(result.dependencies)
                    result.layout.validateInheritableNodes(
                        inferred,
                        result.dependencies,
                        partOwnerCompatible = { key ->
                            val owner = key.owner
                            val actual = (subject as? TypeTemplate.NamedWrapper)?.value?.definition
                            actual != null && definitions[owner]?.representation is RepresentationTemplate.RecordWrapper &&
                                catalog.isNominalSubtype(actual, owner)
                        },
                    ) { field ->
                        subject.field(field, definitions) !=
                            null
                    }
                    if (result.dependencies.validCollections(subject, definitions, catalog, resourceTypes)) {
                        materials +=
                            CollectedPresentationMaterial(
                                subject = subject,
                                target = owned.descriptor.target,
                                material =
                                    PresentationMaterial(
                                        provider = owned.descriptor.id,
                                        target = SkirTypeCodec.encode(owned.descriptor.target).getOrThrow(),
                                        role = role,
                                        layout = result.layout,
                                        dependencies = result.dependencies,
                                        subject = subject,
                                        inheritableNodes = inferred,
                                    ),
                            )
                    } else {
                        val affected = (subject as? TypeTemplate.NamedWrapper)?.value?.definition
                        if (affected != null) {
                            failures +=
                                DeclarationDiagnostic(
                                    affected = affected,
                                    code = "invalid_presentation_collection_dependency",
                                    origins = listOf(DeclarationOrigin(owned.descriptor.owner)),
                                )
                        }
                    }
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (cause: Exception) {
                    callbackFailures +=
                        CatalogCallbackFailure(
                            owned.origin,
                            CatalogCallback.Presentation(subject, role),
                            cause,
                        )
                    val affected = (subject as? TypeTemplate.NamedWrapper)?.value?.definition
                    if (affected != null) {
                        failures +=
                            DeclarationDiagnostic(
                                affected = affected,
                                code = "presentation_material_build_failed",
                                origins = listOf(DeclarationOrigin(owned.descriptor.owner)),
                            )
                    }
                }
            }
        }
    }
    return PresentationMaterialCollection(materials, failures, callbackFailures)
}

private fun skirout.editor.v1.presentation.PresentationDependencies.validCollections(
    subject: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    resourceTypes: Set<TypeDefinitionId>,
): Boolean {
    if (contextInputs.map { it.bindingId }.distinct().size != contextInputs.size) return false
    if (!contextInputs.all { input ->
            input.bindingId.value.startsWith("context:") &&
                input.source.kind != skirout.editor.v1.presentation.PresentationContextSource.Kind.UNKNOWN &&
                input.valueType.isValid &&
                catalog.resolve(input.valueType) is Resolution.Ready
        }
    ) {
        return false
    }
    val parameters = subject.parameterKeys()
    val parameterBounds =
        parameters.associateWith { key ->
            definitions[key.owner]
                ?.parameters
                ?.singleOrNull { it.key == key }
                ?.bounds
                ?: return false
        }
    return collections.all { collection ->
        val rowType = collection.rowType.takeIf { it.isValid } ?: return@all false
        if (!rowType.isValidMaterialTemplate(definitions, parameterBounds, catalog)) return@all false
        collection.projection?.isValid(rowType, definitions, parameterBounds, catalog, resourceTypes) ?: true
    }
}

private fun skirout.editor.v1.presentation.PresentationCollectionProjection.isValid(
    rowType: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    catalog: CheckedCatalog,
    resourceTypes: Set<TypeDefinitionId>,
): Boolean {
    val root = this.root.takeIf { it.isValid } ?: return false
    if (!root.template.isValidMaterialTemplate(definitions, parameterBounds, catalog)) return false
    if (root.definition !in resourceTypes) return false
    return fields.all { field ->
        val targetPath = field.target.validOrNull() ?: return@all false
        val targetType = rowType.templateAt(targetPath, definitions) ?: return@all false
        when (val source = field.source) {
            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.ContentWrapper -> {
                val sourcePath = source.value.validOrNull() ?: return@all false
                val sourceType = root.template.templateAt(sourcePath, definitions) ?: return@all false
                catalog.isTemplateReadableAs(sourceType, targetType, parameterBounds)
            }

            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.LiteralWrapper -> {
                val value = source.value.portableOrNull() ?: return@all false
                targetType.acceptsLiteral(value, parameterBounds.keys, catalog)
            }

            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.Unknown -> {
                false
            }
        }
    }
}

private fun TypeTemplate.isValidMaterialTemplate(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    catalog: CheckedCatalog,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            value in parameterBounds
        }

        is TypeTemplate.NamedWrapper -> {
            val definition = definitions[value.definition]
            definition != null &&
                catalog.definition(this.value.definition) == DeclarationStatus.Ready &&
                value.arguments.size == definition.parameters.size &&
                value.arguments.all { it.isValidMaterialTemplate(definitions, parameterBounds, catalog) } &&
                definition.parameters.zip(value.arguments).all { (parameter, argument) ->
                    val bindings =
                        definition.parameters
                            .map(TypeParameter::key)
                            .zip(value.arguments)
                            .toMap()
                    parameter.bounds.all { bound ->
                        val expected = bound.substitute(bindings)
                        catalog.isTemplateReadableAs(argument, expected, parameterBounds)
                    }
                }
        }

        is TypeTemplate.NullableWrapper -> {
            value.value.isValidMaterialTemplate(definitions, parameterBounds, catalog)
        }

        is TypeTemplate.ScalarWrapper -> {
            true
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.acceptsLiteral(
    value: skirout.editor.v1.type_catalog.DataValue,
    parameters: Set<ParameterKey>,
    catalog: CheckedCatalog,
): Boolean {
    if (value == skirout.editor.v1.type_catalog.DataValue.UNFILLED) return true
    if (parameterKeys().any(parameters::contains)) return false
    val use = (apply(emptyMap()) as? Resolution.Ready)?.value ?: return false
    val checked = (catalog.resolve(use) as? Resolution.Ready)?.value ?: return false
    return checked.complete(value) !is CompletenessResult.Invalid
}

private fun TypeTemplate.templateAt(
    path: ValuePath,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): TypeTemplate? {
    var current = this
    path.segments.forEach { segment ->
        current = current.unwrapNullable()
        current =
            when (segment) {
                is PathSegment.FieldWrapper -> {
                    current.field(segment.name, definitions)
                }

                is PathSegment.ItemWrapper -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.SequenceWrapper)?.value?.item?.substitute(arguments)
                    }
                }

                PathSegment.MAP_KEY -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.key?.substitute(arguments)
                    }
                }

                PathSegment.MAP_VALUE -> {
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

private fun PresentationTarget.presentationSubjects(definitions: Map<TypeDefinitionId, TypeDefinition>): List<TypeTemplate> =
    when (this) {
        is PresentationTarget.Named -> {
            val definition = definitions[type.definition]
            if (definition == null || definition.parameters.size != type.arguments.size) emptyList() else listOf(type.template)
        }

        is PresentationTarget.Representation -> {
            val named =
                definitions.values
                    .filter { it.representation.presentationKind() == kind }
                    .map { definition ->
                        definition.id.template(definition.parameters.map { it.key.template })
                    }
            (named + kind.scalarSubjects()).distinct()
        }
    }

private fun RepresentationKind.scalarSubjects(): List<TypeTemplate> =
    when (this) {
        RepresentationKind.Unit -> {
            listOf(ScalarKind.UNIT.template)
        }

        RepresentationKind.Boolean -> {
            listOf(ScalarKind.BOOLEAN.template)
        }

        RepresentationKind.Text -> {
            listOf(ScalarKind.TEXT.template)
        }

        RepresentationKind.Bytes -> {
            listOf(ScalarKind.BYTES.template)
        }

        RepresentationKind.Integer -> {
            IntegerWidth.entries.map { width ->
                integerScalar(width).template
            }
        }

        RepresentationKind.Float -> {
            FloatWidth.entries.map { width ->
                floatScalar(width).template
            }
        }

        RepresentationKind.Decimal -> {
            listOf(ScalarKind.DECIMAL.template)
        }

        RepresentationKind.Timestamp -> {
            listOf(ScalarKind.TIMESTAMP.template)
        }

        RepresentationKind.Duration -> {
            listOf(ScalarKind.DURATION.template)
        }

        else -> {
            emptyList()
        }
    }

private sealed interface ConfigurationCollectionResult {
    data class Collected(
        val value: CollectedOwnedConfiguration,
    ) : ConfigurationCollectionResult

    data class Failed(
        val diagnostic: DeclarationDiagnostic,
        val evidence: CatalogCallbackFailure,
    ) : ConfigurationCollectionResult
}

private fun RepresentationTemplate.presentationKind(): RepresentationKind =
    when (this) {
        is RepresentationTemplate.ScalarWrapper -> {
            when (val kind = value.kind) {
                ScalarKind.UNIT -> RepresentationKind.Unit
                ScalarKind.BOOLEAN -> RepresentationKind.Boolean
                ScalarKind.TEXT -> RepresentationKind.Text
                ScalarKind.BYTES -> RepresentationKind.Bytes
                is ScalarKind.IntegerWrapper -> RepresentationKind.Integer
                is ScalarKind.FloatWrapper -> RepresentationKind.Float
                ScalarKind.DECIMAL -> RepresentationKind.Decimal
                ScalarKind.TIMESTAMP -> RepresentationKind.Timestamp
                ScalarKind.DURATION -> RepresentationKind.Duration
                else -> unknownVariant(kind)
            }
        }

        is RepresentationTemplate.RecordWrapper -> {
            RepresentationKind.Record
        }

        is RepresentationTemplate.SequenceWrapper -> {
            when (val kind = value.kind) {
                CollectionKind.LIST -> RepresentationKind.List
                CollectionKind.SET -> RepresentationKind.Set
                else -> unknownVariant(kind)
            }
        }

        is RepresentationTemplate.MappingWrapper -> {
            RepresentationKind.Map
        }

        is RepresentationTemplate.EnumerationWrapper -> {
            RepresentationKind.Enum
        }

        is RepresentationTemplate.LinkWrapper -> {
            RepresentationKind.Link
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun TypeTemplate.matchesTemplate(
    actual: TypeTemplate,
    parameters: MutableMap<ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            parameters[value]?.let { it == actual } ?: run {
                parameters[value] = actual
                true
            }
        }

        is TypeTemplate.ScalarWrapper -> {
            actual == this
        }

        is TypeTemplate.NullableWrapper -> {
            actual is TypeTemplate.NullableWrapper && value.value.matchesTemplate(actual.value.value, parameters)
        }

        is TypeTemplate.NamedWrapper -> {
            if (actual !is TypeTemplate.NamedWrapper || value.definition != actual.value.definition ||
                value.arguments.size != actual.value.arguments.size
            ) {
                false
            } else {
                val candidateParameters = LinkedHashMap(parameters)
                val matches =
                    value.arguments.zip(actual.value.arguments).all { (expected, supplied) ->
                        expected.matchesTemplate(supplied, candidateParameters)
                    }
                if (matches) {
                    parameters.clear()
                    parameters.putAll(candidateParameters)
                }
                matches
            }
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun collectConfiguration(
    owned: OwnedConfiguration,
    constants: PortableConstantEncoder,
): ConfigurationCollectionResult =
    try {
        ConfigurationCollectionResult.Collected(
            CollectedOwnedConfiguration(
                owned,
                owned.callback.collect(DefaultConfigurationCollectionScope(owned.target, constants)),
            ),
        )
    } catch (cancelled: CancellationException) {
        throw cancelled
    } catch (cause: Exception) {
        ConfigurationCollectionResult.Failed(
            DeclarationDiagnostic(owned.target, "configuration_callback_failed", listOf(DeclarationOrigin(owned.origin.owner))),
            CatalogCallbackFailure(owned.origin, CatalogCallback.Configuration(owned.target), cause),
        )
    }

private fun configurationRuleDiagnostics(
    results: List<CollectedOwnedConfiguration>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): List<DeclarationDiagnostic> {
    val compiler = DefaultPortableRuleCompiler()
    val reasoner = DefaultPredicateReasoner()
    val recipes =
        results.flatMap { collected ->
            collected.configuration.recipes.map { recipe ->
                CollectedConfigurationRecipe(collected.owned.target, collected.owned.origin, recipe)
            }
        }
    return definitions.values.flatMap { definition ->
        val applicableOwners =
            (listOf(definition.id) + definition.transitiveAncestors(definitions).map(NamedTypeTemplate::definition)).toSet()
        recipes
            .filter { it.target in applicableOwners }
            .groupBy { it.recipe.relativePath to it.recipe.representationCondition }
            .values
            .flatMap { matching ->
                val origins = matching.map { DeclarationOrigin(it.origin.owner) }.distinct()
                val structural =
                    matching.flatMap { owned ->
                        owned.recipe.rules.flatMap(compiler::validateStructure).map { diagnostic ->
                            diagnostic.copy(affected = definition.id, origins = listOf(DeclarationOrigin(owned.origin.owner)))
                        }
                    }
                val subject =
                    checkedRuleSubject(
                        definition,
                        matching.first().recipe,
                        definitions,
                        catalog,
                    )
                if (subject == null) {
                    structural
                } else {
                    val compiled =
                        matching.flatMap { owned ->
                            owned.recipe.rules.map { rule -> owned to compiler.compile(rule, subject) }
                        }
                    val invalid =
                        compiled.flatMap { (owned, resolution) ->
                            (resolution as? Resolution.Invalid)?.diagnostics.orEmpty().map { diagnostic ->
                                diagnostic.copy(
                                    affected = definition.id,
                                    origins = listOf(DeclarationOrigin(owned.origin.owner)),
                                )
                            }
                        }
                    val checked = compiled.mapNotNull { (_, resolution) -> (resolution as? Resolution.Ready)?.value }
                    invalid +
                        reasoner.contradictions(checked).map { diagnostic ->
                            diagnostic.copy(affected = definition.id, origins = origins)
                        }
                }
            }
    }
}

private fun checkedRuleSubject(
    definition: TypeDefinition,
    recipe: ConfigurationRecipe,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): com.typewritermc.types.catalog.CheckedType? {
    val concrete =
        definition
            .templateAt(recipe.relativePath, definitions)
            ?.apply(emptyMap())
            ?.let { it as? Resolution.Ready }
            ?.value
            ?.let(catalog::resolve)
            ?.let { it as? Resolution.Ready }
            ?.value
    if (concrete != null) return concrete
    val representative = recipe.representationCondition?.representativeUse() ?: return null
    return (catalog.resolve(representative) as? Resolution.Ready)?.value
}

private fun RepresentationKind.representativeUse(): TypeUse? =
    when (this) {
        RepresentationKind.Unit -> {
            ScalarKind.UNIT.use
        }

        RepresentationKind.Boolean -> {
            ScalarKind.BOOLEAN.use
        }

        RepresentationKind.Text -> {
            ScalarKind.TEXT.use
        }

        RepresentationKind.Bytes -> {
            ScalarKind.BYTES.use
        }

        RepresentationKind.Integer -> {
            integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use
        }

        RepresentationKind.Float -> {
            floatScalar(FloatWidth.SIXTY_FOUR).use
        }

        RepresentationKind.Decimal -> {
            ScalarKind.DECIMAL.use
        }

        RepresentationKind.Timestamp -> {
            ScalarKind.TIMESTAMP.use
        }

        RepresentationKind.Duration -> {
            ScalarKind.DURATION.use
        }

        RepresentationKind.List -> {
            StandardTypes.list.use(listOf(ScalarKind.TEXT.use))
        }

        RepresentationKind.Set -> {
            StandardTypes.set.use(listOf(ScalarKind.TEXT.use))
        }

        RepresentationKind.Map -> {
            StandardTypes.map.use(
                listOf(
                    ScalarKind.TEXT.use,
                    ScalarKind.TEXT.use,
                ),
            )
        }

        RepresentationKind.Record,
        RepresentationKind.Enum,
        RepresentationKind.Link,
        -> {
            null
        }
    }

private data class CollectedConfigurationRecipe(
    val target: TypeDefinitionId,
    val origin: ProviderOrigin,
    val recipe: ConfigurationRecipe,
)

private fun TypeDefinition.templateAt(
    path: RelativeFieldPattern,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): TypeTemplate? {
    var current: TypeTemplate = id.template(parameters.map { it.key.template })
    path.segments.forEach { segment ->
        current = current.unwrapNullable()
        current =
            when (segment) {
                is FieldPatternSegment.Field -> {
                    current.field(segment.name, definitions)
                }

                FieldPatternSegment.Items -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.SequenceWrapper)?.value?.item?.substitute(arguments)
                    }
                }

                FieldPatternSegment.Keys -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.key?.substitute(arguments)
                    }
                }

                FieldPatternSegment.Values -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.MappingWrapper)?.value?.value?.substitute(arguments)
                    }
                }
            } ?: return null
    }
    return current
}

private fun TypeTemplate.unwrapNullable(): TypeTemplate = if (this is TypeTemplate.NullableWrapper) value.value else this

private fun TypeTemplate.field(
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

private fun TypeTemplate.representation(
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

private fun TypeTemplate.presentationTemplate(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): CheckedPresentationTemplate =
    CheckedPresentationTemplate(
        type = this,
        fieldResolver = { parent, name -> parent.unwrapNullable().field(name, definitions) },
        nestedResolver = { parent, slot -> parent.presentationNested(slot, definitions) },
        expressionChecker = { body, bindings, expected, present, mayBeMissing ->
            com.typewritermc.presentation.checkPresentationExpression(body, bindings, expected, present, catalog::resolve, mayBeMissing)
        },
        payloadResolver = { parent ->
            val scalar = (parent.unwrapNullable().representation(definitions)?.first as? RepresentationTemplate.ScalarWrapper)?.value?.kind
            if (scalar == null) parent.unwrapNullable() else scalar.template
        },
        linkResolver = { parent ->
            parent.unwrapNullable().representation(definitions)?.let { (representation, arguments) ->
                (representation as? RepresentationTemplate.LinkWrapper)?.let { link ->
                    com.typewritermc.presentation.PresentationLinkTemplate(link.value.endpoint, link.value.target.substitute(arguments))
                }
            }
        },
        subtypeChecker = catalog::isNominalSubtype,
        descriptorSelector = { actual, descriptors ->
            val bounds = definitions.parameterBounds()
            selectMostSpecificDescriptors(
                descriptors.filter { descriptor -> descriptor.target.appliesTo(actual, definitions, bounds) },
                catalog,
            )
        },
    )

private fun Map<TypeDefinitionId, TypeDefinition>.parameterBounds(): Map<ParameterKey, List<TypeTemplate>> =
    values
        .flatMap { definition -> definition.parameters.map { parameter -> parameter.key to parameter.bounds } }
        .toMap()

private fun PresentationTarget.appliesTo(
    actual: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
): Boolean =
    when (this) {
        is PresentationTarget.Representation -> {
            kind in actual.presentationKinds(definitions, bounds, linkedSetOf())
        }

        is PresentationTarget.Named -> {
            actual.presentationApplications(definitions, bounds, linkedSetOf()).any { application ->
                type.template.matchesTemplate(application.template, linkedMapOf())
            }
        }
    }

private fun TypeTemplate.presentationKinds(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
    visiting: MutableSet<TypeTemplate>,
): Set<RepresentationKind> {
    if (!visiting.add(this)) return emptySet()
    return try {
        when (this) {
            is TypeTemplate.ScalarWrapper -> {
                setOf(value.presentationKind())
            }

            is TypeTemplate.NullableWrapper -> {
                value.value.presentationKinds(definitions, bounds, visiting)
            }

            is TypeTemplate.ParameterWrapper -> {
                bounds[value].orEmpty().flatMapTo(
                    linkedSetOf(),
                ) { it.presentationKinds(definitions, bounds, visiting) }
            }

            is TypeTemplate.NamedWrapper -> {
                definitions[value.definition]
                    ?.representation
                    ?.presentationKind()
                    ?.let(::setOf)
                    .orEmpty()
            }

            else -> {
                unknownVariant(this)
            }
        }
    } finally {
        visiting.remove(this)
    }
}

private fun ScalarKind.presentationKind(): RepresentationKind = RepresentationTemplate.createScalar(kind = this).presentationKind()

private fun TypeTemplate.presentationApplications(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
    visiting: MutableSet<TypeTemplate>,
): List<NamedTypeTemplate> {
    if (!visiting.add(this)) return emptyList()
    return try {
        when (this) {
            is TypeTemplate.ScalarWrapper -> {
                emptyList()
            }

            is TypeTemplate.NullableWrapper -> {
                value.value.presentationApplications(definitions, bounds, visiting)
            }

            is TypeTemplate.ParameterWrapper -> {
                bounds[value].orEmpty().flatMap { it.presentationApplications(definitions, bounds, visiting) }.distinct()
            }

            is TypeTemplate.NamedWrapper -> {
                val declaration = definitions[value.definition] ?: return listOf(value)
                val substitutions =
                    declaration.parameters
                        .map(TypeParameter::key)
                        .zip(value.arguments)
                        .toMap()
                listOf(value) +
                    declaration.parents.flatMap { parent ->
                        parent.substitute(substitutions).template.presentationApplications(definitions, bounds, visiting)
                    }
            }

            else -> {
                unknownVariant(this)
            }
        }
    } finally {
        visiting.remove(this)
    }
}

private fun TypeTemplate.presentationNested(
    slot: NestedPresentationSlot,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): PresentationNestedTemplate? {
    return when (slot) {
        NestedPresentationSlot.Payload, NestedPresentationSlot.Fields -> {
            PresentationNestedTemplate(this)
        }

        NestedPresentationSlot.Items -> {
            val (representation, arguments) = unwrapNullable().representation(definitions) ?: return null
            val sequence = representation as? RepresentationTemplate.SequenceWrapper ?: return null
            PresentationNestedTemplate(sequence.value.item.substitute(arguments), sequence.value.kind)
        }

        NestedPresentationSlot.Keys -> {
            val (representation, arguments) = unwrapNullable().representation(definitions) ?: return null
            val mapping = representation as? RepresentationTemplate.MappingWrapper ?: return null
            PresentationNestedTemplate(mapping.value.key.substitute(arguments))
        }

        NestedPresentationSlot.Values -> {
            if (this is TypeTemplate.NullableWrapper) {
                PresentationNestedTemplate(value.value)
            } else {
                val (representation, arguments) = representation(definitions) ?: return null
                val mapping = representation as? RepresentationTemplate.MappingWrapper ?: return null
                PresentationNestedTemplate(mapping.value.value.substitute(arguments))
            }
        }
    }
}

private fun encodeConstant(
    expected: TypeTemplate,
    value: Any?,
    catalog: CheckedCatalog,
    bindings: com.typewritermc.types.NativeBindingRegistry,
): skirout.editor.v1.type_catalog.DataValue {
    val use =
        when (val applied = expected.apply(emptyMap())) {
            is Resolution.Ready -> applied.value
            is Resolution.Invalid -> throw IllegalArgumentException("A portable constant cannot target a free type parameter.")
        }
    val checked =
        when (val resolved = catalog.resolve(use)) {
            is Resolution.Ready -> resolved.value
            is Resolution.Invalid -> throw IllegalArgumentException("A portable constant requires a valid concrete type.")
        }
    return bindings.bind(checked).encodeGeneratedDefault(value)
}

private fun TypeDefinition.effectiveFields(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    recipes: List<ConfigurationRecipe>,
): List<EffectiveFieldTemplate> {
    val fields = templateFields(definitions).fields
    val applicableOwners = (listOf(id) + transitiveAncestors(definitions).map(NamedTypeTemplate::definition)).toSet()
    return fields.map { field ->
        val matching =
            recipes.filter { recipe ->
                recipe.origin.owner in applicableOwners &&
                    recipe.relativePath.segments == listOf(FieldPatternSegment.Field(field.owner.name))
            }
        EffectiveFieldTemplate(
            key = field.owner.name,
            owner = field.owner,
            type = field.type,
            rules = matching.flatMap(ConfigurationRecipe::rules).map { it.id },
        )
    }
}

private data class TemplateFieldsResult(
    val fields: List<FieldDeclaration>,
    val diagnostics: List<DeclarationDiagnostic>,
)

private fun TypeDefinition.templateFields(definitions: Map<TypeDefinitionId, TypeDefinition>): TemplateFieldsResult =
    collectTemplateFields(
        template = id.namedTemplate(parameters.map { it.key.template }),
        definitions = definitions,
        affected = id,
        stack = emptySet(),
    )

private fun TypeDefinition.transitiveAncestors(definitions: Map<TypeDefinitionId, TypeDefinition>): List<NamedTypeTemplate> {
    val roots = parents
    val result = linkedSetOf<NamedTypeTemplate>()

    fun visit(
        template: NamedTypeTemplate,
        stack: Set<TypeDefinitionId>,
    ) {
        if (!result.add(template) || template.definition in stack) return
        val definition = definitions[template.definition] ?: return
        val arguments =
            definition.parameters
                .map { it.key }
                .zip(template.arguments)
                .toMap()
        definition.parents.forEach { parent -> visit(parent.substitute(arguments), stack + template.definition) }
    }

    roots.forEach { visit(it, setOf(id)) }
    return result.toList()
}

private fun collectTemplateFields(
    template: NamedTypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    affected: TypeDefinitionId,
    stack: Set<TypeDefinitionId>,
): TemplateFieldsResult {
    if (template.definition in stack) return TemplateFieldsResult(emptyList(), emptyList())
    val definition = definitions[template.definition] ?: return TemplateFieldsResult(emptyList(), emptyList())
    val arguments =
        definition.parameters
            .map { it.key }
            .zip(template.arguments)
            .toMap()
    val parentResults =
        definition.parents.map { parent ->
            collectTemplateFields(
                parent.substitute(arguments),
                definitions,
                affected,
                stack + template.definition,
            )
        }
    val inherited = parentResults.flatMap(TemplateFieldsResult::fields)
    val diagnostics = parentResults.flatMap(TemplateFieldsResult::diagnostics).toMutableList()
    val own =
        (definition.representation as? RepresentationTemplate.RecordWrapper)?.value?.fields.orEmpty().map { field ->
            field.copy(type = field.type.substitute(arguments))
        }
    val fieldOrder = (inherited.map { it.owner.name } + own.map { it.owner.name }).distinct()
    val inheritedByName = inherited.groupBy { it.owner.name }.toMutableMap()
    val merged = linkedMapOf<String, FieldDeclaration>()
    own.forEach { field ->
        val inheritedFields = inheritedByName.remove(field.owner.name).orEmpty()
        val inheritedOwners = inheritedFields.map(FieldDeclaration::owner).toSet()
        if (inheritedOwners.isNotEmpty() && !field.overrides.containsAll(inheritedOwners)) {
            diagnostics +=
                DeclarationDiagnostic(
                    affected = affected,
                    code = "missing_field_override",
                    field = RelativeFieldPattern(listOf(FieldPatternSegment.Field(field.owner.name))),
                )
        }
        merged[field.owner.name] = field
    }
    inheritedByName.forEach { (name, fields) ->
        if (fields.map(FieldDeclaration::owner).distinct().size > 1 || fields.map(FieldDeclaration::type).distinct().size > 1) {
            diagnostics +=
                DeclarationDiagnostic(
                    affected = affected,
                    code = "ambiguous_inherited_field",
                    field = RelativeFieldPattern(listOf(FieldPatternSegment.Field(name))),
                )
        } else {
            merged[name] = fields.first()
        }
    }
    return TemplateFieldsResult(fieldOrder.mapNotNull(merged::get), diagnostics.distinct())
}

private fun DeclarationStatus.diagnostics(): List<DeclarationDiagnostic> =
    when (this) {
        DeclarationStatus.Ready -> emptyList()
        is DeclarationStatus.Unavailable -> reasons
    }

private class ImmutableOwnedProviderRegistry(
    private val ownedConfigurations: List<OwnedConfiguration>,
    private val ownedPresentations: List<OwnedPresentation>,
    private val ownedNativeBindings: List<OwnedNativeBinding>,
    private val ownedChecks: List<OwnedCheck>,
) : OwnedProviderRegistry {
    override fun retain(origin: ProviderOrigin): ProviderLease {
        require(
            ownedConfigurations.any { it.origin == origin } ||
                ownedPresentations.any { it.origin == origin } ||
                ownedNativeBindings.any { it.origin == origin } ||
                ownedChecks.any { it.origin == origin },
        ) { "Unknown provider origin $origin." }
        return ImmutableProviderLease
    }

    override fun configurations(): List<OwnedConfiguration> = ownedConfigurations

    override fun presentations(): List<OwnedPresentation> = ownedPresentations

    override fun nativeBindings(): List<OwnedNativeBinding> = ownedNativeBindings

    override fun checks(): List<OwnedCheck> = ownedChecks
}

private data object ImmutableProviderLease : ProviderLease {
    override fun close() = Unit
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
