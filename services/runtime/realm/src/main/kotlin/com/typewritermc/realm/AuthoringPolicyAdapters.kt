package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringChangeSummary
import com.typewritermc.authoring.AuthoringGraphRelation
import com.typewritermc.authoring.AuthoringGraphResource
import com.typewritermc.authoring.AuthoringPolicyCatalog
import com.typewritermc.authoring.AuthoringPolicyProvider
import com.typewritermc.authoring.AuthoringRelationOrigin
import com.typewritermc.authoring.AuthoringSearchFacet
import com.typewritermc.authoring.AuthoringSearchSelector
import com.typewritermc.authoring.AuthoringSearchSelectorMultiplicity
import com.typewritermc.authoring.AuthoringSearchSelectorValues
import com.typewritermc.authoring.AuthoringWorkingGraph
import com.typewritermc.authoring.GraphReadRequirement
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.ContentDigest
import com.typewritermc.realm.compiler.AuthoringCompilationProjection
import com.typewritermc.realm.compiler.AuthoringCompilationProjectionRegistry
import com.typewritermc.realm.repository.AuthoringGraphDelta
import com.typewritermc.realm.repository.AuthoringGraphRule
import com.typewritermc.realm.repository.AuthoringGraphValidationContext
import com.typewritermc.realm.repository.AuthoringMutationPlan
import com.typewritermc.realm.repository.PolicyGraphSliceResult
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.realm.repository.isAssignable
import com.typewritermc.realm.repository.sliceForPolicy
import com.typewritermc.realm.routes.AuthoringPresentationRegistry
import com.typewritermc.realm.search.AuthoringSearchGraph
import com.typewritermc.realm.search.AuthoringSearchProjectionRegistry
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypedValueEnvelope
import skirout.editor.v1.binding.BindingId
import skirout.editor.v1.presentation.SearchSelectorDefinition
import skirout.editor.v1.presentation.SearchSelectorMultiplicity
import skirout.editor.v1.presentation.SearchSelectorValues
import com.typewritermc.realm.compiler.GraphReadRequirement as RealmGraphReadRequirement
import com.typewritermc.realm.repository.AuthoringGraphResource as RealmGraphResource
import com.typewritermc.realm.repository.AuthoringWorkingGraph as RealmWorkingGraph
import com.typewritermc.realm.routes.AuthoringPresentationProjection as RealmPresentationProjection
import com.typewritermc.realm.search.AuthoringSearchProjection as RealmSearchProjection

/** The policy set consumed by Realm after public SDK policies are adapted to runtime storage types. */
internal data class RealmAuthoringPolicyCatalog(
    val definitions: List<AuthoringResourceDefinition>,
    val validations: List<AuthoringGraphRule>,
    val search: AuthoringSearchProjectionRegistry,
    val searchSelectors: List<AuthoringSearchSelector>,
    val searchFacets: List<AuthoringSearchFacet>,
    val presentations: AuthoringPresentationRegistry,
    val compilation: AuthoringCompilationProjectionRegistry,
)

/** Assembles extension policies once, then exposes only Realm owned policy implementations internally. */
internal object RealmAuthoringPolicyAssembler {
    fun assemble(
        providers: Collection<AuthoringPolicyProvider>,
        catalog: TypeCatalog,
        relations: Collection<RelationDefinition> = emptyList(),
    ): RealmAuthoringPolicyCatalog {
        val policies = AuthoringPolicyCatalog.assemble(providers)
        policies.validateTypeRoots(catalog, relations)
        return RealmAuthoringPolicyCatalog(
            definitions = policies.definitions.values.map { it.toRealm() },
            validations = policies.validations.values.map { it.toRealm(catalog, relations) },
            search =
                AuthoringSearchProjectionRegistry(
                    policies.search.values.map { projection ->
                        toRealmSearch(
                            projection,
                            policies.searchSelectors.mapTo(linkedSetOf(), AuthoringSearchSelector::id),
                            relations,
                        )
                    },
                ),
            searchSelectors = policies.searchSelectors,
            searchFacets = policies.searchFacets,
            presentations =
                AuthoringPresentationRegistry(
                    policies.presentations.values.associate { it.resourceDefinition to toRealmPresentation(it, relations) },
                ),
            compilation =
                AuthoringCompilationProjectionRegistry(
                    policies.compilation.values.map { projection ->
                        projection.toRealmCompilation(
                            definitions = policies.definitions.values,
                            catalog = catalog,
                            relations = relations,
                        )
                    },
                ),
        )
    }

