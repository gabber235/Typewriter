package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.InitializationDescriptor
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.complete
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.checking.CatalogGeneration
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
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.PresentationNestedTemplate
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.RoleFallback
import com.typewritermc.presentation.explicitFieldSelections
import com.typewritermc.presentation.isEquivalentTo
import com.typewritermc.presentation.isMoreSpecificThan
import com.typewritermc.presentation.selectMostSpecificDescriptors
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationOrigin
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.EffectiveFieldTemplate
import com.typewritermc.types.catalog.PublishedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import java.util.concurrent.CancellationException

data class OwnedTypeDeclaration(
    val origin: ProviderOrigin,
    val definition: TypeDefinition,
    val display: TypeDisplay? = null,
)

data class CatalogAssemblyContext(
    val generation: CatalogGeneration,
    val relations: List<RelationContract> = emptyList(),
    val endpointBindings: List<EndpointBindingTemplate> = emptyList(),
    val resources: List<AuthoringResourceDefinition> = emptyList(),
    val initialization: List<InitializationDescriptor> = emptyList(),
    val capabilities: List<RealmCapabilityDescriptor> = emptyList(),
    val roleFallbacks: List<RoleFallback> = DEFAULT_ROLE_FALLBACKS,
)

val DEFAULT_ROLE_FALLBACKS: List<RoleFallback> =
    listOf(
        RoleFallback(PresentationRole.REFERENCE_OPTION, listOf(PresentationRole.COLLECTION_ITEM)),
        RoleFallback(PresentationRole.COLLECTION_ITEM, listOf(PresentationRole.REFERENCE_SUMMARY)),
    )

data class CatalogAssembly(
    val snapshot: EditorCatalogSnapshot,
    val checked: CheckedCatalog,
    val bindings: com.typewritermc.types.NativeBindingRegistry,
    val providers: OwnedProviderRegistry,
    val checks: List<OwnedCheckRecipe>,
)

