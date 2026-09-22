package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringCompilationProjection
import com.typewritermc.authoring.AuthoringCompilationResult
import com.typewritermc.authoring.AuthoringContentDigest
import com.typewritermc.authoring.AuthoringGraphRelation
import com.typewritermc.authoring.AuthoringGraphResource
import com.typewritermc.authoring.AuthoringPolicyProvider
import com.typewritermc.authoring.AuthoringPresentationProjection
import com.typewritermc.authoring.AuthoringPresentationSubject
import com.typewritermc.authoring.AuthoringSearchDocument
import com.typewritermc.authoring.AuthoringSearchProjection
import com.typewritermc.authoring.AuthoringWorkingGraph
import com.typewritermc.authoring.GraphReadRequirement
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementCatalog
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationResult
import com.typewritermc.library.BOOK_PAGES_RELATION_ID
import com.typewritermc.library.Book
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.library.Page
import com.typewritermc.library.Tag
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.compiler.AuthoringCompilationProjectionRegistry
import com.typewritermc.realm.compiler.PageCompilationProjection
import com.typewritermc.realm.repository.AuthoringGraphDelta
import com.typewritermc.realm.repository.DecomposedResourceValue
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.realm.routes.AuthoringPresentationRegistry
import com.typewritermc.realm.search.AuthoringSearchGraph
import com.typewritermc.realm.search.AuthoringSearchProjectionRegistry
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.realm.repository.AuthoringWorkingGraph as RealmWorkingGraph
import com.typewritermc.realm.routes.AuthoringPresentationProjection as RealmPresentationProjection
import com.typewritermc.realm.search.AuthoringSearchProjection as RealmSearchProjection

