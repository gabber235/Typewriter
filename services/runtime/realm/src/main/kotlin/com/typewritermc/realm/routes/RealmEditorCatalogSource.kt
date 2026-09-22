package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringCreationContext
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementCatalogEntry
import com.typewritermc.library.Book
import com.typewritermc.library.Page
import com.typewritermc.library.Tag
import com.typewritermc.pages.PageCatalogEntry
import com.typewritermc.pages.PageDiagnostic
import com.typewritermc.pages.ResolvedPageEditorDefinition
import com.typewritermc.presentation.PresentationDiagnostic
import com.typewritermc.realm.AuthoringCreationHostCardinality
import com.typewritermc.realm.AuthoringCreationHostFilter
import com.typewritermc.realm.AuthoringCreationRelationDirection
import com.typewritermc.realm.AuthoringCreationSlotDefinition
import com.typewritermc.realm.RealmDiscoverySnapshot
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.PresentationId
import com.typewritermc.types.RelationCardinality
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationEndpointDefinition
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeInitializationPlan
import com.typewritermc.types.TypeInitializationRequirementReason
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.ResourceDefinition
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.capability.CommandCapabilityDefinition
import skirout.editor.v1.capability.ComputationCapabilityDefinition
import skirout.editor.v1.capability.SearchCapabilityDefinition
import skirout.editor.v1.catalog.CatalogFetchRequest
import skirout.editor.v1.catalog.CatalogFetchResult
import skirout.editor.v1.catalog.CatalogWatchUpdate
import skirout.editor.v1.catalog.InitializeTypedValueRequest
import skirout.editor.v1.catalog.InitializeTypedValueResult
import skirout.editor.v1.catalog.SubtypeResult
import skirout.editor.v1.catalog.WatchEditorCatalogRequest
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.TypeDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.authoring.RelationCardinality as SkirRelationCardinality
import skirout.editor.v1.authoring.RelationDefinition as SkirRelationDefinition
import skirout.editor.v1.authoring.RelationDeletePolicy as SkirRelationDeletePolicy
import skirout.editor.v1.authoring.RelationEndpointDefinition as SkirRelationEndpointDefinition
import skirout.editor.v1.authoring.RelationEndpointSide as SkirRelationEndpointSide
import skirout.editor.v1.authoring.RelationId as SkirRelationId
import skirout.editor.v1.authoring.ResourceDefinitionId as WireResourceDefinitionId
import skirout.editor.v1.catalog.AuthoringCreationContext as WireAuthoringCreationContext
import skirout.editor.v1.catalog.AuthoringCreationHostCardinality as WireAuthoringCreationHostCardinality
import skirout.editor.v1.catalog.AuthoringCreationSlotDefinition as WireAuthoringCreationSlotDefinition
import skirout.editor.v1.catalog.AuthoringCreationSlotId as WireAuthoringCreationSlotId
import skirout.editor.v1.catalog.AuthoringSearchDefinition as WireAuthoringSearchDefinition
import skirout.editor.v1.catalog.AuthoringSearchFacetDefinition as WireAuthoringSearchFacetDefinition
import skirout.editor.v1.catalog.TypeInitializationRequirement as WireTypeInitializationRequirement
import skirout.editor.v1.catalog.TypeInitializationRequirementReason as WireTypeInitializationRequirementReason
import skirout.editor.v1.path.DataPath as SkirDataPath
import skirout.editor.v1.path.DataPathSegment as SkirDataPathSegment
import skirout.editor.v1.type_catalog.CapabilityId as SkirCapabilityId

/**
 * Provides editor metadata and initial generation state without owning messaging subscriptions.
 *
 * Callers can request a generation to prevent mixing metadata from different deployments.
 */
interface RealmEditorCatalogSource {
    /**
     * Fetches one complete catalog view from the current discovery snapshot.
     *
     * A supplied expected generation makes the fetch conditional. Implementations must return one generation for
     * every catalog section in a successful result.
     */
    suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult

    /** Returns the generation observed when the catalog watch is created. */
    suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate

    /** Completes a partial typed value through the generation pinned prototype graph. */
    suspend fun initialize(request: InitializeTypedValueRequest): InitializeTypedValueResult
}

/**
 * Builds catalog responses from one captured discovery snapshot.
 *
 * Generation mismatch is explicit. Requested types, editor role types, presentations, and capabilities expand into
 * a dependency closure; conversions are currently returned empty. Unknown definitions are not supplied by loading
 * arbitrary runtime code.
 */