interface DeclarationDependencyIndex {
    fun requiredDependents(id: TypeDefinitionId): Set<TypeDefinitionId>
}

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
    val symbolicDiagnostics =
        definitionIndex.values.flatMap { definition -> definition.templateFields(definitionIndex).diagnostics }
    val providerRegistry = ImmutableOwnedProviderRegistry(configurations, presentations, nativeBindings, checks)
    val structural = DefaultCheckedCatalog(context.generation, definitions)
    val resourceDefinitions = (resources + context.resources).distinctBy(AuthoringResourceDefinition::id)
    val resourceFamilyDiagnostics =
        definitions
            .filter { (it.representation as? RepresentationTemplate.Record)?.abstract != true }
            .flatMap { definition ->
                val families =
                    resourceDefinitions.filter { family ->
                        structural.isNominalSubtype(definition.id, family.root)
                    }
                if (families.size <= 1) {
                    emptyList()
                } else {
                    (listOf(definition.id) + families.map(AuthoringResourceDefinition::root)).map { affected ->
                        DeclarationDiagnostic(affected, "overlapping_resource_family")
                    }
                }
            }.distinct()
    val structuralBindings =
        com.typewritermc.types.FactoryNativeBindingRegistry(structural, nativeBindings.map(OwnedNativeBinding::factory))
    val constants = PortableConstantEncoder { expected, value -> encodeConstant(expected, value, structural, structuralBindings) }
    val collectionResults = configurations.map { collectConfiguration(it, constants) }
    val ruleDiagnostics = configurationRuleDiagnostics(collectionResults, definitionIndex, structural)
    val collectedPreferences =
        collectionResults.mapNotNull(ConfigurationCollectionResult::collected).mapNotNull { result ->
            result.configuration.initialization?.let { result.owned.target to it }
        }
    val preferenceDiagnostics =
        collectedPreferences
            .groupBy(Pair<TypeDefinitionId, com.typewritermc.configuration.InitializationPreference>::first)
            .filterValues { preferences -> preferences.map { it.second }.distinct().size > 1 }
            .keys
            .map { affected -> DeclarationDiagnostic(affected, "contradictory_initialization_preference") }
    val preferences =
        collectedPreferences
            .groupBy(Pair<TypeDefinitionId, com.typewritermc.configuration.InitializationPreference>::first)
            .mapNotNull { (target, configured) ->
                configured
                    .map { it.second }
                    .distinct()
                    .singleOrNull()
                    ?.let { target to it }
            }.toMap()
    val initializationPlan =
        com.typewritermc.authoring
            .InitializationCatalogPlanner(structural, structuralBindings)
            .plan(definitions, preferences)
    val initializationDiagnostics =
        initializationPlan.diagnostics.flatMap { (affected, diagnostics) ->
            diagnostics.map { diagnostic -> DeclarationDiagnostic(affected, diagnostic.code) }
        }
    val materialCollection =
        collectPresentationMaterials(
            presentations,
            nativeBindings,
            definitionIndex,
            structural,
            resourceDefinitions,
        )
    val presentationDiagnostics =
        presentationFieldDiagnostics(
            materialCollection.materials,
            presentations.map(OwnedPresentation::descriptor),
            definitionIndex,
            structural,
        )
    val directFailures =
        collectionResults.mapNotNull(ConfigurationCollectionResult::failure) +
            duplicateDiagnostics + symbolicDiagnostics + ruleDiagnostics + preferenceDiagnostics + initializationDiagnostics +
            materialCollection.failures + presentationDiagnostics + resourceFamilyDiagnostics
    val unavailable = propagateUnavailableDefinitions(directFailures.map(DeclarationDiagnostic::affected).toSet(), definitions)
    val checked = DefaultCheckedCatalog(context.generation, definitions.filterNot { it.id in unavailable })
    val bindingRegistry =
        com.typewritermc.types.FactoryNativeBindingRegistry(checked, nativeBindings.map(OwnedNativeBinding::factory))
    val collected = collectionResults.mapNotNull(ConfigurationCollectionResult::collected)
    val recipes = collected.flatMap { it.configuration.recipes }
    val simpleChecks =
        collected.flatMap { result ->
            result.configuration.checks.map { OwnedCheckRecipe(result.owned.origin, it.bindNative(bindingRegistry)) }
        }
    val propagatedFailures =
        (unavailable - directFailures.map(DeclarationDiagnostic::affected).toSet()).map { affected ->
            DeclarationDiagnostic(affected, "configuration_dependency_unavailable")
        }
    val isolationDiagnostics = directFailures + propagatedFailures
    val isolationByDefinition = isolationDiagnostics.groupBy(DeclarationDiagnostic::affected)
    val diagnostics =
        declarationGroups.keys.flatMap { id ->
            isolationByDefinition[id] ?: checked.definition(id).diagnostics()
        }
    val published =
        declarationGroups.entries.sortedBy { it.key.toString() }.map { (id, owned) ->
            val definition = owned.first().definition
            val status = isolationByDefinition[id]?.let(DeclarationStatus::Unavailable) ?: checked.definition(id)
            val ancestry = if (status == DeclarationStatus.Ready) definition.transitiveAncestors(definitionIndex) else emptyList()
            PublishedType(
                definition = definition,
                status = status,
                effectiveFields =
                    if (status ==
                        DeclarationStatus.Ready
                    ) {
                        definition.effectiveFields(definitionIndex, recipes)
                    } else {
                        emptyList()
                    },
                ancestorTemplates = ancestry,
                display = owned.first().display,
            )
        }
    val snapshot =
        EditorCatalogSnapshot(
            generation = context.generation,
            types = published,
            relations = (relations + context.relations).distinctBy(RelationContract::id),
            resourceDefinitions = resourceDefinitions.filter { it.root !in unavailable },
            presentations = presentations.map(OwnedPresentation::descriptor),
            presentationMaterials =
                materialCollection.materials.filter { material ->
                    val target = material.target as? PresentationTarget.Named
                    target == null || target.type.definition !in unavailable
                },
            configuration = recipes,
            diagnostics = diagnostics,
            initialization =
                (context.initialization + initializationPlan.descriptors)
                    .filter { it.definition !in unavailable }
                    .distinctBy(com.typewritermc.authoring.InitializationDescriptor::definition),
            endpointBindings = (endpointBindings + context.endpointBindings).distinct(),
            capabilities = context.capabilities.sortedBy { it.id.value },
            recommendations = typeRecommendations(definitionIndex, unavailable),
            roleFallbacks = context.roleFallbacks,
        ).immutableCopy()
    return CatalogAssembly(snapshot, checked, bindingRegistry, providerRegistry, simpleChecks)
}