/** Registers Realm library behavior through the same public policy boundary as extensions. */
internal class CoreAuthoringPolicyProvider(
    private val prototypes: TypePrototypeRegistry,
    private val pageCatalog: PageCatalog,
    private val elements: ElementCatalog,
    private val types: TypeCatalog,
    private val catalogRevision: () -> String,
) : AuthoringPolicyProvider {
    override fun contribute(builder: com.typewritermc.authoring.AuthoringPolicyCatalog.Builder) {
        coreDefinitions().forEach(builder::definition)
        coreSearchProjections().forEach(builder::search)
        coreSearchSelectors().forEach(builder::searchSelector)
        coreSearchFacets().forEach(builder::searchFacet)
        corePresentations().forEach(builder::presentation)
        coreAuthoringCreationSlots(pageCatalog, prototypes, types).forEach(builder::creationSlot)
        builder.compilation(coreCompilationProjection())
    }

    private fun coreSearchSelectors() =
        listOf(
            com.typewritermc.authoring.AuthoringSearchSelector("book", "book:"),
            com.typewritermc.authoring.AuthoringSearchSelector("page", "page:"),
            com.typewritermc.authoring.AuthoringSearchSelector("tag", "tag:"),
            com.typewritermc.authoring.AuthoringSearchSelector("type", "type:"),
        )

    private fun coreSearchFacets() =
        listOf(
            com.typewritermc.authoring.AuthoringSearchFacet("book", "Book", "book"),
            com.typewritermc.authoring.AuthoringSearchFacet("page", "Page", "page"),
            com.typewritermc.authoring.AuthoringSearchFacet("tag", "Tag", "tag"),
            com.typewritermc.authoring.AuthoringSearchFacet("type", "Type", "type"),
        )

    private fun coreDefinitions() =
        listOf(
            com.typewritermc.authoring.AuthoringResourceDefinition(
                CoreResourceDefinitionIds.BOOK,
                TypeExpression.Named(prototypes.require(Book::class).type),
                navigationHandler = "typewriter.book",
            ),
            com.typewritermc.authoring.AuthoringResourceDefinition(
                CoreResourceDefinitionIds.TAG,
                TypeExpression.Named(prototypes.require(Tag::class).type),
                navigationHandler = "typewriter.tags",
            ),
            com.typewritermc.authoring.AuthoringResourceDefinition(
                CoreResourceDefinitionIds.PAGE,
                TypeExpression.Named(prototypes.require(Page::class).type),
                navigationHandler = "typewriter.page",
            ),
            com.typewritermc.authoring.AuthoringResourceDefinition(
                CoreResourceDefinitionIds.ELEMENT,
                TypeExpression.Named(types.requireQualified(Element::class.qualifiedName!!)),
                navigationHandler = "typewriter.page-element",
            ),
        )

    private fun coreSearchProjections(): List<AuthoringSearchProjection> =
        listOf(
            coreSearch(
                definition = CoreResourceDefinitionIds.BOOK,
                facet = "book",
                dependencies = setOf(CoreResourceDefinitionIds.BOOK, CoreResourceDefinitionIds.TAG),
                selectors = { resource, graph, _, _ ->
                    mapOf(SearchSelectorId("tag") to graph.inheritedTagValues(resource.id))
                },
            ),
            coreSearch(
                definition = CoreResourceDefinitionIds.TAG,
                facet = "tag",
                dependencies = setOf(CoreResourceDefinitionIds.TAG),
            ),
            coreSearch(
                definition = CoreResourceDefinitionIds.PAGE,
                facet = "page",
                dependencies =
                    setOf(
                        CoreResourceDefinitionIds.PAGE,
                        CoreResourceDefinitionIds.BOOK,
                        CoreResourceDefinitionIds.TAG,
                    ),
                relations = setOf(RelationId(BOOK_PAGES_RELATION_ID)),
                ownerPath = { resource -> pageOwnerPath(resource.id) },
                selectors = { _, graph, ownerPath, _ ->
                    ownerPath
                        .firstOrNull()
                        ?.let { owner ->
                            mapOf(
                                SearchSelectorId("book") to graph.resources[owner]?.identityValues().orEmpty(),
                                SearchSelectorId("tag") to graph.inheritedTagValues(owner),
                            )
                        }.orEmpty()
                },
            ),
            coreSearch(
                definition = CoreResourceDefinitionIds.ELEMENT,
                facet = "type",
                dependencies =
                    setOf(
                        CoreResourceDefinitionIds.ELEMENT,
                        CoreResourceDefinitionIds.PAGE,
                        CoreResourceDefinitionIds.BOOK,
                        CoreResourceDefinitionIds.TAG,
                    ),
                relations = setOf(RelationId(PAGE_ELEMENTS_RELATION_ID), RelationId(BOOK_PAGES_RELATION_ID)),
                ownerPath = { resource -> elementOwnerPath(resource.id) },
                selectors = { _, graph, ownerPath, _ ->
                    buildMap {
                        ownerPath.firstOrNull()?.let { page ->
                            put(SearchSelectorId("page"), graph.resources[page]?.identityValues().orEmpty())
                        }
                        ownerPath.drop(1).firstOrNull()?.let { book ->
                            put(SearchSelectorId("book"), graph.resources[book]?.identityValues().orEmpty())
                            put(SearchSelectorId("tag"), graph.inheritedTagValues(book))
                        }
                    }
                },
            ),
        )

    private fun coreSearch(
        definition: ResourceDefinitionId,
        facet: String,
        dependencies: Set<ResourceDefinitionId>,
        relations: Set<RelationId> = emptySet(),
        ownerPath: AuthoringWorkingGraph.(AuthoringGraphResource) -> List<ResourceId> = { emptyList() },
        selectors: (
            AuthoringGraphResource,
            AuthoringWorkingGraph,
            List<ResourceId>,
            Set<String>,
        ) -> Map<SearchSelectorId, Set<String>> = { _, _, _, _ -> emptyMap() },
    ): AuthoringSearchProjection =
        object : AuthoringSearchProjection {
            override val resourceDefinition = definition
            override val graphRequirement =
                GraphReadRequirement(
                    definitions = dependencies,
                    declaredRelations = relations,
                    outgoingReferences = true,
                    maximumDepth = 16,
                )

            override fun project(
                resource: AuthoringGraphResource,
                graph: AuthoringWorkingGraph,
            ): AuthoringSearchDocument {
                val ownerPath = graph.ownerPath(resource)
                val values = resource.identityValues()
                val projectedSelectors =
                    mapOf(SearchSelectorId(facet) to values) + selectors(resource, graph, ownerPath, values)
                return AuthoringSearchDocument(
                    resource = resource.id,
                    definition = resource.definition,
                    text =
                        buildList {
                            add(resource.id.value)
                            add(resource.definition.value)
                            resource.content.rootValue.collectText(this)
                        }.distinct().joinToString(" "),
                    selectors = projectedSelectors,
                    ownerPath = ownerPath,
                )
            }

            override fun affectedResources(
                change: com.typewritermc.authoring.AuthoringChangeSummary,
                before: AuthoringWorkingGraph,
                proposed: AuthoringWorkingGraph,
            ): Set<ResourceId> =
                (
                    change.changedResources +
                        change.changedEdges.flatMap { edge ->
                            listOfNotNull(before.relations[edge], proposed.relations[edge]).flatMap { listOf(it.source, it.target) }
                        }
                ).let { roots ->
                    before.dependents(roots) + proposed.dependents(roots)
                }
        }

    private fun corePresentations(): List<AuthoringPresentationProjection> =
        listOf(
            corePresentation(CoreResourceDefinitionIds.BOOK) {
                it.descriptor("Book", "Authored page collection", "material-symbols:book", 0xff3f51b5u)
            },
            corePresentation(
                CoreResourceDefinitionIds.TAG,
            ) { it.descriptor("Tag", "Library classification", "material-symbols:label", 0xff795548u) },
            corePresentation(
                definition = CoreResourceDefinitionIds.PAGE,
                dependencies = setOf(CoreResourceDefinitionIds.PAGE, CoreResourceDefinitionIds.BOOK),
                relations = setOf(RelationId(BOOK_PAGES_RELATION_ID)),
                maximumDepth = 1,
                ownerPath = { resource -> pageOwnerPath(resource.id) },
            ) { resource ->
                val page = prototypes.decode(resource.content) as Page
                val definition = pageCatalog.definition(page.kind)
                ResourceTypeDescriptor(
                    resource.rootReference,
                    definition?.name ?: "Page",
                    definition?.description.orEmpty(),
                    definition?.icon ?: Icon.Iconify("material-symbols:description"),
                    definition?.color ?: Color(0xff607d8bu),
                )
            },
            corePresentation(
                definition = CoreResourceDefinitionIds.ELEMENT,
                dependencies =
                    setOf(
                        CoreResourceDefinitionIds.ELEMENT,
                        CoreResourceDefinitionIds.PAGE,
                        CoreResourceDefinitionIds.BOOK,
                    ),
                relations = setOf(RelationId(PAGE_ELEMENTS_RELATION_ID), RelationId(BOOK_PAGES_RELATION_ID)),
                maximumDepth = 2,
                ownerPath = { resource -> elementOwnerPath(resource.id) },
            ) { resource ->
                val definition = elements.descriptor(resource.rootReference)
                ResourceTypeDescriptor(
                    resource.rootReference,
                    definition?.name ?: "Element",
                    definition?.description.orEmpty(),
                    definition?.icon ?: Icon.Iconify("material-symbols:extension"),
                    definition?.color ?: Color(0xff607d8bu),
                )
            },
        )

    private fun corePresentation(
        definition: ResourceDefinitionId,
        dependencies: Set<ResourceDefinitionId> = setOf(definition),
        relations: Set<RelationId> = emptySet(),
        maximumDepth: Int = 0,
        ownerPath: AuthoringWorkingGraph.(AuthoringGraphResource) -> List<ResourceId> = { emptyList() },
        descriptor: (AuthoringGraphResource) -> ResourceTypeDescriptor,
    ): AuthoringPresentationProjection =
        object : AuthoringPresentationProjection {
            override val resourceDefinition = definition
            override val graphRequirement =
                GraphReadRequirement(
                    definitions = dependencies,
                    declaredRelations = relations,
                    direction = GraphReadRequirement.Direction.INCOMING,
                    maximumDepth = maximumDepth,
                )

            override fun project(
                resource: AuthoringGraphResource,
                graph: AuthoringWorkingGraph,
            ): AuthoringPresentationSubject {
                val ownerPath = graph.ownerPath(resource)
                return AuthoringPresentationSubject(
                    resource = resource.id,
                    definition = resource.definition,
                    content = resource.content,
                    descriptor = descriptor(resource),
                    identity = ResourceIdentity(resource.id, ownerPath.firstOrNull()),
                    ownerPath = ownerPath,
                )
            }
        }

    private fun coreCompilationProjection(): AuthoringCompilationProjection =
        object : AuthoringCompilationProjection {
            private val delegate = PageCompilationProjection(prototypes, catalogRevision = catalogRevision)

            override val id = com.typewritermc.authoring.AuthoringCompilationProjectionId(delegate.id.value)
            override val root = delegate.root
            override val graphRequirement =
                GraphReadRequirement(
                    definitions =
                        delegate.graphRequirement.definitions
                            .mapTo(linkedSetOf()) { definition -> ResourceDefinitionId(definition.value) },
                    declaredRelations = setOf(RelationId(PAGE_ELEMENTS_RELATION_ID)),
                    outgoingReferences = true,
                    direction = GraphReadRequirement.Direction.OUTGOING,
                    maximumDepth = 1,
                )

            override fun affectedRoots(
                change: com.typewritermc.authoring.AuthoringChangeSummary,
                before: AuthoringWorkingGraph,
                proposed: AuthoringWorkingGraph,
            ): Set<ResourceId> =
                delegate.affectedRoots(
                    AuthoringGraphDelta(
                        resourceUpserts =
                            proposed.resources.filterKeys { it in change.changedResources }.mapValues { (_, resource) ->
                                DecomposedResourceValue(resource.toRealm(), emptyList())
                            },
                        resourceCreates = emptySet(),
                        resourceRemovals = change.deletedResources,
                        relationUpserts = proposed.relations.filterKeys { it in change.changedEdges }.mapValues { it.value.toRealm() },
                        relationRemovals = change.changedEdges - proposed.relations.keys,
                    ),
                    before.toRealm(),
                    proposed.toRealm(),
                )

            override suspend fun compile(
                root: ResourceId,
                graph: AuthoringWorkingGraph,
            ): AuthoringCompilationResult = delegate.compile(root, graph.toRealm()).toPublic()
        }
}