    private fun AuthoringPolicyCatalog.validateTypeRoots(
        catalog: TypeCatalog,
        relations: Collection<RelationDefinition>,
    ) {
        val relationIds = relations.mapTo(linkedSetOf(), RelationDefinition::id)
        definitions.values.forEach { definition ->
            catalog.requireKnownRoot(definition.acceptedRoot, "resource definition ${definition.id.value}")
        }
        val graphRelations =
            (
                validations.values.map(com.typewritermc.authoring.AuthoringValidationRule::graphRequirement) +
                    search.values.map(com.typewritermc.authoring.AuthoringSearchProjection::graphRequirement) +
                    presentations.values.map(com.typewritermc.authoring.AuthoringPresentationProjection::graphRequirement) +
                    compilation.values.map(com.typewritermc.authoring.AuthoringCompilationProjection::graphRequirement)
            ).flatMapTo(linkedSetOf()) { it.declaredRelations }
        require(graphRelations.all { it in relationIds }) {
            "Graph requirements reference unknown relations: ${(graphRelations - relationIds).sortedBy { it.value }}."
        }
        compilation.values.forEach { projection ->
            catalog.requireKnownRoot(projection.root, "compilation projection ${projection.id.value}")
            require(definitions.values.any { definition -> catalog.isAssignable(projection.root, definition.acceptedRoot) }) {
                "Compilation projection ${projection.id.value} does not target a registered resource definition."
            }
        }
    }
}

private fun TypeCatalog.requireKnownRoot(
    expression: TypeExpression,
    owner: String,
): com.typewritermc.types.TypeDefinition? =
    when (expression) {
        is TypeExpression.Named -> requireKnownRoot(expression.reference, owner)
        else -> error("$owner must use a named type root, but found $expression.")
    }

private fun TypeCatalog.requireKnownRoot(
    reference: com.typewritermc.types.ResolvedTypeRef,
    owner: String,
): com.typewritermc.types.TypeDefinition {
    val definition = definitions.singleOrNull { it.id == reference.copy(arguments = emptyList()) }
    require(definition != null) {
        "$owner references type root $reference, but the type is absent from the TypeCatalog."
    }
    return definition
}

internal fun RealmAuthoringPolicyCatalog.searchDefinition(): AuthoringSearchDefinition =
    AuthoringSearchDefinition(
        definitions = search.all().map(RealmSearchProjection::definition),
        selectors =
            searchSelectors.map { selector ->
                SearchSelectorDefinition(
                    selectorId = selector.id.value,
                    key = selector.key,
                    valueBindingId = BindingId(value = 0),
                    values =
                        when (val values = selector.values) {
                            AuthoringSearchSelectorValues.FreeText -> {
                                SearchSelectorValues.FREE_TEXT
                            }

                            is AuthoringSearchSelectorValues.Enumeration -> {
                                SearchSelectorValues.createEnumeration(values = values.values)
                            }
                        },
                    caseSensitive = selector.caseSensitive,
                    multiplicity =
                        when (selector.multiplicity) {
                            AuthoringSearchSelectorMultiplicity.SINGLE -> SearchSelectorMultiplicity.SINGLE
                            AuthoringSearchSelectorMultiplicity.MULTIPLE -> SearchSelectorMultiplicity.MULTIPLE
                        },
                    color = selector.colorValue,
                )
            },
        facets =
            searchFacets.map { facet ->
                AuthoringSearchFacetDefinition(facet.id, facet.label, facet.selectorId.value)
            },
    )

private fun com.typewritermc.authoring.AuthoringResourceDefinition.toRealm(): AuthoringResourceDefinition =
    AuthoringResourceDefinition(id, acceptedRoot, navigationHandler)

private fun com.typewritermc.authoring.AuthoringValidationRule.toRealm(
    catalog: TypeCatalog,
    relations: Collection<RelationDefinition>,
): AuthoringGraphRule =
    object : AuthoringGraphRule {
        override val id: String = this@toRealm.id.value
        override val graphRequirement: RealmGraphReadRequirement = this@toRealm.graphRequirement.toRealm(relations)

        override fun validate(context: AuthoringGraphValidationContext): List<com.typewritermc.realm.repository.AuthoringDiagnostic> {
            val change =
                AuthoringChangeSummary(
                    changedResources = context.changedResources,
                    changedEdges = context.changedEdges,
                    deletedResources = context.deletedResources,
                )
            return this@toRealm
                .validate(
                    com.typewritermc.authoring.AuthoringValidationContext(
                        catalog = catalog,
                        before = context.before.toPublic(),
                        proposed = context.proposed.toPublic(),
                        change = change,
                    ),
                ).map { diagnostic ->
                    com.typewritermc.realm.repository.AuthoringDiagnostic(
                        code = diagnostic.code,
                        message = diagnostic.message,
                        resource = diagnostic.resources.firstOrNull(),
                    )
                }
        }
    }