private data class CollectedOwnedConfiguration(
    val owned: OwnedConfiguration,
    val configuration: com.typewritermc.configuration.CollectedConfiguration,
)

private data class PresentationMaterialCollection(
    val materials: List<PresentationMaterial>,
    val failures: List<DeclarationDiagnostic>,
)

private fun collectPresentationMaterials(
    presentations: List<OwnedPresentation>,
    nativeBindings: List<OwnedNativeBinding>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    resources: List<AuthoringResourceDefinition>,
): PresentationMaterialCollection {
    val materials = mutableListOf<PresentationMaterial>()
    val failures = mutableListOf<DeclarationDiagnostic>()
    val resourceTypes =
        nativeBindings
            .mapNotNull { owned ->
                val native = owned.factory.nativeClass ?: return@mapNotNull null
                val definition = definitions[owned.factory.definition] ?: return@mapNotNull null
                native to TypeTemplate.Named(definition.id, definition.parameters.map { TypeTemplate.Parameter(it.key) })
            }.groupBy(Pair<kotlin.reflect.KClass<*>, TypeTemplate.Named>::first)
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
            owned.descriptor.roles.sortedBy { it.ordinal }.forEach { role ->
                try {
                    val result = owned.provider.build(PresentationBuildBinding(template, role, resourceTypes))
                    if (result.dependencies.validCollections(subject, definitions, catalog, resources)) {
                        materials +=
                            PresentationMaterial(
                                provider = owned.descriptor.id,
                                target = owned.descriptor.target,
                                subject = subject,
                                role = role,
                                layout = result.layout,
                                dependencies = result.dependencies,
                            )
                    } else {
                        val affected = (subject as? TypeTemplate.Named)?.definition
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
                } catch (_: Exception) {
                    val affected = (subject as? TypeTemplate.Named)?.definition
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
    return PresentationMaterialCollection(materials, failures)
}

private fun skirout.editor.v1.presentation.PresentationDependencies.validCollections(
    subject: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
    resources: List<AuthoringResourceDefinition>,
): Boolean {
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
        val wireRowType = collection.rowType
        val rowType = SkirTypeCodec.decode(wireRowType).valueOrNull() ?: return@all false
        if (!rowType.isValidMaterialTemplate(definitions, parameterBounds, catalog)) return@all false
        val projection = collection.projection
        val resourceCollection = collection.resources
        if (projection != null && resourceCollection != null) return@all false
        when {
            projection != null -> {
                projection.isValid(rowType, definitions, parameterBounds, catalog, resources)
            }

            resourceCollection != null -> {
                val namedRow = rowType as? TypeTemplate.Named
                namedRow != null &&
                    wireRowType is skirout.editor.v1.type_catalog.TypeTemplate.NamedWrapper &&
                    wireRowType.value.definition == resourceCollection.root &&
                    resources.any { resource -> catalog.isNominalSubtype(namedRow.definition, resource.root) }
            }

            else -> {
                true
            }
        }
    }
}

private fun skirout.editor.v1.presentation.PresentationCollectionProjection.isValid(
    rowType: TypeTemplate,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    parameterBounds: Map<ParameterKey, List<TypeTemplate>>,
    catalog: CheckedCatalog,
    resources: List<AuthoringResourceDefinition>,
): Boolean {
    val root =
        SkirTypeCodec
            .decode(
                skirout.editor.v1.type_catalog.TypeTemplate
                    .NamedWrapper(this.root),
            ).valueOrNull() as? TypeTemplate.Named ?: return false
    if (!root.isValidMaterialTemplate(definitions, parameterBounds, catalog)) return false
    if (resources.none { resource -> catalog.isNominalSubtype(root.definition, resource.root) }) return false
    return fields.all { field ->
        val targetPath = SkirAuthoringValueCodec.decode(field.target).valueOrNull() ?: return@all false
        val targetType = rowType.templateAt(targetPath, definitions) ?: return@all false
        when (val source = field.source) {
            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.ContentWrapper -> {
                val sourcePath = SkirAuthoringValueCodec.decode(source.value).valueOrNull() ?: return@all false
                val sourceType = root.templateAt(sourcePath, definitions) ?: return@all false
                catalog.isTemplateReadableAs(sourceType, targetType, parameterBounds)
            }

            is skirout.editor.v1.presentation.PresentationCollectionProjectionValue.LiteralWrapper -> {
                val value = SkirDataValueCodec.decode(source.value).valueOrNull() ?: return@all false
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
        is TypeTemplate.Parameter -> {
            key in parameterBounds
        }

        is TypeTemplate.Named -> {
            val definition = definitions[definition]
            definition != null &&
                catalog.definition(this.definition) == DeclarationStatus.Ready &&
                arguments.size == definition.parameters.size &&
                arguments.all { it.isValidMaterialTemplate(definitions, parameterBounds, catalog) } &&
                definition.parameters.zip(arguments).all { (parameter, argument) ->
                    val bindings =
                        definition.parameters
                            .map(TypeParameter::key)
                            .zip(arguments)
                            .toMap()
                    parameter.bounds.all { bound ->
                        val expected = bound.substitute(bindings)
                        catalog.isTemplateReadableAs(argument, expected, parameterBounds)
                    }
                }
        }

        is TypeTemplate.Nullable -> {
            value.isValidMaterialTemplate(definitions, parameterBounds, catalog)
        }

        is TypeTemplate.Scalar -> {
            true
        }
    }

private fun TypeTemplate.acceptsLiteral(
    value: com.typewritermc.types.DataValue,
    parameters: Set<ParameterKey>,
    catalog: CheckedCatalog,
): Boolean {
    if (value == com.typewritermc.types.DataValue.Unfilled) return true
    if (parameterKeys().any(parameters::contains)) return false
    val use = (apply(emptyMap()) as? Resolution.Ready)?.value ?: return false
    val checked = (catalog.resolve(use) as? Resolution.Ready)?.value ?: return false
    return checked.complete(value) !is CompletenessResult.Invalid
}

private fun TypeTemplate.parameterKeys(): Set<ParameterKey> =
    when (this) {
        is TypeTemplate.Parameter -> setOf(key)
        is TypeTemplate.Named -> arguments.flatMapTo(linkedSetOf()) { it.parameterKeys() }
        is TypeTemplate.Nullable -> value.parameterKeys()
        is TypeTemplate.Scalar -> emptySet()
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
                is PathSegment.Field -> {
                    current.field(segment.name, definitions)
                }

                is PathSegment.Item -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.Sequence)?.item?.substitute(arguments)
                    }
                }

                PathSegment.MapKey -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.Mapping)?.key?.substitute(arguments)
                    }
                }

                PathSegment.MapValue -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.Mapping)?.value?.substitute(arguments)
                    }
                }
            } ?: return null
    }
    return current
}