private fun AuthoringGraphResource.identityValues(): Set<String> =
    buildSet {
        add(id.value)
        val record = content.rootValue as? DataValue.Record ?: return@buildSet
        listOf("title", "name").mapNotNull { (record.fields[it] as? DataValue.StringValue)?.value }.forEach(::add)
    }

private fun DataValue.collectText(target: MutableList<String>) {
    when (this) {
        is DataValue.StringValue -> target += value
        is DataValue.Record -> fields.values.forEach { it.collectText(target) }
        is DataValue.ListValue -> values.forEach { it.collectText(target) }
        is DataValue.MapValue -> entries.forEach { it.value.collectText(target) }
        is DataValue.Polymorphic -> value.collectText(target)
        else -> Unit
    }
}

private fun AuthoringWorkingGraph.pageOwnerPath(page: ResourceId): List<ResourceId> = listOfNotNull(incoming(page, BOOK_PAGES_RELATION_ID))

private fun AuthoringWorkingGraph.elementOwnerPath(element: ResourceId): List<ResourceId> {
    val page = incoming(element, PAGE_ELEMENTS_RELATION_ID)
    return listOfNotNull(page, page?.let { incoming(it, BOOK_PAGES_RELATION_ID) })
}

private fun AuthoringWorkingGraph.incoming(
    target: ResourceId,
    relationId: String,
): ResourceId? =
    relations.values
        .asSequence()
        .filter { relation ->
            relation.target == target &&
                (relation.origin as? com.typewritermc.authoring.AuthoringRelationOrigin.Declared)?.relationId ==
                RelationId(relationId)
        }.map(AuthoringGraphRelation::source)
        .sortedBy(ResourceId::value)
        .firstOrNull()