class SnapshotRealmEditorCatalogSource(
    private val prototypes: TypePrototypeRegistry,
    private val snapshot: suspend () -> RealmDiscoverySnapshot?,
) : RealmEditorCatalogSource {
    /** Captures one snapshot, expands its type dependencies, then encodes the result for the editor protocol. */
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult {
        val snapshot = snapshot() ?: return unavailableCatalogFetchResult("Realm discovery snapshot is unavailable")
        val generation = snapshot.discovery.generation.value
        if (request.expectedGeneration?.value != null && request.expectedGeneration?.value != generation) {
            return CatalogFetchResult.createGenerationMismatch(actualGeneration = CatalogGeneration(value = generation))
        }
        val requestedTypes = request.requestedTypes.map { SkirTypeCodec.decode(it).getOrThrow() }
        val subtypeMatches =
            request.subtypeQueries.map { query ->
                val target = SkirTypeCodec.decode(query.target).getOrThrow()
                Triple(query.queryId, target, snapshot.discovery.types.subtypesOf(target))
            }
        val subtypeResults =
            subtypeMatches.map { (queryId, _, matches) ->
                SubtypeResult(
                    queryId = queryId,
                    matchingTypes = matches.map { SkirTypeCodec.encode(it.id).getOrThrow() },
                )
            }
        val resourceDefinitions = snapshot.resourceDefinitions.map { it.toWire() }
        val closure =
            snapshot.closure(
                requestedTypes +
                    snapshot.catalogTypes(prototypes) +
                    resourceDefinitions.mapNotNull { definition ->
                        (SkirTypeCodec.decode(definition.acceptedRoot).getOrThrow() as? TypeExpression.Named)?.reference
                    } +
                    snapshot.compilationProjections.mapNotNull { projection ->
                        (SkirTypeCodec.decode(projection.root).getOrThrow() as? TypeExpression.Named)?.reference
                    } +
                    snapshot.collectionProjections.map { projection ->
                        SkirTypeCodec.decode(projection.rowType).getOrThrow()
                    } +
                    subtypeMatches.flatMap { (_, target, matches) -> listOf(target) + matches.map { it.id } },
                request.presentationIds.map { PresentationId(it.namespace, it.name) },
            )
        val encoded = SkirTypeCodec.encode(closure.types).getOrThrow()
        return CatalogFetchResult.createSuccess(
            generation = CatalogGeneration(value = generation),
            typeDefinitions = encoded.definitions,
            presentationDefinitions = closure.presentations,
            conversions = emptyList(),
            capabilityDefinitions = closure.capabilities.map(RealmCapabilityDescriptor::toWire),
            subtypeResults = subtypeResults,
            diagnostics = snapshot.presentationDiagnostics.map(PresentationDiagnostic::toWire) + closure.diagnostics,
            elementEntries = snapshot.elements.entries.map { it.toSkir(prototypes) },
            pageEntries = snapshot.pages.entries.map { it.toSkir(prototypes) },
            pageDiagnostics = snapshot.pages.diagnostics.map(PageDiagnostic::toSkir),
            resourceDefinitions = resourceDefinitions,
            relationDefinitions = snapshot.relations.map(RelationDefinition::toWire),
            collectionProjectionDefinitions = snapshot.collectionProjections,
            authoringCreationSlots = snapshot.creationSlots.map { it.toWire() },
            authoringSearch = snapshot.authoringSearch?.toWire(),
            authoringCompilationProjections = snapshot.compilationProjections,
        )
    }

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(
            value = snapshot()?.discovery?.generation?.value ?: "unavailable",
        )

    override suspend fun initialize(request: InitializeTypedValueRequest): InitializeTypedValueResult {
        val snapshot = snapshot() ?: return InitializeTypedValueResult.UnavailableWrapper(emptyList())
        val generation = snapshot.discovery.generation.value
        if (request.generation.value != generation) {
            return InitializeTypedValueResult.createGenerationMismatch(
                actualGeneration = CatalogGeneration(value = generation),
            )
        }
        return try {
            val root = SkirTypeCodec.decode(request.rootType).getOrThrow()
            val partial = request.partialValue?.let { SkirDataValueCodec.decode(it).getOrThrow() }
            when (val plan = prototypes.planInitialization(root, partial)) {
                is TypeInitializationPlan.Ready -> {
                    InitializeTypedValueResult.SuccessWrapper(
                        prototypes.initializeConcrete(root, plan.supplied).toWire(),
                    )
                }

                is TypeInitializationPlan.NeedsInput -> {
                    InitializeTypedValueResult.createNeedsInput(
                        rootType = SkirTypeCodec.encode(root).getOrThrow(),
                        suppliedValue = plan.supplied?.let { SkirDataValueCodec.encode(it).getOrThrow() },
                        requirements =
                            plan.requirements.map { requirement ->
                                WireTypeInitializationRequirement(
                                    path = requirement.path.toWirePath(),
                                    expected = SkirTypeCodec.encode(requirement.expected).getOrThrow(),
                                    reason =
                                        when (requirement.reason) {
                                            TypeInitializationRequirementReason.MISSING_VALUE -> {
                                                WireTypeInitializationRequirementReason.MISSING_VALUE
                                            }

                                            TypeInitializationRequirementReason.CONCRETE_TYPE_REQUIRED -> {
                                                WireTypeInitializationRequirementReason.CONCRETE_TYPE_REQUIRED
                                            }
                                        },
                                )
                            },
                    )
                }
            }
        } catch (invalid: IllegalArgumentException) {
            InitializeTypedValueResult.InvalidWrapper(
                listOf(
                    TypeDiagnostic(
                        code = DiagnosticCode.INVALID_VALUE,
                        severity = DiagnosticSeverity.ERROR,
                        message = invalid.message ?: "The partial typed value is invalid.",
                        path = null,
                        relatedType = null,
                        details = emptyList(),
                    ),
                ),
            )
        }
    }
}