private fun <Value> SkirConversionResult<Value>.valueOrNull(): Value? =
    when (this) {
        is SkirConversionResult.Success -> value
        is SkirConversionResult.Failure -> null
    }

private fun PresentationTarget.presentationSubjects(definitions: Map<TypeDefinitionId, TypeDefinition>): List<TypeTemplate> =
    when (this) {
        is PresentationTarget.Named -> {
            val definition = definitions[type.definition]
            if (definition == null || definition.parameters.size != type.arguments.size) emptyList() else listOf(type)
        }

        is PresentationTarget.Representation -> {
            val named =
                definitions.values
                    .filter { it.representation.presentationKind() == kind }
                    .map { definition ->
                        TypeTemplate.Named(definition.id, definition.parameters.map { TypeTemplate.Parameter(it.key) })
                    }
            (named + kind.scalarSubjects()).distinct()
        }
    }

private fun RepresentationKind.scalarSubjects(): List<TypeTemplate.Scalar> =
    when (this) {
        RepresentationKind.Unit -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Unit))
        }

        RepresentationKind.Boolean -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Boolean))
        }

        RepresentationKind.Text -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Text))
        }

        RepresentationKind.Bytes -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Bytes))
        }

        RepresentationKind.Integer -> {
            com.typewritermc.types.IntegerWidth.entries.map { width ->
                TypeTemplate.Scalar(
                    com.typewritermc.types.ScalarKind
                        .Integer(width),
                )
            }
        }

        RepresentationKind.Float -> {
            com.typewritermc.types.FloatWidth.entries.map { width ->
                TypeTemplate.Scalar(
                    com.typewritermc.types.ScalarKind
                        .Float(width),
                )
            }
        }

        RepresentationKind.Decimal -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Decimal))
        }

        RepresentationKind.Timestamp -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Timestamp))
        }

        RepresentationKind.Duration -> {
            listOf(TypeTemplate.Scalar(com.typewritermc.types.ScalarKind.Duration))
        }

        else -> {
            emptyList()
        }
    }