private fun AuthoringWorkingGraph.dependents(roots: Set<ResourceId>): Set<ResourceId> {
    val affected = roots.toMutableSet()
    val pending = ArrayDeque(roots)
    while (pending.isNotEmpty()) {
        val target = pending.removeFirst()
        relations.values
            .filter { it.target == target }
            .map { it.source }
            .filter(affected::add)
            .forEach(pending::addLast)
    }
    return affected
}

private fun AuthoringWorkingGraph.inheritedTagValues(resource: ResourceId): Set<String> {
    val tags = resources.values.filter { it.definition == CoreResourceDefinitionIds.TAG }.associateBy(AuthoringGraphResource::id)
    val pending = ArrayDeque(resources[resource]?.referenceIds("tags").orEmpty())
    val visited = linkedSetOf<ResourceId>()
    while (pending.isNotEmpty()) {
        val tag = pending.removeFirst()
        if (!visited.add(tag)) continue
        tags[tag]?.referenceIds("parents")?.forEach(pending::addLast)
    }
    return visited.flatMapTo(linkedSetOf()) { id -> tags[id]?.identityValues() ?: setOf(id.value) }
}

private fun AuthoringGraphResource.referenceIds(field: String): List<ResourceId> =
    when (val value = (content.rootValue as? DataValue.Record)?.fields?.get(field)) {
        is DataValue.Reference -> listOf(value.id)
        is DataValue.ListValue -> value.values.filterIsInstance<DataValue.Reference>().map(DataValue.Reference::id)
        else -> emptyList()
    }