private fun toRealmSearch(
    projection: com.typewritermc.authoring.AuthoringSearchProjection,
    selectors: Set<SearchSelectorId>,
    relations: Collection<RelationDefinition>,
): RealmSearchProjection =
    object : RealmSearchProjection {
        override val definition: ResourceDefinitionId = projection.resourceDefinition
        override val graphRequirement: RealmGraphReadRequirement = projection.graphRequirement.toRealm(relations)

        override fun project(
            resource: RealmGraphResource,
            graph: AuthoringSearchGraph,
        ): com.typewritermc.realm.search.AuthoringSearchDocument {
            val document = projection.project(resource.toPublic(), graph.toPublic())
            require(document.resource == resource.id) {
                "Search projection ${projection.resourceDefinition.value} returned resource ${document.resource} " +
                    "while projecting ${resource.id}."
            }
            require(document.definition == projection.resourceDefinition && document.definition == resource.definition) {
                "Search projection ${projection.resourceDefinition.value} returned definition ${document.definition.value} " +
                    "while projecting ${resource.definition.value}."
            }
            require(document.selectors.keys.all { it in selectors }) {
                "Search projection ${projection.resourceDefinition.value} returned unregistered selectors: " +
                    document.selectors.keys
                        .filterNot { it in selectors }
                        .map(SearchSelectorId::value) + "."
            }
            return com.typewritermc.realm.search.AuthoringSearchDocument(
                resource = document.resource,
                definition = document.definition,
                text = listOf(document.text),
                selectors = document.selectors.mapKeys { it.key.value },
                ownerPath = document.ownerPath,
            )
        }

        override fun affectedResources(plan: AuthoringMutationPlan): Set<ResourceId> =
            plan.policyGraphs(graphRequirement).let { (before, proposed) ->
                projection.affectedResources(
                    change = plan.changeSummary(),
                    before = before.toPublic(),
                    proposed = proposed.toPublic(),
                )
            }
    }

private fun toRealmPresentation(
    projection: com.typewritermc.authoring.AuthoringPresentationProjection,
    relations: Collection<RelationDefinition>,
): RealmPresentationProjection =
    object : RealmPresentationProjection {
        override val graphRequirement: RealmGraphReadRequirement = projection.graphRequirement.toRealm(relations)

        override fun project(
            resource: RealmGraphResource,
            graph: RealmWorkingGraph,
        ) = projection.project(resource = resource.toPublic(), graph = graph.toPublic()).also { subject ->
            require(subject.resource == resource.id) {
                "Presentation projection ${projection.resourceDefinition.value} returned resource ${subject.resource} " +
                    "while projecting ${resource.id}."
            }
            require(subject.definition == projection.resourceDefinition && subject.definition == resource.definition) {
                "Presentation projection ${projection.resourceDefinition.value} returned definition ${subject.definition.value} " +
                    "while projecting ${resource.definition.value}."
            }
        }

        override fun affectedResources(
            change: AuthoringChangeSummary,
            before: RealmWorkingGraph,
            proposed: RealmWorkingGraph,
        ): Set<ResourceId> =
            projection.affectedResources(
                change = change,
                before = before.toPublic(),
                proposed = proposed.toPublic(),
            )
    }