private data class ConfigurationCollectionResult(
    val collected: CollectedOwnedConfiguration? = null,
    val failure: DeclarationDiagnostic? = null,
)

private data class FieldPresentationCandidate(
    val selection: com.typewritermc.presentation.OwnedFieldPresentation,
    val descriptor: PresentationDescriptor?,
)

private fun presentationFieldDiagnostics(
    materials: List<PresentationMaterial>,
    descriptors: List<PresentationDescriptor>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): List<DeclarationDiagnostic> {
    val descriptorsById =
        descriptors
            .groupBy(PresentationDescriptor::id)
            .mapValues { (_, matching) -> matching.singleOrNull() }
    val selections =
        materials.flatMap(PresentationMaterial::explicitFieldSelections).map { selection ->
            FieldPresentationCandidate(selection, descriptorsById[selection.provider])
        }
    return definitions.values.flatMap { definition ->
        selections
            .filter { candidate -> candidate.selection.target.appliesTo(definition, definitions) }
            .groupBy { candidate -> candidate.selection.role to candidate.selection.field }
            .values
            .mapNotNull { candidates ->
                val maximal =
                    candidates.filterNot { candidate ->
                        candidates.any { other ->
                            other.selection.target.isMoreSpecificThan(candidate.selection.target, catalog)
                        }
                    }
                val incomparable =
                    maximal.any { candidate ->
                        maximal.any { other ->
                            !candidate.selection.target.isEquivalentTo(other.selection.target, catalog)
                        }
                    }
                val winners =
                    if (incomparable) {
                        maximal
                    } else {
                        val highestPriority = maximal.maxOfOrNull { it.descriptor?.priority ?: 0 } ?: return@mapNotNull null
                        maximal.filter { (it.descriptor?.priority ?: 0) == highestPriority }
                    }
                if (winners.map { it.selection.selected }.distinct().size < 2) return@mapNotNull null
                DeclarationDiagnostic(
                    affected = definition.id,
                    code = "conflicting_field_presentation",
                    origins =
                        winners
                            .mapNotNull { it.descriptor?.owner }
                            .distinct()
                            .map(::DeclarationOrigin),
                )
            }
    }
}

private fun PresentationTarget.appliesTo(
    definition: TypeDefinition,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): Boolean =
    when (this) {
        is PresentationTarget.Representation -> {
            definition.representation.presentationKind() == kind
        }

        is PresentationTarget.Named -> {
            val own = TypeTemplate.Named(definition.id, definition.parameters.map { TypeTemplate.Parameter(it.key) })
            (listOf(own) + definition.transitiveAncestors(definitions)).any { application ->
                type.matchesTemplate(application, linkedMapOf())
            }
        }
    }

private fun RepresentationTemplate.presentationKind(): RepresentationKind =
    when (this) {
        is RepresentationTemplate.Scalar -> {
            when (kind) {
                com.typewritermc.types.ScalarKind.Unit -> RepresentationKind.Unit
                com.typewritermc.types.ScalarKind.Boolean -> RepresentationKind.Boolean
                com.typewritermc.types.ScalarKind.Text -> RepresentationKind.Text
                com.typewritermc.types.ScalarKind.Bytes -> RepresentationKind.Bytes
                is com.typewritermc.types.ScalarKind.Integer -> RepresentationKind.Integer
                is com.typewritermc.types.ScalarKind.Float -> RepresentationKind.Float
                com.typewritermc.types.ScalarKind.Decimal -> RepresentationKind.Decimal
                com.typewritermc.types.ScalarKind.Timestamp -> RepresentationKind.Timestamp
                com.typewritermc.types.ScalarKind.Duration -> RepresentationKind.Duration
            }
        }

        is RepresentationTemplate.Record -> {
            RepresentationKind.Record
        }

        is RepresentationTemplate.Sequence -> {
            when (kind) {
                com.typewritermc.types.CollectionKind.List -> RepresentationKind.List
                com.typewritermc.types.CollectionKind.Set -> RepresentationKind.Set
            }
        }

        is RepresentationTemplate.Mapping -> {
            RepresentationKind.Map
        }

        is RepresentationTemplate.Enumeration -> {
            RepresentationKind.Enum
        }

        is RepresentationTemplate.Link -> {
            RepresentationKind.Link
        }
    }