private fun com.typewritermc.realm.AuthoringResourceDefinition.toWire(): ResourceDefinition =
    ResourceDefinition(
        id = WireResourceDefinitionId(value = id.value),
        acceptedRoot = SkirTypeCodec.encode(acceptedRoot).getOrThrow(),
    )

private fun com.typewritermc.realm.AuthoringSearchDefinition.toWire(): WireAuthoringSearchDefinition =
    WireAuthoringSearchDefinition(
        definitions = definitions.map { WireResourceDefinitionId(value = it.value) },
        selectors = selectors,
        facets = facets.map { it.toWire() },
    )

private fun com.typewritermc.realm.AuthoringSearchFacetDefinition.toWire(): WireAuthoringSearchFacetDefinition =
    WireAuthoringSearchFacetDefinition(
        id = id,
        label = label,
        selectorId = selectorId,
    )

private fun AuthoringCreationSlotDefinition.toWire(): WireAuthoringCreationSlotDefinition =
    WireAuthoringCreationSlotDefinition(
        id = WireAuthoringCreationSlotId(value = id.value),
        label = label,
        creates = WireResourceDefinitionId(value = creates.value),
        context = context.toWire(),
        concreteRoots = concreteRoots.map { SkirTypeCodec.encode(it).getOrThrow() },
    )

private fun AuthoringCreationContext.toWire(): WireAuthoringCreationContext =
    when (this) {
        AuthoringCreationContext.Standalone -> {
            WireAuthoringCreationContext.createStandalone()
        }

        is AuthoringCreationContext.DeclaredRelation -> {
            WireAuthoringCreationContext.createDeclaredRelation(
                hosts = hosts.toWire(),
                cardinality = cardinality.toWire(),
                relation = SkirRelationId(value = relation.value),
                direction = direction.toWire(),
            )
        }

        is AuthoringCreationContext.ReferencePath -> {
            WireAuthoringCreationContext.createReferencePath(
                hosts = hosts.toWire(),
                cardinality = cardinality.toWire(),
                path = path.toWirePath(),
            )
        }
    }

private fun AuthoringCreationHostFilter.toWire(): skirout.editor.v1.authoring.ResourceFilter =
    skirout.editor.v1.authoring.ResourceFilter(
        definitions = definitions.map { WireResourceDefinitionId(value = it.value) },
        assignableTo = assignableTo?.let { SkirTypeCodec.encode(it).getOrThrow() },
    )

private fun AuthoringCreationHostCardinality.toWire(): WireAuthoringCreationHostCardinality =
    when (this) {
        AuthoringCreationHostCardinality.EXACTLY_ONE -> WireAuthoringCreationHostCardinality.EXACTLY_ONE
        AuthoringCreationHostCardinality.ONE_OR_MORE -> WireAuthoringCreationHostCardinality.ONE_OR_MORE
    }

