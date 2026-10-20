@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayoutDefinition
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.capability.CapabilityId
import com.typewritermc.checking.CatalogGeneration
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
import com.typewritermc.operations.ResourceOperationId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.ResourceOperationRuntime
import com.typewritermc.realm.catalog.RealmCatalogIncarnation
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.realm.testBook
import com.typewritermc.realm.testTag
import com.typewritermc.realm.withRealmStructure
import com.typewritermc.types.DataValue
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.Ref
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationInvocation
import skirout.editor.v1.resource_operations.OperationOrigin
import skirout.editor.v1.resource_operations.OperationSearchContext
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.OperationWorkingOverlay
import skirout.editor.v1.resource_operations.PrepareAuthoringActionRequest
import skirout.editor.v1.resource_operations.ResolveDropCandidatesRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
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
            val fields = (declaration.representation as RepresentationTemplate.Record).fields
            return OwnedTypeDeclaration(
                origin,
                TypeDefinition(
                    type,
                    representation =
                        RepresentationTemplate.Record(
                            fields.map { field -> field.copy(owner = FieldOwner(type, field.owner.name), overrides = listOf(field.owner)) },
                        ),
                    parents = (listOf(contract) + extraParents).map { TypeTemplate.Named(it) },
                ),
            )
        }

        fun derivedBindings(
            type: TypeDefinitionId,
            contract: TypeDefinitionId,
        ) = contributions.endpointBindings
            .filter { it.valueOwner == contract }
            .map { it.copy(containingResource = TypeTemplate.Named(type), valueOwner = type) }
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
                ).assemble(CatalogAssemblyContext(CatalogGeneration("core-operations")))
        check(assembly.operations.failures.isEmpty()) { assembly.operations.failures.joinToString { it.cause.stackTraceToString() } }
        catalogs.replace(RealmCatalogIncarnation(assembly, deployment))
        val lease = catalogs.captureCurrent()

        fun <T : Any> record(
            value: T,
            type: TypeDefinitionId,
        ): AuthoringRecord {
            val checked = (lease.checked.resolve(TypeUse.Named(type)) as Resolution.Ready).value

            @Suppress("UNCHECKED_CAST")
            val binding = lease.nativeBindings.bind(checked) as NativeBinding<T>
            val encoded = binding.encode(value) as DataValue.Named
            return AuthoringRecord(TypeSelection.Complete(encoded.actualType), (encoded.payload as DataValue.Record).fields)
        }

        fun encodeFields(
            declaration: TypeDefinition,
            values: Map<String, Any?>,
        ): Map<String, DataValue> =
            (declaration.representation as RepresentationTemplate.Record).fields.associate { field ->
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
                            ResourceId(book),
                            ValuePath(listOf(PathSegment.Field("pages"), PathSegment.Item(ItemId("native:$index")))),
                        ),
                    "name" to "Page $index",
                    "chapter" to HierarchyPath.parse(chapter),
                    "priority" to priority,
                    "elements" to
                        elements.map {
                            Ref<PageElements.Page, com.typewritermc.elements.Element>(
                                ResourceId(it),
                                ValuePath(listOf(PathSegment.Field("page"))),
                            )
                        },
                )
            return AuthoringRecord(TypeSelection.Complete(TypeUse.Named(type)), encodeFields(PageDefinition.declaration, values))
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
                            ResourceId(page),
                            ValuePath(listOf(PathSegment.Field("elements"), PathSegment.Item(ItemId("native:$index")))),
                        ),
                    "name" to "Entry",
                    "placement" to placement,
                )
            return AuthoringRecord(TypeSelection.Complete(TypeUse.Named(ENTRY_TYPE)), encodeFields(ElementDefinition.declaration, values))
        }

        fun bookOf(
            title: String,
            vararg pages: String,
        ) = record(
            testBook(
                title = title,
                pages =
                    pages.map {
                        Ref(ResourceId(it), ValuePath(listOf(PathSegment.Field("book"))))
                    },
            ),
            BookDefinition.id,
        )
        val resources =
            mutableMapOf(
                ResourceId("book") to bookOf("Tutorial"),
                ResourceId("tag") to
                    record(
                        testTag(name = "Quest", parents = setOf(Ref(ResourceId("parent"))), placement = GraphPlacement()),
                        TagDefinition.id,
                    ),
                ResourceId("parent") to record(testTag(name = "Adventure", placement = GraphPlacement(5, 0)), TagDefinition.id),
                ResourceId("loose") to record(testTag(name = "Loose", placement = GraphPlacement(9, 0)), TagDefinition.id),
            )
        if (withPages) {
            resources[ResourceId("book")] = bookOf("Source", "first", "second", "other")
            resources[ResourceId("destination")] = bookOf("Destination", "resident", "peer")
            resources[ResourceId("first")] = page("book", "intro", 100, 0)
            resources[ResourceId("second")] = page("book", "intro", 1, 1)
            resources[ResourceId("other")] = page("book", "outro", 77, 2)
            resources[ResourceId("resident")] = page("destination", "intro", 9, 0)
            resources[ResourceId("peer")] = page("destination", "outro", 3, 1)
        }
        if (withElements) {
            resources[ResourceId("library")] = bookOf("Library", "graph", "canvas", "timeline")
            resources[ResourceId("graph")] = page("library", "intro", 0, 0, GRAPH_PAGE_TYPE, listOf("graph-entry"))
            resources[ResourceId("canvas")] = page("library", "intro", 1, 1, GRAPH_PAGE_TYPE, listOf("resident-entry"))
            resources[ResourceId("timeline")] = page("library", "intro", 2, 2, elements = listOf("timeline-entry"))
            resources[ResourceId("graph-entry")] = entry("graph", 0, GraphPlacement(0, 0, 2, 2))
            resources[ResourceId("resident-entry")] = entry("canvas", 0, GraphPlacement(0, 0, 2, 2))
            resources[ResourceId("timeline-entry")] = entry("timeline", 0, TimelineEntryPlacement(0))
        }
        views = InMemoryAuthoringViewStore(lease, AuthoringSeed(resources.withRealmStructure(lease)))
        runtime = ResourceOperationRuntime(views)
        routes = ResourceOperationRoutes(runtime, EditorContracts(RealmRouteScope("organization", "realm")))
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
    ): CapabilityId = operation(declaration).candidateSearch(ValuePath(listOf(PathSegment.Field(field))))

    fun input(
        value: Any,
        type: TypeDefinitionId,
    ): skirout.editor.v1.type_catalog.DataValue =
        views.read { root ->
            val checked = (root.catalog.checked.resolve(TypeUse.Named(type)) as Resolution.Ready).value
            com.typewritermc.types.skir.SkirDataValueCodec
                .encode(
                    root.catalog.nativeBindings
                        .bind(checked)
                        .encodeGeneratedDefault(value),
                ).getOrThrow()
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
            val checked = (root.catalog.checked.resolve(TypeUse.Named(type)) as Resolution.Ready).value

            @Suppress("UNCHECKED_CAST")
            val binding = root.catalog.nativeBindings.bind(checked) as NativeBinding<T>
            val encoded = binding.encode(value) as DataValue.Named
            AuthoringRecord(TypeSelection.Complete(encoded.actualType), (encoded.payload as DataValue.Record).fields)
        }

    /** Plans [edit] against the saved resources and returns the resulting resources, or the planner rejection. */
    fun plan(edit: PreparedEdit): MutationPlanningResult =
        views.capture().use { lease ->
            val catalog = lease.root.catalog
            AuthoringMutationPlanner(catalog.checked, catalog.relations, catalog.endpointBindings).plan(lease.root.resources, edit)
        }

    /** Prepares [request] through the wire route and replays its preview edit onto the saved resources. */
    suspend fun replay(request: PrepareAuthoringActionRequest): Map<ResourceId, AuthoringRecord> {
        val response = routes.prepare(request)
        val preview = response as? AuthoringActionResult.PreviewWrapper ?: error(response.toString())
        val before = views.read { it.resources }
        val accepted = plan(SkirAuthoringOperationCodec.decode(preview.value.edit).getOrThrow()) as MutationPlanningResult.Accepted
        return before + accepted.plan.resources - accepted.plan.removedResources
    }

    override fun close() {
        views.close()
        catalogs.close()
    }
}

private val PAGE_TYPE = TypeDefinitionId(TypeId.Qualified("fixture", "Page"), 1)
private val GRAPH_PAGE_TYPE = TypeDefinitionId(TypeId.Qualified("fixture", "GraphPage"), 1)
private val ENTRY_TYPE = TypeDefinitionId(TypeId.Qualified("fixture", "Entry"), 1)