private fun TypeTemplate.matchesTemplate(
    actual: TypeTemplate,
    parameters: MutableMap<ParameterKey, TypeTemplate>,
): Boolean =
    when (this) {
        is TypeTemplate.Parameter -> {
            parameters[key]?.let { it == actual } ?: run {
                parameters[key] = actual
                true
            }
        }

        is TypeTemplate.Scalar -> {
            actual == this
        }

        is TypeTemplate.Nullable -> {
            actual is TypeTemplate.Nullable && value.matchesTemplate(actual.value, parameters)
        }

        is TypeTemplate.Named -> {
            if (actual !is TypeTemplate.Named || definition != actual.definition || arguments.size != actual.arguments.size) {
                false
            } else {
                val candidateParameters = LinkedHashMap(parameters)
                val matches =
                    arguments.zip(actual.arguments).all { (expected, supplied) ->
                        expected.matchesTemplate(supplied, candidateParameters)
                    }
                if (matches) {
                    parameters.clear()
                    parameters.putAll(candidateParameters)
                }
                matches
            }
        }
    }

private fun collectConfiguration(
    owned: OwnedConfiguration,
    constants: PortableConstantEncoder,
): ConfigurationCollectionResult =
    try {
        ConfigurationCollectionResult(
            collected =
                CollectedOwnedConfiguration(
                    owned,
                    owned.callback.collect(DefaultConfigurationCollectionScope(owned.target, constants)),
                ),
        )
    } catch (cancellation: CancellationException) {
        throw cancellation
    } catch (_: Exception) {
        ConfigurationCollectionResult(
            failure =
                DeclarationDiagnostic(
                    affected = owned.target,
                    code = "configuration_callback_failed",
                    origins = listOf(DeclarationOrigin(owned.origin.owner)),
                ),
        )
    }

private fun configurationRuleDiagnostics(
    results: List<ConfigurationCollectionResult>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    catalog: CheckedCatalog,
): List<DeclarationDiagnostic> {
    val compiler = DefaultPortableRuleCompiler()
    val reasoner = DefaultPredicateReasoner()
    val recipes =
        results.mapNotNull(ConfigurationCollectionResult::collected).flatMap { collected ->
            collected.configuration.recipes.map { recipe ->
                CollectedConfigurationRecipe(collected.owned.target, collected.owned.origin, recipe)
            }
        }
    return definitions.values.flatMap { definition ->
        val applicableOwners =
            (listOf(definition.id) + definition.transitiveAncestors(definitions).map(TypeTemplate.Named::definition)).toSet()
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
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Unit)
        }

        RepresentationKind.Boolean -> {
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Boolean)
        }

        RepresentationKind.Text -> {
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text)
        }

        RepresentationKind.Bytes -> {
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Bytes)
        }

        RepresentationKind.Integer -> {
            TypeUse.Scalar(
                com.typewritermc.types.ScalarKind
                    .Integer(com.typewritermc.types.IntegerWidth.SIGNED_64),
            )
        }

        RepresentationKind.Float -> {
            TypeUse.Scalar(
                com.typewritermc.types.ScalarKind
                    .Float(com.typewritermc.types.FloatWidth.FLOAT_64),
            )
        }

        RepresentationKind.Decimal -> {
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Decimal)
        }

        RepresentationKind.Timestamp -> {
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Timestamp)
        }

        RepresentationKind.Duration -> {
            TypeUse.Scalar(com.typewritermc.types.ScalarKind.Duration)
        }

        RepresentationKind.List -> {
            TypeUse.Named(StandardTypes.list, listOf(TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text)))
        }

        RepresentationKind.Set -> {
            TypeUse.Named(StandardTypes.set, listOf(TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text)))
        }

        RepresentationKind.Map -> {
            TypeUse.Named(
                StandardTypes.map,
                listOf(
                    TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text),
                    TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text),
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
    var current: TypeTemplate = TypeTemplate.Named(id, parameters.map { TypeTemplate.Parameter(it.key) })
    path.segments.forEach { segment ->
        current = current.unwrapNullable()
        current =
            when (segment) {
                is FieldPatternSegment.Field -> {
                    current.field(segment.name, definitions)
                }

                FieldPatternSegment.Items -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.Sequence)?.item?.substitute(arguments)
                    }
                }

                FieldPatternSegment.Keys -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.Mapping)?.key?.substitute(arguments)
                    }
                }

                FieldPatternSegment.Values -> {
                    current.representation(definitions)?.let { (representation, arguments) ->
                        (representation as? RepresentationTemplate.Mapping)?.value?.substitute(arguments)
                    }
                }
            } ?: return null
    }
    return current
}