private fun AuthoringCreationRelationDirection.toWire(): skirout.editor.v1.authoring.RelationDirection =
    when (this) {
        AuthoringCreationRelationDirection.OUTGOING -> skirout.editor.v1.authoring.RelationDirection.OUTGOING
        AuthoringCreationRelationDirection.INCOMING -> skirout.editor.v1.authoring.RelationDirection.INCOMING
        AuthoringCreationRelationDirection.BOTH -> skirout.editor.v1.authoring.RelationDirection.BOTH
    }

private fun RelationDefinition.toWire(): SkirRelationDefinition =
    SkirRelationDefinition(
        id = SkirRelationId(value = id.value),
        source = SkirTypeCodec.encode(source).getOrThrow(),
        target = SkirTypeCodec.encode(target).getOrThrow(),
        onSourceDelete = onSourceDelete.toWire(),
        onTargetDelete = onTargetDelete.toWire(),
        sourceEndpoint = sourceEndpoint?.toWire(),
        targetEndpoint = targetEndpoint?.toWire(),
    )

private fun RelationEndpointDefinition.toWire(): SkirRelationEndpointDefinition =
    SkirRelationEndpointDefinition(
        owner = SkirTypeCodec.encode(owner).getOrThrow(),
        path = path.toWirePath(),
        side =
            when (side) {
                RelationEndpointSide.SOURCE -> SkirRelationEndpointSide.SOURCE
                RelationEndpointSide.TARGET -> SkirRelationEndpointSide.TARGET
            },
        cardinality =
            when (cardinality) {
                RelationCardinality.ONE -> SkirRelationCardinality.ONE
                RelationCardinality.MANY -> SkirRelationCardinality.MANY
            },
    )

private fun RelationDeletePolicy.toWire(): SkirRelationDeletePolicy =
    when (this) {
        RelationDeletePolicy.RESTRICT -> SkirRelationDeletePolicy.RESTRICT
        RelationDeletePolicy.CASCADE -> SkirRelationDeletePolicy.CASCADE
        RelationDeletePolicy.CLEAR -> SkirRelationDeletePolicy.CLEAR
    }

private fun RealmDiscoverySnapshot.catalogTypes(prototypes: TypePrototypeRegistry): List<ResolvedTypeRef> =
    elements.entries.map { it.descriptor.type } +
        listOf(
            prototypes.require(ResourceTypeDescriptor::class).type,
            prototypes.require(ResolvedTypeRef::class).type,
        ) +
        pages.entries.flatMap { entry ->
            listOf(entry.presentationTarget) +
                when (val editor = entry.descriptor.editor) {
                    is ResolvedPageEditorDefinition.Graph -> editor.nodes
                    is ResolvedPageEditorDefinition.Timeline -> editor.tracks + editor.segments + editor.keyframes
                }
        }

private data class RealmEditorCatalogClosure(
    val types: TypeCatalog,
    val presentations: List<skirout.editor.v1.presentation.PresentationDefinition>,
    val capabilities: List<RealmCapabilityDescriptor>,
    val diagnostics: List<TypeDiagnostic>,
)