private fun com.typewritermc.authoring.AuthoringCompilationProjection.toRealmCompilation(
    definitions: Collection<com.typewritermc.authoring.AuthoringResourceDefinition>,
    catalog: TypeCatalog,
    relations: Collection<RelationDefinition>,
): AuthoringCompilationProjection {
    val rootDefinitions =
        definitions
            .filter { definition -> catalog.isAssignable(root, definition.acceptedRoot) }
            .mapTo(linkedSetOf(), com.typewritermc.authoring.AuthoringResourceDefinition::id)
    return object : AuthoringCompilationProjection {
        override val id: CompilationProjectionId = CompilationProjectionId(this@toRealmCompilation.id.value)
        override val root: TypeExpression = this@toRealmCompilation.root
        override val graphRequirement: RealmGraphReadRequirement =
            this@toRealmCompilation.graphRequirement.toRealm(relations).copy(
                definitions = this@toRealmCompilation.graphRequirement.definitions + rootDefinitions,
            )

        override fun roots(graph: RealmWorkingGraph): Set<ResourceId> =
            graph.resources.values
                .filter { resource -> catalog.isAssignable(TypeExpression.Named(resource.root), root) }
                .mapTo(linkedSetOf(), StoredTypedResource::id)

        override fun affectedRoots(
            change: AuthoringGraphDelta,
            before: RealmWorkingGraph,
            proposed: RealmWorkingGraph,
        ): Set<ResourceId> =
            this@toRealmCompilation.affectedRoots(
                change = change.toSummary(),
                before = before.toPublic(),
                proposed = proposed.toPublic(),
            )

        override suspend fun compile(
            root: ResourceId,
            graph: RealmWorkingGraph,
        ): CompilationResult =
            this@toRealmCompilation.compile(root, graph.toPublic()).toRealm().also { result ->
                val expected = com.typewritermc.engine.CompilationRoot(id, root)
                require(result.root == expected) {
                    "Compilation projection ${id.value} returned root ${result.root} while compiling $expected."
                }
            }
    }
}

private fun GraphReadRequirement.toRealm(relations: Collection<RelationDefinition>): RealmGraphReadRequirement =
    RealmGraphReadRequirement(
        definitions = definitions,
        relations = declaredRelations + relations.filter { it.families.any(relationFamilies::contains) }.map(RelationDefinition::id),
        incomingReferences = incomingReferences,
        outgoingReferences = outgoingReferences,
        includeIncidentEdges = includeIncidentEdges,
        direction =
            when (direction) {
                GraphReadRequirement.Direction.OUTGOING -> RealmGraphReadRequirement.Direction.OUTGOING
                GraphReadRequirement.Direction.INCOMING -> RealmGraphReadRequirement.Direction.INCOMING
                GraphReadRequirement.Direction.BOTH -> RealmGraphReadRequirement.Direction.BOTH
            },
        maximumDepth = maximumDepth,
        maximumResources = maximumResources,
        maximumEdges = maximumEdges,
    )

private fun AuthoringWorkingGraph.toSearchGraph(): AuthoringSearchGraph =
    AuthoringSearchGraph(
        resources = resources.mapValues { (_, resource) -> resource.toRealm() },
        relations = relations.values.map { relation -> relation.toRealm() },
    )

private fun AuthoringSearchGraph.toPublic(): AuthoringWorkingGraph =
    AuthoringWorkingGraph(
        resources = resources.mapValues { (_, resource) -> resource.toPublic() },
        relations = relations.associateBy(StoredResourceRelation::id).mapValues { (_, relation) -> relation.toPublic() },
    )

private fun RealmGraphResource.toPublic(): AuthoringGraphResource =
    AuthoringGraphResource(id = id, definition = definition, content = content)

private fun AuthoringGraphResource.toRealm(): RealmGraphResource = RealmGraphResource(id, definition, content)

private fun StoredTypedResource.toPublic(): AuthoringGraphResource =
    AuthoringGraphResource(
        id = id,
        definition = definition,
        content = TypedValueEnvelope(TypeExpression.Named(root), valueWithSlots),
    )

private fun StoredResourceRelation.toPublic(): AuthoringGraphRelation =
    AuthoringGraphRelation(
        id = id,
        source = source,
        target = target,
        origin =
            when (val relationOrigin = origin) {
                is ResourceRelationOrigin.Reference -> {
                    AuthoringRelationOrigin.Reference(
                        slot = relationOrigin.slot.value,
                        sourcePath = relationOrigin.sourcePath,
                        expectedTarget = relationOrigin.expectedTarget,
                    )
                }

                is ResourceRelationOrigin.Declared -> {
                    AuthoringRelationOrigin.Declared(
                        relationOrigin.relationId,
                        relationOrigin.sourceIndex,
                        relationOrigin.targetIndex,
                    )
                }
            },
    )

