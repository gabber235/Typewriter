@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayoutDefinition
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.requireValid
import com.typewritermc.authoring.root
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.BookPages
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.PageElements
import com.typewritermc.library.TagDefinition
import com.typewritermc.operations.OperationDeclaration
import com.typewritermc.operations.candidateSearch
import com.typewritermc.operations.capability
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.edit.AuthoringMutationPlanner
import com.typewritermc.realm.edit.MutationPlanningResult
import com.typewritermc.realm.operation.ResourceOperationRuntime
import com.typewritermc.realm.testBook
import com.typewritermc.realm.testTag
import com.typewritermc.realm.withRealmStructure
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Ref
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.fieldMap
import com.typewritermc.types.fields
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.requirePortable
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationInvocation
import skirout.editor.v1.resource_operations.OperationOrigin
import skirout.editor.v1.resource_operations.OperationSearchContext
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.OperationWorkingOverlay
import skirout.editor.v1.resource_operations.PrepareAuthoringActionRequest
import skirout.editor.v1.resource_operations.ResolveDropCandidatesRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValuePath
import java.nio.file.Path

/**
 * The core catalog as discovery assembles it from the typewriter artifact, with saved resources for operation tests.
 *
 * Every graph has a book and two tags (`tag` is a child of `parent`) plus the loose tag `loose`. [withPages] adds the
 * books `book` (pages first, second, other) and `destination` (pages resident, peer). [withElements] adds the book
 * `library` with the graph layout pages `graph` and `canvas` and the timeline page `timeline`, each with one entry; the timeline entry holds a timeline entry placement.
 * [extraOperations] adds operation declarations, built with the artifact's origin, before assembly.
 */