private fun RealmDiscoverySnapshot.closure(
    requestedTypes: List<ResolvedTypeRef>,
    requestedPresentations: List<PresentationId>,
): RealmEditorCatalogClosure {
    val discoveryCollector = TypeClosureCollector(discovery.types)
    requestedTypes.forEach(discoveryCollector::includeReference)
    val presentationsById =
        presentations.associateBy { PresentationId(it.presentationId.namespace, it.presentationId.name) }
    val capabilitiesById = capabilities.associateBy(RealmCapabilityDescriptor::id)
    val presentationIds = requestedPresentations.toMutableSet()
    val capabilityIds = mutableSetOf<CapabilityId>()
    var previousTypeCount = -1
    var previousPresentationCount = -1
    var previousCapabilityCount = -1
    while (
        previousTypeCount != discoveryCollector.definitions.size ||
        previousPresentationCount != presentationIds.size ||
        previousCapabilityCount != capabilityIds.size
    ) {
        previousTypeCount = discoveryCollector.definitions.size
        previousPresentationCount = presentationIds.size
        previousCapabilityCount = capabilityIds.size
        presentationIds.apply {
            discoveryCollector.definitions.forEach { definition ->
                definition.defaultPresentationId?.let(::add)
                addAll(definition.namedPresentations.values)
                addAll(definition.rolePresentations.values)
            }
        }
        presentationIds.mapNotNull(presentationsById::get).forEach { presentation ->
            presentation.inputs.forEach { discoveryCollector.includeExpression(SkirTypeCodec.decode(it.valueType).getOrThrow()) }
            presentation.dependencies.types.forEach { discoveryCollector.includeReference(SkirTypeCodec.decode(it).getOrThrow()) }
            presentation.dependencies.collections.forEach { collection ->
                discoveryCollector.includeExpression(SkirTypeCodec.decode(collection.rowType).getOrThrow())
                discoveryCollector.includeExpression(SkirTypeCodec.decode(collection.key.resultType).getOrThrow())
                discoveryCollector.includeExpression(SkirTypeCodec.decode(collection.selectability.resultType).getOrThrow())
                collection.relations.forEach { relation ->
                    discoveryCollector.includeExpression(SkirTypeCodec.decode(relation.targets.resultType).getOrThrow())
                }
            }
            presentation.dependencies.presentations.forEach { presentationIds += PresentationId(it.namespace, it.name) }
            presentation.dependencies.capabilities.forEach { capabilityIds += CapabilityId(it.value) }
        }
        capabilityIds.mapNotNull(capabilitiesById::get).forEach { capability ->
            discoveryCollector.includeReference(capability.requestType)
            when (capability) {
                is RealmCapabilityDescriptor.Search -> discoveryCollector.includeReference(capability.resultType)
                is RealmCapabilityDescriptor.Computation -> discoveryCollector.includeReference(capability.resultType)
                is RealmCapabilityDescriptor.Command -> Unit
            }
        }
    }

    val diagnostics = mutableListOf<TypeDiagnostic>()
    val validity = mutableMapOf<PresentationId, Boolean>()

    fun validatePresentation(
        id: PresentationId,
        visiting: Set<PresentationId> = emptySet(),
    ): Boolean {
        validity[id]?.let { return it }
        if (id in visiting) return true
        val presentation = presentationsById[id]
        if (presentation == null) {
            diagnostics += closureDiagnostic("Presentation dependency ${id.namespace}/${id.name} is unavailable")
            validity[id] = false
            return false
        }
        var valid = true
        presentation.inputs.forEach { input ->
            val type = SkirTypeCodec.decode(input.valueType).getOrThrow()
            if (!discoveryCollector.canIncludeExpression(type)) {
                diagnostics += closureDiagnostic("Presentation ${id.namespace}/${id.name} has unavailable input type $type")
                valid = false
            }
        }
        presentation.dependencies.types.forEach { encoded ->
            val type = SkirTypeCodec.decode(encoded).getOrThrow()
            if (!discoveryCollector.canInclude(type)) {
                diagnostics += closureDiagnostic("Presentation ${id.namespace}/${id.name} requires unavailable type $type")
                valid = false
            }
        }
        presentation.dependencies.collections.forEach { collection ->
            val types =
                buildList {
                    add(SkirTypeCodec.decode(collection.rowType).getOrThrow())
                    add(SkirTypeCodec.decode(collection.key.resultType).getOrThrow())
                    add(SkirTypeCodec.decode(collection.selectability.resultType).getOrThrow())
                    collection.relations.forEach { relation ->
                        add(SkirTypeCodec.decode(relation.targets.resultType).getOrThrow())
                    }
                }
            types.filterNot(discoveryCollector::canIncludeExpression).forEach { type ->
                diagnostics +=
                    closureDiagnostic(
                        "Presentation ${id.namespace}/${id.name} collection ${collection.sourceId} requires unavailable type $type",
                    )
                valid = false
            }
        }
        presentation.dependencies.capabilities.forEach { encoded ->
            val capability = capabilitiesById[CapabilityId(encoded.value)]
            if (capability == null) {
                diagnostics +=
                    closureDiagnostic(
                        "Presentation ${id.namespace}/${id.name} requires unavailable capability ${encoded.value}",
                    )
                valid = false
            } else {
                val referencedTypes =
                    when (capability) {
                        is RealmCapabilityDescriptor.Search -> listOf(capability.requestType, capability.resultType)
                        is RealmCapabilityDescriptor.Computation -> listOf(capability.requestType, capability.resultType)
                        is RealmCapabilityDescriptor.Command -> listOf(capability.requestType)
                    }
                referencedTypes.filterNot(discoveryCollector::canInclude).forEach { type ->
                    diagnostics +=
                        closureDiagnostic(
                            "Capability ${encoded.value} requires unavailable type $type",
                        )
                    valid = false
                }
            }
        }
        presentation.dependencies.presentations.forEach { encoded ->
            val dependency = PresentationId(encoded.namespace, encoded.name)
            if (!validatePresentation(dependency, visiting + id)) valid = false
        }
        validity[id] = valid
        return valid
    }

    val validPresentationIds = presentationIds.filter(::validatePresentation).toSet()
    val validCapabilityIds =
        validPresentationIds
            .mapNotNull(presentationsById::get)
            .flatMap { presentation -> presentation.dependencies.capabilities.map { CapabilityId(it.value) } }
            .toSet()
    val finalCollector = TypeClosureCollector(discovery.types)
    requestedTypes.forEach(finalCollector::includeReference)
    validPresentationIds.mapNotNull(presentationsById::get).forEach { presentation ->
        presentation.inputs.forEach { finalCollector.includeExpression(SkirTypeCodec.decode(it.valueType).getOrThrow()) }
        presentation.dependencies.types.forEach { finalCollector.includeReference(SkirTypeCodec.decode(it).getOrThrow()) }
        presentation.dependencies.collections.forEach { collection ->
            finalCollector.includeExpression(SkirTypeCodec.decode(collection.rowType).getOrThrow())
            finalCollector.includeExpression(SkirTypeCodec.decode(collection.key.resultType).getOrThrow())
            finalCollector.includeExpression(SkirTypeCodec.decode(collection.selectability.resultType).getOrThrow())
            collection.relations.forEach { relation ->
                finalCollector.includeExpression(SkirTypeCodec.decode(relation.targets.resultType).getOrThrow())
            }
        }
    }
    validCapabilityIds.mapNotNull(capabilitiesById::get).forEach { capability ->
        finalCollector.includeReference(capability.requestType)
        when (capability) {
            is RealmCapabilityDescriptor.Search -> finalCollector.includeReference(capability.resultType)
            is RealmCapabilityDescriptor.Computation -> finalCollector.includeReference(capability.resultType)
            is RealmCapabilityDescriptor.Command -> Unit
        }
    }
    return RealmEditorCatalogClosure(
        types = TypeCatalog(finalCollector.definitions),
        presentations = validPresentationIds.mapNotNull(presentationsById::get),
        capabilities = validCapabilityIds.mapNotNull(capabilitiesById::get),
        diagnostics = diagnostics.distinct(),
    )
}