private fun AuthoringGraphResource.descriptor(
    name: String,
    description: String,
    icon: String,
    color: UInt,
): ResourceTypeDescriptor =
    ResourceTypeDescriptor(
        rootReference,
        name,
        description,
        Icon.Iconify(icon),
        Color(color),
    )

private val AuthoringGraphResource.rootReference
    get() = (content.rootType as TypeExpression.Named).reference

private fun AuthoringGraphResource.toRealm(): StoredTypedResource =
    StoredTypedResource(
        id = id,
        definition = definition,
        root = (content.rootType as TypeExpression.Named).reference,
        valueWithSlots = content.rootValue,
    )

private fun AuthoringGraphRelation.toRealm(): StoredResourceRelation =
    StoredResourceRelation(
        id = id,
        source = source,
        target = target,
        origin =
            when (val origin = origin) {
                is com.typewritermc.authoring.AuthoringRelationOrigin.Reference -> {
                    ResourceRelationOrigin.Reference(
                        slot = com.typewritermc.elements.ReferenceSlotId(origin.slot),
                        sourcePath = origin.sourcePath,
                        expectedTarget = origin.expectedTarget,
                    )
                }

                is com.typewritermc.authoring.AuthoringRelationOrigin.Declared -> {
                    ResourceRelationOrigin.Declared(origin.relationId)
                }
            },
    )

private fun AuthoringWorkingGraph.toRealm(): RealmWorkingGraph =
    RealmWorkingGraph(
        resources = resources.mapValues { it.value.toRealm() },
        relations = relations.mapValues { it.value.toRealm() },
    )

private fun CompilationResult.toPublic(): AuthoringCompilationResult =
    when (this) {
        is CompilationResult.Success -> {
            AuthoringCompilationResult.Success(artifact.toPublic())
        }

        is CompilationResult.Removed -> {
            AuthoringCompilationResult.Removed(root.toPublic())
        }

        is CompilationResult.Blocked -> {
            AuthoringCompilationResult.Blocked(
                root = root.toPublic(),
                inputFingerprint = AuthoringContentDigest(inputFingerprint.value),
                diagnostics =
                    diagnostics.map { diagnostic ->
                        com.typewritermc.authoring.AuthoringCompileDiagnostic(
                            code = diagnostic.code,
                            message = diagnostic.message,
                            severity = com.typewritermc.authoring.AuthoringCompileDiagnostic.Severity.ERROR,
                            source = diagnostic.source,
                            target = diagnostic.target,
                        )
                    },
            )
        }
    }

private fun com.typewritermc.engine.CompiledArtifact.toPublic() =
    com.typewritermc.authoring.AuthoringCompiledArtifact(
        root = root.toPublic(),
        formatRevision = formatRevision,
        mediaType = mediaType,
        inputFingerprint = AuthoringContentDigest(inputFingerprint.value),
        semanticDigest = AuthoringContentDigest(semanticDigest.value),
        payload = payload,
    )

private fun com.typewritermc.engine.CompilationRoot.toPublic() =
    com.typewritermc.authoring.AuthoringCompilationRoot(
        projection = com.typewritermc.authoring.AuthoringCompilationProjectionId(projection.value),
        resource = resource,
    )

private fun TypeCatalog.requireQualified(qualifiedName: String): ResolvedTypeRef {
    val namespace = qualifiedName.substringBeforeLast('.')
    val name = qualifiedName.substringAfterLast('.')
    return definitions
        .singleOrNull { definition ->
            definition.id.id == TypeId.Qualified(namespace, name)
        }?.id ?: error("Type definition is unavailable: $qualifiedName")
}