private fun TypeTemplate.unwrapNullable(): TypeTemplate = if (this is TypeTemplate.Nullable) value else this

private fun TypeTemplate.field(
    name: String,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
): TypeTemplate? {
    val named = this as? TypeTemplate.Named ?: return null
    val definition = definitions[named.definition] ?: return null
    val arguments =
        definition.parameters
            .map(TypeParameter::key)
            .zip(named.arguments)
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
    val named = this as? TypeTemplate.Named ?: return null
    val definition = definitions[named.definition] ?: return null
    return definition.representation to
        definition.parameters
            .map(TypeParameter::key)
            .zip(named.arguments)
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
                type.matchesTemplate(application, linkedMapOf())
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
            is TypeTemplate.Scalar -> {
                setOf(kind.presentationKind())
            }

            is TypeTemplate.Nullable -> {
                value.presentationKinds(definitions, bounds, visiting)
            }

            is TypeTemplate.Parameter -> {
                bounds[key].orEmpty().flatMapTo(
                    linkedSetOf(),
                ) { it.presentationKinds(definitions, bounds, visiting) }
            }

            is TypeTemplate.Named -> {
                definitions[definition]
                    ?.representation
                    ?.presentationKind()
                    ?.let(::setOf)
                    .orEmpty()
            }
        }
    } finally {
        visiting.remove(this)
    }
}

private fun com.typewritermc.types.ScalarKind.presentationKind(): RepresentationKind =
    RepresentationTemplate.Scalar(this).presentationKind()