private fun closureDiagnostic(message: String): TypeDiagnostic =
    TypeDiagnostic(
        code = DiagnosticCode.INVALID_PRESENTATION,
        severity = DiagnosticSeverity.WARNING,
        message = message,
        path = null,
        relatedType = null,
        details = emptyList(),
    )

private fun RealmCapabilityDescriptor.toWire(): CapabilityDefinition =
    when (this) {
        is RealmCapabilityDescriptor.Search -> {
            CapabilityDefinition.SearchWrapper(
                SearchCapabilityDefinition(
                    capabilityId = SkirCapabilityId(value = id.value),
                    requestType = SkirTypeCodec.encode(requestType).getOrThrow(),
                    resultType = SkirTypeCodec.encode(resultType).getOrThrow(),
                ),
            )
        }

        is RealmCapabilityDescriptor.Computation -> {
            CapabilityDefinition.ComputationWrapper(
                ComputationCapabilityDefinition(
                    capabilityId = SkirCapabilityId(value = id.value),
                    requestType = SkirTypeCodec.encode(requestType).getOrThrow(),
                    resultType = SkirTypeCodec.encode(resultType).getOrThrow(),
                ),
            )
        }

        is RealmCapabilityDescriptor.Command -> {
            CapabilityDefinition.CommandWrapper(
                CommandCapabilityDefinition(
                    capabilityId = SkirCapabilityId(value = id.value),
                    requestType = SkirTypeCodec.encode(requestType).getOrThrow(),
                ),
            )
        }
    }