internal class CoreOperationsFixture(
    withPages: Boolean = false,
    withElements: Boolean = false,
    extraOperations: (ProviderOrigin) -> List<OperationDeclaration> = { emptyList() },
) : AutoCloseable {
    private val catalogs = RealmCatalogStore()
    val views: InMemoryAuthoringViewStore
    val runtime: ResourceOperationRuntime
    val routes: ResourceOperationRoutes

    init {
        val artifact =
            Path.of(
                Book::class.java.protectionDomain.codeSource.location
                    .toURI(),
            )
        val deployment =
            GeneratedProviderLoader().load(
                listOf(GeneratedProviderArtifact(ArtifactId("typewriter"), artifact)),
                DeploymentFacts(),
                DiscoveryDomains.Realm,
                runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
            )
        val original = deployment.providers.contributions
        val origin = original.declarations.first().origin
        val contributions = original.copy(operations = original.operations + extraOperations(origin))

        fun derived(
            type: TypeDefinitionId,
            contract: TypeDefinitionId,
            declaration: TypeDefinition,
            vararg extraParents: TypeDefinitionId,
        ): OwnedTypeDeclaration {
            val fields = (declaration.representation as RepresentationTemplate.RecordWrapper).value.fields
            return OwnedTypeDeclaration(
                origin,
                TypeDefinition.partial(
                    id = type,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                fields.map { field ->
                                    field.copy(
                                        owner = FieldOwner(definition = type, name = field.owner.name),
                                        overrides = listOf(field.owner),
                                    )
                                },
                            abstract_ = false,
                        ),
                    parents =
                        (
                            listOf(contract) +
                                extraParents
                        ).map { it.namedTemplate() },
                ),
            )
        }

        fun derivedBindings(
            type: TypeDefinitionId,
            contract: TypeDefinitionId,
        ) = contributions.endpointBindings
            .filter { it.valueOwner == contract }
            .map { it.copy(containingResource = type.namedTemplate(), valueOwner = type) }
        val pages = withPages || withElements
        val fixtureTypes =
            buildList {
                if (pages) add(derived(PAGE_TYPE, PageDefinition.id, PageDefinition.declaration))
                if (withElements) {
                    add(derived(GRAPH_PAGE_TYPE, PageDefinition.id, PageDefinition.declaration, GraphLayoutDefinition.id))
                    add(derived(ENTRY_TYPE, ElementDefinition.id, ElementDefinition.declaration))
                }
            }
        val fixtureBindings =
            buildList {
                if (pages) addAll(derivedBindings(PAGE_TYPE, PageDefinition.id))
                if (withElements) {
                    addAll(derivedBindings(GRAPH_PAGE_TYPE, PageDefinition.id))
                    addAll(derivedBindings(ENTRY_TYPE, ElementDefinition.id))
                }
            }
        val assembly =
            contributions
                .copy(
                    declarations = contributions.declarations + fixtureTypes,
                    endpointBindings = contributions.endpointBindings + fixtureBindings,
                ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "core-operations")))
        check(assembly.operations.failures.isEmpty()) { assembly.operations.failures.joinToString { it.cause.stackTraceToString() } }
        catalogs.replace(RealmCatalogIncarnation(assembly, deployment))
        val lease = catalogs.captureCurrent()

        fun <T : Any> record(
            value: T,
            type: TypeDefinitionId,
        ): AuthoringRecord {
            val checked = (lease.checked.resolve(type.use()) as Resolution.Ready).value

            @Suppress("UNCHECKED_CAST")
            val binding = lease.nativeBindings.bind(checked) as NativeBinding<T>
            val encoded = binding.encode(value) as DataValue.NamedWrapper
            return AuthoringRecord.of(
                TypeSelection.CompleteWrapper(encoded.actualType),
                (encoded.payload as DataValue.RecordWrapper).value.fieldMap,
            )
        }

        fun encodeFields(
            declaration: TypeDefinition,
            values: Map<String, Any?>,
        ): Map<String, DataValue> =
            (declaration.representation as RepresentationTemplate.RecordWrapper).value.fields.associate { field ->
                val use = (field.type.apply(emptyMap()) as Resolution.Ready).value
                val checked = (lease.checked.resolve(use) as Resolution.Ready).value
                field.owner.name to lease.nativeBindings.bind(checked).encodeGeneratedDefault(values.getValue(field.owner.name))
            }

        fun page(
            book: String,
            chapter: String,
            priority: Int,
            index: Int,
            type: TypeDefinitionId = PAGE_TYPE,
            elements: List<String> = emptyList(),
        ): AuthoringRecord {
            val values =
                mapOf(
                    "book" to
                        Ref<BookPages.Page, Book>(
                            ResourceId(value = book).toResourceId(),
                            ValuePath(
                                segments =
                                    listOf(
                                        PathSegment.createField(name = "pages"),
                                        PathSegment.createItem(id = ItemId(value = "native:$index")),
                                    ),
                            ),
                        ),
                    "name" to "Page $index",
                    "chapter" to HierarchyPath.parse(chapter),
                    "priority" to priority,
                    "elements" to
                        elements.map {
                            Ref<PageElements.Page, com.typewritermc.elements.Element>(
                                ResourceId(value = it).toResourceId(),
                                ValuePath.root.field("page"),
                            )
                        },
                )
            return AuthoringRecord.of(TypeSelection.CompleteWrapper(type.namedUse()), encodeFields(PageDefinition.declaration, values))
        }

        fun entry(
            page: String,
            index: Int,
            placement: Placement,
        ): AuthoringRecord {
            val values =
                mapOf(
                    "page" to
                        Ref<PageElements.Element, com.typewritermc.library.Page>(
                            ResourceId(value = page).toResourceId(),
                            ValuePath(
                                segments =
                                    listOf(
                                        PathSegment.createField(name = "elements"),
                                        PathSegment.createItem(id = ItemId(value = "native:$index")),
                                    ),
                            ),
                        ),
                    "name" to "Entry",
                    "placement" to placement,
                )
            return AuthoringRecord.of(
                TypeSelection.CompleteWrapper(ENTRY_TYPE.namedUse()),
                encodeFields(ElementDefinition.declaration, values),
            )
        }

        fun bookOf(
            title: String,
            vararg pages: String,
        ) = record(
            testBook(
                title = title,
                pages =
                    pages.map {
                        Ref(ResourceId(value = it).toResourceId(), ValuePath.root.field("book"))
                    },
            ),
            BookDefinition.id,
        )
        val resources =
            mutableMapOf(
                ResourceId(value = "book") to bookOf("Tutorial"),
                ResourceId(value = "tag") to
                    record(
                        testTag(
                            name = "Quest",
                            parents = setOf(Ref(ResourceId(value = "parent").toResourceId())),
                            placement = GraphPlacement(),
                        ),
                        TagDefinition.id,
                    ),
                ResourceId(value = "parent") to record(testTag(name = "Adventure", placement = GraphPlacement(5, 0)), TagDefinition.id),
                ResourceId(value = "loose") to record(testTag(name = "Loose", placement = GraphPlacement(9, 0)), TagDefinition.id),
            )
        if (withPages) {
            resources[ResourceId(value = "book")] = bookOf("Source", "first", "second", "other")
            resources[ResourceId(value = "destination")] = bookOf("Destination", "resident", "peer")
            resources[ResourceId(value = "first")] = page("book", "intro", 100, 0)
            resources[ResourceId(value = "second")] = page("book", "intro", 1, 1)
            resources[ResourceId(value = "other")] = page("book", "outro", 77, 2)
            resources[ResourceId(value = "resident")] = page("destination", "intro", 9, 0)
            resources[ResourceId(value = "peer")] = page("destination", "outro", 3, 1)
        }
        if (withElements) {
            resources[ResourceId(value = "library")] = bookOf("Library", "graph", "canvas", "timeline")
            resources[ResourceId(value = "graph")] = page("library", "intro", 0, 0, GRAPH_PAGE_TYPE, listOf("graph-entry"))
            resources[ResourceId(value = "canvas")] = page("library", "intro", 1, 1, GRAPH_PAGE_TYPE, listOf("resident-entry"))
            resources[ResourceId(value = "timeline")] = page("library", "intro", 2, 2, elements = listOf("timeline-entry"))
            resources[ResourceId(value = "graph-entry")] = entry("graph", 0, GraphPlacement(0, 0, 2, 2))
            resources[ResourceId(value = "resident-entry")] = entry("canvas", 0, GraphPlacement(0, 0, 2, 2))
            resources[ResourceId(value = "timeline-entry")] = entry("timeline", 0, TimelineEntryPlacement(0))
        }
        views = InMemoryAuthoringViewStore(lease, AuthoringSeed(resources.withRealmStructure(lease)))
        runtime = ResourceOperationRuntime(views)
        routes = ResourceOperationRoutes(runtime, RealmRouteScope("organization", "realm"))
    }

    /** The published identity of the operation object [declaration]. */
    fun operation(declaration: Any): ResourceOperationId =
        views.read { root ->
            root.catalog.operations.operations
                .single { it.definition.id.declaration == declaration::class.qualifiedName }
                .definition.id
        }

    /** The candidate search of [field] in the input of the operation object [declaration]. */
    fun candidateSearch(
        declaration: Any,
        field: String,
    ): CapabilityId = operation(declaration).candidateSearch(ValuePath.root.field(field))

    fun input(
        value: Any,
        type: TypeDefinitionId,
    ): skirout.editor.v1.type_catalog.DataValue =
        views.read { root ->
            val checked = (root.catalog.checked.resolve(type.use()) as Resolution.Ready).value
            (
                root.catalog.nativeBindings
                    .bind(checked)
                    .encodeGeneratedDefault(value)
            ).requirePortable()
        }

    fun resolve(vararg ids: String) = routes.resolve(resolveRequest(*ids))

    fun resolveRequest(vararg ids: String): ResolveResourceOperationsRequest =
        ResolveResourceOperationsRequest(invocation = invocation(*ids), context = workingContext())

    fun dropCandidates(vararg ids: String) =
        routes.resolveDropCandidates(ResolveDropCandidatesRequest(invocation = invocation(*ids), context = workingContext()))

    /** A preparation request of the operation object [declaration] for [ids], without input or choices. */
    fun prepare(
        declaration: Any,
        vararg ids: String,
    ): PrepareAuthoringActionRequest =
        PrepareAuthoringActionRequest(
            invocation = invocation(*ids),
            capability =
                skirout.editor.v1.type_catalog
                    .CapabilityId(value = operation(declaration).capability.value),
            context = workingContext(),
            inputRevision = 0,
            input = null,
            choices = emptyList(),
        )

    fun searchContext(vararg ids: String) =
        OperationSearchContext(invocation = invocation(*ids), context = workingContext(), inputRevision = 0)

    fun catalogGeneration(): String = views.read { it.catalog.generation.value }

    private fun invocation(vararg ids: String) =
        OperationInvocation(
            invocationId = InvocationId(value = "operation-test"),
            catalog =
                skirout.editor.v1.type_catalog
                    .CatalogGeneration(value = catalogGeneration()),
            targets =
                ids.map {
                    skirout.editor.v1.type_catalog
                        .ResourceId(value = it)
                },
            origin = OperationOrigin(container = null, occurrences = emptyList()),
        )

    private fun workingContext() =
        views.read { root ->
            OperationWorkingContext(
                confirmedObservation = AuthoringObservationId(value = root.observationId),
                overlay = OperationWorkingOverlay(upserts = emptyList(), removals = emptyList()),
            )
        }

    /** Encodes a native value as a saved record of [type] under the current catalog. */
    fun <T : Any> record(
        value: T,
        type: TypeDefinitionId,
    ): AuthoringRecord =
        views.read { root ->
            val checked = (root.catalog.checked.resolve(type.use()) as Resolution.Ready).value

            @Suppress("UNCHECKED_CAST")
            val binding = root.catalog.nativeBindings.bind(checked) as NativeBinding<T>
            val encoded = binding.encode(value) as DataValue.NamedWrapper
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(encoded.actualType),
                (encoded.payload as DataValue.RecordWrapper).value.fieldMap,
            )
        }

    /** Plans [edit] against the saved resources and returns the resulting resources, or the planner rejection. */
    fun plan(edit: PreparedEdit): MutationPlanningResult =
        views.capture().use { lease ->
            val catalog = lease.root.catalog
            AuthoringMutationPlanner(catalog.checked, catalog.relations).plan(lease.root.resources, edit)
        }

    /** Prepares [request] through the wire route and replays its preview edit onto the saved resources. */
    suspend fun replay(request: PrepareAuthoringActionRequest): Map<ResourceId, AuthoringRecord> {
        val response = routes.prepare(request)
        val preview = response as? AuthoringActionResult.PreviewWrapper ?: error(response.toString())
        val before = views.read { it.resources }
        val accepted = plan(preview.value.edit.requireValid()) as MutationPlanningResult.Accepted
        return before + accepted.plan.resources - accepted.plan.removedResources
    }

    override fun close() {
        views.close()
        catalogs.close()
    }
}

private val PAGE_TYPE = TypeDefinitionId.qualified("fixture", "Page")
private val GRAPH_PAGE_TYPE = TypeDefinitionId.qualified("fixture", "GraphPage")
private val ENTRY_TYPE = TypeDefinitionId.qualified("fixture", "Entry")