private fun TypeTemplate.presentationApplications(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    bounds: Map<ParameterKey, List<TypeTemplate>>,
    visiting: MutableSet<TypeTemplate>,
): List<TypeTemplate.Named> {
    if (!visiting.add(this)) return emptyList()
    return try {
        when (this) {
            is TypeTemplate.Scalar -> {
                emptyList()
            }

            is TypeTemplate.Nullable -> {
                value.presentationApplications(definitions, bounds, visiting)
            }

            is TypeTemplate.Parameter -> {
                bounds[key].orEmpty().flatMap { it.presentationApplications(definitions, bounds, visiting) }.distinct()
            }

            is TypeTemplate.Named -> {
                val declaration = definitions[definition] ?: return listOf(this)
                val substitutions =
                    declaration.parameters
                        .map(TypeParameter::key)
                        .zip(arguments)
                        .toMap()
                listOf(this) +
                    declaration.parents.flatMap { parent ->
                        parent.substitute(substitutions).presentationApplications(definitions, bounds, visiting)
                    }
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
            val sequence = representation as? RepresentationTemplate.Sequence ?: return null
            PresentationNestedTemplate(sequence.item.substitute(arguments), sequence.kind)
        }

        NestedPresentationSlot.Keys -> {
            val (representation, arguments) = unwrapNullable().representation(definitions) ?: return null
            val mapping = representation as? RepresentationTemplate.Mapping ?: return null
            PresentationNestedTemplate(mapping.key.substitute(arguments))
        }

        NestedPresentationSlot.Values -> {
            if (this is TypeTemplate.Nullable) {
                PresentationNestedTemplate(value)
            } else {
                val (representation, arguments) = representation(definitions) ?: return null
                val mapping = representation as? RepresentationTemplate.Mapping ?: return null
                PresentationNestedTemplate(mapping.value.substitute(arguments))
            }
        }
    }
}

private fun encodeConstant(
    expected: TypeTemplate,
    value: Any?,
    catalog: CheckedCatalog,
    bindings: com.typewritermc.types.NativeBindingRegistry,
): com.typewritermc.types.DataValue {
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

private fun propagateUnavailableDefinitions(
    initial: Set<TypeDefinitionId>,
    definitions: List<TypeDefinition>,
): Set<TypeDefinitionId> {
    val declared = definitions.map(TypeDefinition::id).toSet()
    val unavailable = initial.toMutableSet()
    var changed: Boolean
    do {
        changed = false
        definitions.forEach { definition ->
            if (definition.id !in unavailable && definition.requiredDefinitions().any { it in unavailable && it in declared }) {
                unavailable += definition.id
                changed = true
            }
        }
    } while (changed)
    return unavailable
}

private fun TypeDefinition.requiredDefinitions(): Set<TypeDefinitionId> =
    parents.flatMapTo(mutableSetOf()) { it.requiredDefinitions() } + representation.requiredDefinitions()

private fun RepresentationTemplate.requiredDefinitions(): Set<TypeDefinitionId> =
    when (this) {
        is RepresentationTemplate.Scalar, is RepresentationTemplate.Enumeration -> emptySet()
        is RepresentationTemplate.Record -> fields.flatMapTo(mutableSetOf()) { it.type.requiredDefinitions() }
        is RepresentationTemplate.Sequence -> item.requiredDefinitions()
        is RepresentationTemplate.Mapping -> key.requiredDefinitions() + value.requiredDefinitions()
        is RepresentationTemplate.Link -> target.requiredDefinitions()
    }

private fun TypeTemplate.requiredDefinitions(): Set<TypeDefinitionId> =
    when (this) {
        is TypeTemplate.Parameter, is TypeTemplate.Scalar -> emptySet()
        is TypeTemplate.Nullable -> value.requiredDefinitions()
        is TypeTemplate.Named -> setOf(definition) + arguments.flatMapTo(mutableSetOf()) { it.requiredDefinitions() }
    }

private fun TypeDefinition.effectiveFields(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    recipes: List<ConfigurationRecipe>,
): List<EffectiveFieldTemplate> {
    val fields = templateFields(definitions).fields
    val applicableOwners = (listOf(id) + transitiveAncestors(definitions).map(TypeTemplate.Named::definition)).toSet()
    return fields.map { field ->
        val matching =
            recipes.filter { recipe ->
                recipe.origin.owner in applicableOwners &&
                    recipe.relativePath.segments == listOf(FieldPatternSegment.Field(field.owner.name))
            }
        EffectiveFieldTemplate(
            key = field.owner.name,
            owner = FieldOwner(field.owner.definition, field.owner.name),
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
        template = TypeTemplate.Named(id, parameters.map { TypeTemplate.Parameter(it.key) }),
        definitions = definitions,
        affected = id,
        stack = emptySet(),
    )

private fun TypeDefinition.transitiveAncestors(definitions: Map<TypeDefinitionId, TypeDefinition>): List<TypeTemplate.Named> {
    val roots = parents
    val result = linkedSetOf<TypeTemplate.Named>()

    fun visit(
        template: TypeTemplate.Named,
        stack: Set<TypeDefinitionId>,
    ) {
        if (!result.add(template) || template.definition in stack) return
        val definition = definitions[template.definition] ?: return
        val arguments =
            definition.parameters
                .map { it.key }
                .zip(template.arguments)
                .toMap()
        definition.parents.forEach { parent -> visit(parent.substitute(arguments) as TypeTemplate.Named, stack + template.definition) }
    }

    roots.forEach { visit(it, setOf(id)) }
    return result.toList()
}

private fun collectTemplateFields(
    template: TypeTemplate.Named,
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
                parent.substitute(arguments) as TypeTemplate.Named,
                definitions,
                affected,
                stack + template.definition,
            )
        }
    val inherited = parentResults.flatMap(TemplateFieldsResult::fields)
    val diagnostics = parentResults.flatMap(TemplateFieldsResult::diagnostics).toMutableList()
    val own =
        (definition.representation as? RepresentationTemplate.Record)?.fields.orEmpty().map { field ->
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

private fun TypeTemplate.substitute(arguments: Map<ParameterKey, TypeTemplate>): TypeTemplate =
    when (this) {
        is TypeTemplate.Parameter -> arguments[key] ?: this
        is TypeTemplate.Named -> copy(arguments = this.arguments.map { it.substitute(arguments) })
        is TypeTemplate.Nullable -> copy(value = value.substitute(arguments))
        is TypeTemplate.Scalar -> this
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
                ContributionKey(
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