private class TypeClosureCollector(
    private val catalog: TypeCatalog,
) {
    private val definitionsById = catalog.definitions.associateBy { it.id }
    private val included = linkedMapOf<ResolvedTypeRef, TypeDefinition>()

    val definitions: List<TypeDefinition>
        get() = included.values.toList()

    fun canInclude(reference: ResolvedTypeRef): Boolean =
        reference.arguments.all(::canIncludeExpression) && definitionsById.containsKey(reference.copy(arguments = emptyList()))

    fun canIncludeExpression(expression: TypeExpression): Boolean =
        when (expression) {
            TypeExpression.Any,
            TypeExpression.Boolean,
            TypeExpression.Unit,
            is TypeExpression.Bytes,
            is TypeExpression.Decimal,
            is TypeExpression.Duration,
            is TypeExpression.Float,
            is TypeExpression.Integer,
            is TypeExpression.Parameter,
            is TypeExpression.StringType,
            is TypeExpression.Timestamp,
            -> true

            is TypeExpression.Enumeration -> canIncludeExpression(expression.valueType)

            is TypeExpression.ListType -> canIncludeExpression(expression.element)

            is TypeExpression.MapType -> canIncludeExpression(expression.key) && canIncludeExpression(expression.value)

            is TypeExpression.Record -> expression.fields.all { canIncludeExpression(it.type) }

            is TypeExpression.Named -> canInclude(expression.reference)

            is TypeExpression.Reference -> canInclude(expression.target)
        }

    fun includeReference(reference: ResolvedTypeRef) {
        reference.arguments.forEach(::includeExpression)
        definitionsById[reference.copy(arguments = emptyList())]?.let(::includeDefinition)
    }

    fun includeExpression(expression: TypeExpression) {
        when (expression) {
            TypeExpression.Any,
            TypeExpression.Boolean,
            TypeExpression.Unit,
            is TypeExpression.Bytes,
            is TypeExpression.Decimal,
            is TypeExpression.Duration,
            is TypeExpression.Float,
            is TypeExpression.Integer,
            is TypeExpression.Parameter,
            is TypeExpression.StringType,
            is TypeExpression.Timestamp,
            -> {
                return
            }

            is TypeExpression.Enumeration -> {
                includeExpression(expression.valueType)
            }

            is TypeExpression.ListType -> {
                includeExpression(expression.element)
            }

            is TypeExpression.MapType -> {
                includeExpression(expression.key)
                includeExpression(expression.value)
            }

            is TypeExpression.Record -> {
                expression.fields.forEach { includeExpression(it.type) }
            }

            is TypeExpression.Named -> {
                includeReference(expression.reference)
            }

            is TypeExpression.Reference -> {
                includeReference(expression.target)
            }
        }
    }

    private fun includeDefinition(definition: TypeDefinition) {
        if (included.putIfAbsent(definition.id, definition) != null) return
        includeExpression(definition.representation)
        definition.parameters.flatMap { it.upperBounds }.forEach(::includeExpression)
        definition.parents.forEach(::includeReference)
        if (definition.kind != NominalTypeKind.CONCRETE) {
            catalog.subtypesOf(definition.id).forEach(::includeDefinition)
        }
    }
}

class UnavailableRealmEditorCatalogSource : RealmEditorCatalogSource {
    override suspend fun fetch(request: CatalogFetchRequest): CatalogFetchResult =
        CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic()))

    override suspend fun initialGeneration(request: WatchEditorCatalogRequest): CatalogWatchUpdate =
        CatalogWatchUpdate.createInitial(value = "unavailable")

    override suspend fun initialize(request: InitializeTypedValueRequest): InitializeTypedValueResult =
        InitializeTypedValueResult.UnavailableWrapper(listOf(unavailableDiagnostic()))
}

internal fun unavailableCatalogFetchResult(message: String): CatalogFetchResult =
    CatalogFetchResult.UnavailableWrapper(listOf(unavailableDiagnostic(message)))

private fun unavailableDiagnostic(message: String = "Realm editor catalog source is unavailable"): TypeDiagnostic =
    TypeDiagnostic(
        code = DiagnosticCode.INVALID_PRESENTATION,
        severity = DiagnosticSeverity.ERROR,
        message = message,
        path = null,
        relatedType = null,
        details = emptyList(),
    )

private fun PresentationDiagnostic.toWire(): TypeDiagnostic =
    TypeDiagnostic(
        code = DiagnosticCode.INVALID_PRESENTATION,
        severity = DiagnosticSeverity.WARNING,
        message =
            buildString {
                append(message)
                namespace?.let { append(" Namespace: $it.") }
                sourcePart?.let { append(" Source part: $it.") }
                presentationName?.let { append(" Presentation: $it.") }
            },
        path = null,
        relatedType = null,
        details = emptyList(),
    )