private fun AuthoringGraphRelation.toRealm(): StoredResourceRelation =
    StoredResourceRelation(
        id = id,
        source = source,
        target = target,
        origin =
            when (val relationOrigin = origin) {
                is AuthoringRelationOrigin.Reference -> {
                    ResourceRelationOrigin.Reference(
                        slot = com.typewritermc.elements.ReferenceSlotId(relationOrigin.slot),
                        sourcePath = relationOrigin.sourcePath,
                        expectedTarget = relationOrigin.expectedTarget,
                    )
                }

                is AuthoringRelationOrigin.Declared -> {
                    ResourceRelationOrigin.Declared(
                        relationOrigin.relationId,
                        relationOrigin.sourceIndex,
                        relationOrigin.targetIndex,
                    )
                }
            },
    )

private fun RealmWorkingGraph.toPublic(): AuthoringWorkingGraph =
    AuthoringWorkingGraph(
        resources = resources.mapValues { (_, resource) -> resource.toPublic() },
        relations = relations.mapValues { (_, relation) -> relation.toPublic() },
    )

private fun AuthoringMutationPlan.changeSummary(): AuthoringChangeSummary =
    AuthoringChangeSummary(
        changedResources = changedResources,
        changedEdges = changedEdges,
        deletedResources = delta.resourceRemovals,
    )

private fun AuthoringMutationPlan.policyGraphs(requirement: RealmGraphReadRequirement): Pair<RealmWorkingGraph, RealmWorkingGraph> {
    val roots =
        buildSet {
            addAll(changedResources)
            changedEdges.forEach { edgeId ->
                listOfNotNull(before.relations[edgeId], proposed.relations[edgeId]).forEach { relation ->
                    add(relation.source)
                    add(relation.target)
                }
            }
        }
    return before.requirePolicySlice(roots, requirement) to proposed.requirePolicySlice(roots, requirement)
}

private fun RealmWorkingGraph.requirePolicySlice(
    roots: Set<ResourceId>,
    requirement: RealmGraphReadRequirement,
): RealmWorkingGraph =
    when (val result = sliceForPolicy(roots, requirement)) {
        is PolicyGraphSliceResult.Success -> {
            result.graph
        }

        is PolicyGraphSliceResult.LimitExceeded -> {
            error("Authoring policy exceeded its graph ${result.dimension} limit ${result.limit}.")
        }
    }

private fun AuthoringGraphDelta.toSummary(): AuthoringChangeSummary =
    AuthoringChangeSummary(
        changedResources = resourceUpserts.keys + resourceRemovals,
        changedEdges = relationUpserts.keys + relationRemovals,
        deletedResources = resourceRemovals,
    )

private fun com.typewritermc.authoring.AuthoringCompilationResult.toRealm(): CompilationResult =
    when (this) {
        is com.typewritermc.authoring.AuthoringCompilationResult.Success -> {
            CompilationResult.Success(artifact.toRealm())
        }

        is com.typewritermc.authoring.AuthoringCompilationResult.Removed -> {
            CompilationResult.Removed(root.toRealm())
        }

        is com.typewritermc.authoring.AuthoringCompilationResult.Blocked -> {
            CompilationResult.Blocked(
                root = root.toRealm(),
                inputFingerprint = ContentDigest(inputFingerprint.value),
                diagnostics =
                    diagnostics.map { diagnostic ->
                        com.typewritermc.engine.CompileDiagnostic(
                            code = diagnostic.code,
                            message = diagnostic.message,
                            severity =
                                when (diagnostic.severity) {
                                    com.typewritermc.authoring.AuthoringCompileDiagnostic.Severity.ERROR -> {
                                        com.typewritermc.engine.CompileDiagnosticSeverity.ERROR
                                    }

                                    com.typewritermc.authoring.AuthoringCompileDiagnostic.Severity.WARNING -> {
                                        com.typewritermc.engine.CompileDiagnosticSeverity.WARNING
                                    }
                                },
                            source = diagnostic.source,
                            target = diagnostic.target,
                        )
                    },
            )
        }
    }

private fun com.typewritermc.authoring.AuthoringCompiledArtifact.toRealm(): CompiledArtifact =
    CompiledArtifact(
        root = root.toRealm(),
        formatRevision = formatRevision,
        mediaType = mediaType,
        inputFingerprint = ContentDigest(inputFingerprint.value),
        semanticDigest = ContentDigest(semanticDigest.value),
        payload = payload,
    )

private fun com.typewritermc.authoring.AuthoringCompilationRoot.toRealm(): CompilationRoot =
    CompilationRoot(CompilationProjectionId(projection.value), resource)
