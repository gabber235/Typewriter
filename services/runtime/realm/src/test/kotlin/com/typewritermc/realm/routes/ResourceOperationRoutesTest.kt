@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphLayoutDefinition
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.assemble
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.BookPages
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.PageElements
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.operations.BuiltinResourceOperation
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.operations.MoveToPageInput
import com.typewritermc.operations.MoveToPageInputDefinition
import com.typewritermc.operations.linkWith
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
import com.typewritermc.realm.repository.ResourceValueMapper
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
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationInvocation
import skirout.editor.v1.resource_operations.OperationOrigin
import skirout.editor.v1.resource_operations.OperationSelectionEffect
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.OperationWorkingOverlay
import skirout.editor.v1.resource_operations.PrepareAuthoringActionRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import java.nio.file.Path

val ResourceOperationRoutesTest by testSuite {
    test("generated core declarations resolve mixed selection and book primary action") {
        CoreOperationsFixture().use { fixture ->
            val book = fixture.resolve("book") as ResolveResourceOperationsResult.ResolvedWrapper
            book.value.primaryOperation?.local shouldBe "open"
            book.value.operations
                .map { it.definition.id.local }
                .contains("open") shouldBe true
            val tag = fixture.resolve("tag") as ResolveResourceOperationsResult.ResolvedWrapper
            tag.value.operations
                .map { it.definition.id.local }
                .contains("linkWithDuplicate") shouldBe true
            val mixed = fixture.resolve("book", "tag") as ResolveResourceOperationsResult.ResolvedWrapper
            mixed.value.primaryOperation shouldBe null
            mixed.value.operations
                .map { it.definition.id.local }
                .toSet() shouldBe setOf("duplicate", "delete")
        }
    }

    test("linked tag duplicate crosses wire preparation and replay without changing saved state") {
        runTest {
            CoreOperationsFixture().use { fixture ->
                val before = fixture.views.read { it.resources }
                val result =
                    fixture.routes.prepare(
                        fixture.prepare(BuiltinResourceOperation.LinkWithDuplicate, "tag"),
                    ) as AuthoringActionResult.PreviewWrapper
                val selected = result.value.selection as OperationSelectionEffect.ReplaceWrapper
                val copy = ResourceId(selected.value.single().value)
                val edit = SkirAuthoringOperationCodec.decode(result.value.edit).getOrThrow()
                val replay =
                    fixture.views.capture().use { lease ->
                        val catalog = lease.root.catalog
                        AuthoringMutationPlanner(
                            catalog.checked,
                            catalog.relations,
                            catalog.endpointBindings,
                        ).plan(before, edit) as MutationPlanningResult.Accepted
                    }
                val after = before + replay.plan.resources - replay.plan.removedResources
                val links = ResourceValueMapper.discover(after)
                links.any { it.source == ResourceId("tag") && it.target.resource == copy } shouldBe true
                links.any { it.source == copy && it.target.resource == ResourceId("parent") } shouldBe true
                links.any { it.source == ResourceId("tag") && it.target.resource == ResourceId("parent") } shouldBe true
                fixture.views.read { it.resources } shouldBe before
            }
        }
    }

    test("moving pages appends within each chapter in selection order and preserves saved state") {
        runTest {
            CoreOperationsFixture(withPages = true).use { fixture ->
                val before = fixture.views.read { it.resources }
                val request =
                    fixture
                        .prepare(BuiltinResourceOperation.MoveToBook, "second", "first", "other", "resident")
                        .copy(
                            input =
                                fixture.input(
                                    com.typewritermc.operations.MoveToBookInput(ResourceId("destination")),
                                    com.typewritermc.operations.MoveToBookInputDefinition.id,
                                ),
                        )
                val response = fixture.routes.prepare(request)
                val result = response as? AuthoringActionResult.PreviewWrapper ?: error(response.toString())
                val edit = SkirAuthoringOperationCodec.decode(result.value.edit).getOrThrow()
                val replay =
                    fixture.views.capture().use { lease ->
                        val catalog = lease.root.catalog
                        AuthoringMutationPlanner(
                            catalog.checked,
                            catalog.relations,
                            catalog.endpointBindings,
                        ).plan(before, edit) as MutationPlanningResult.Accepted
                    }
                val after = before + replay.plan.resources - replay.plan.removedResources
                after.getValue(ResourceId("second")).fields["priority"] shouldBe DataValue.Integer(java.math.BigInteger.valueOf(10))
                after.getValue(ResourceId("first")).fields["priority"] shouldBe DataValue.Integer(java.math.BigInteger.valueOf(11))
                after.getValue(ResourceId("other")).fields["priority"] shouldBe DataValue.Integer(java.math.BigInteger.valueOf(4))
                after.getValue(ResourceId("resident")).fields["priority"] shouldBe DataValue.Integer(java.math.BigInteger.valueOf(9))
                listOf("first", "second", "other").forEach { id ->
                    after.getValue(ResourceId(id)).fields["chapter"] shouldBe before.getValue(ResourceId(id)).fields["chapter"]
                    val owner = (after.getValue(ResourceId(id)).fields.getValue("book") as DataValue.Named).payload as DataValue.Link
                    owner.target.resource shouldBe ResourceId("destination")
                }
                fixture.views.read { it.resources } shouldBe before
            }
        }
    }

    test("moving an entry into a page that is not a graph layout keeps its placement") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val before = fixture.views.read { it.resources }
                val after =
                    fixture.replay(
                        fixture
                            .prepare(BuiltinResourceOperation.MoveToPage, "graph-entry")
                            .copy(input = fixture.input(MoveToPageInput(ResourceId("timeline")), MoveToPageInputDefinition.id)),
                    )
                val moved = after.getValue(ResourceId("graph-entry"))
                moved.linkTarget("page") shouldBe ResourceId("timeline")
                moved.fields["placement"] shouldBe before.getValue(ResourceId("graph-entry")).fields["placement"]
            }
        }
    }

    test("moving an entry into a graph layout places it clear of the members already there") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val after =
                    fixture.replay(
                        fixture
                            .prepare(BuiltinResourceOperation.MoveToPage, "graph-entry")
                            .copy(input = fixture.input(MoveToPageInput(ResourceId("canvas")), MoveToPageInputDefinition.id)),
                    )
                val moved = after.getValue(ResourceId("graph-entry"))
                moved.linkTarget("page") shouldBe ResourceId("canvas")
                val placement = moved.graphPlacement()
                placement.intersectsWithGap(after.getValue(ResourceId("resident-entry")).graphPlacement()) shouldBe false
                (placement.width to placement.height) shouldBe (2 to 2)
            }
        }
    }

    test("duplicating an entry inside a page that is not a graph layout needs no placement") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val before = fixture.views.read { it.resources }
                val after = fixture.replay(fixture.prepare(BuiltinResourceOperation.Duplicate, "timeline-entry"))
                val copy = (after.keys - before.keys).single()
                after.getValue(copy).linkTarget("page") shouldBe ResourceId("timeline")
                after.getValue(copy).fields["placement"] shouldBe before.getValue(ResourceId("timeline-entry")).fields["placement"]
            }
        }
    }

    test("a tag dropped onto a book is linked through the book's tags") {
        runTest {
            CoreOperationsFixture(withTagLink = true).use { fixture ->
                val before = fixture.views.read { it.resources }
                val after =
                    fixture.replay(
                        fixture
                            .prepare(BuiltinResourceOperation.LinkWith, "tag")
                            .copy(input = fixture.input(LinkWithInput(ResourceId("book")), LinkWithInputDefinition.id)),
                    )
                after.getValue(ResourceId("book")).linkTargets("tags") shouldBe listOf(ResourceId("tag"))
                after.getValue(ResourceId("tag")).fields shouldBe before.getValue(ResourceId("tag")).fields
            }
        }
    }

    test("a tag dropped onto a tag becomes its child") {
        runTest {
            CoreOperationsFixture(withTagLink = true).use { fixture ->
                val after =
                    fixture.replay(
                        fixture
                            .prepare(BuiltinResourceOperation.LinkWith, "loose")
                            .copy(input = fixture.input(LinkWithInput(ResourceId("tag")), LinkWithInputDefinition.id)),
                    )
                after.getValue(ResourceId("loose")).linkTargets("parents") shouldBe listOf(ResourceId("tag"))
            }
        }
    }

    test("a tag cycle written directly into the parents field is rejected") {
        CoreOperationsFixture().use { fixture ->
            val cyclic =
                fixture.record(
                    Tag(name = "Adventure", parents = setOf(Ref(ResourceId("tag"))), placement = GraphPlacement(5, 0)),
                    TagDefinition.id,
                )
            val generation = fixture.views.read { it.catalog.generation }
            val edit =
                com.typewritermc.authoring.PreparedEdit(
                    generation,
                    emptyList(),
                    listOf(
                        com.typewritermc.authoring.EditIntent.SetValue(
                            com.typewritermc.authoring.ValueLocation(ResourceId("parent"), ValuePath(listOf(PathSegment.Field("parents")))),
                            cyclic.fields.getValue("parents"),
                        ),
                    ),
                )
            val rejected = fixture.plan(edit) as MutationPlanningResult.Rejected
            rejected.problems.map { it.code }.toSet() shouldBe setOf("relation_cycle")
        }
    }

    test("an included alias invokes its retained authoring handler without contributing the canonical operation row") {
        runTest {
            CoreOperationsFixture(withDeleteAlias = true).use { fixture ->
                val resolved = fixture.resolve("tag") as ResolveResourceOperationsResult.ResolvedWrapper
                resolved.value.operations.map { it.definition.id.local } shouldBe listOf("removeTag")
                val response = fixture.routes.prepare(fixture.prepare(BuiltinResourceOperation.Delete, "tag"))
                val preview = response as? AuthoringActionResult.PreviewWrapper ?: error(response.toString())
                val edit = SkirAuthoringOperationCodec.decode(preview.value.edit).getOrThrow()
                val before = fixture.views.read { it.resources }
                val replay =
                    fixture.views.capture().use { lease ->
                        val catalog = lease.root.catalog
                        AuthoringMutationPlanner(
                            catalog.checked,
                            catalog.relations,
                            catalog.endpointBindings,
                        ).plan(before, edit) as MutationPlanningResult.Accepted
                    }
                replay.plan.removedResources shouldBe setOf(ResourceId("tag"))
                fixture.views.read { it.resources } shouldBe before
            }
        }
    }

    test("preparing one action ignores an unrelated failing availability callback while menu resolution still fails") {
        runTest {
            CoreOperationsFixture(withFailingAvailability = true).use { fixture ->
                (fixture.resolve("tag") is ResolveResourceOperationsResult.FailedWrapper) shouldBe true
                val request = fixture.prepare(BuiltinResourceOperation.Delete, "tag")
                (fixture.routes.prepare(request) is AuthoringActionResult.PreviewWrapper) shouldBe true
                val unavailable =
                    request.copy(
                        capability =
                            skirout.editor.v1.type_catalog.CapabilityId(
                                value = fixture.brokenCapability,
                            ),
                    )
                // The selected callback failure is still reported at the existing route boundary.
                (fixture.routes.prepare(unavailable) is AuthoringActionResult.FailedWrapper) shouldBe true
            }
        }
    }

    test("changed saved observations and catalogs produce typed refresh responses") {
        CoreOperationsFixture().use { fixture ->
            val request = fixture.resolveRequest("book")
            val stale =
                fixture.routes.resolve(
                    request.copy(context = request.context.copy(confirmedObservation = AuthoringObservationId(value = "previous"))),
                )
            (stale is ResolveResourceOperationsResult.StaleObservationWrapper) shouldBe true
            val catalog =
                fixture.routes.resolve(
                    request.copy(
                        invocation =
                            request.invocation.copy(
                                catalog =
                                    skirout.editor.v1.type_catalog
                                        .CatalogGeneration(value = "previous"),
                            ),
                    ),
                )
            (catalog is ResolveResourceOperationsResult.CatalogChangedWrapper) shouldBe true
            val empty = fixture.routes.resolve(request.copy(invocation = request.invocation.copy(targets = emptyList())))
            (empty is ResolveResourceOperationsResult.InvalidWrapper) shouldBe true
        }
    }
}

private class CoreOperationsFixture(
    withPages: Boolean = false,
    withDeleteAlias: Boolean = false,
    withFailingAvailability: Boolean = false,
    withElements: Boolean = false,
    withTagLink: Boolean = false,
) : AutoCloseable {
    private val catalogs = RealmCatalogStore()
    val views: InMemoryAuthoringViewStore
    val routes: ResourceOperationRoutes
    val brokenCapability: String

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
        val loaded =
            if (withFailingAvailability) {
                val failing =
                    com.typewritermc.operations.collectOperations(
                        original.declarations.first().origin,
                        "fixture.FailingOperations",
                        TypeTemplate.Named(TagDefinition.id),
                        com.typewritermc.library.TagDraftProjection,
                    ) { scope ->
                        scope.operation("broken", com.typewritermc.operations.noInput()) {
                            label("Broken availability")
                            availability { error("Unselected callback failure") }
                            prepare { error("Unavailable operation must never prepare") }
                        }
                    }
                original.copy(operations = original.operations + failing)
            } else {
                original
            }
        val linkable =
            if (withTagLink) {
                // Core tags do not declare Link with yet; the fixture adds it to exercise link direction.
                val tagLink =
                    com.typewritermc.operations.collectOperations(
                        loaded.declarations.first().origin,
                        "fixture.TagLinkOperations",
                        TypeTemplate.Named(TagDefinition.id),
                        com.typewritermc.library.TagDraftProjection,
                    ) { scope -> scope.linkWith() }
                loaded.copy(operations = loaded.operations + tagLink)
            } else {
                loaded
            }
        val contributions =
            if (withDeleteAlias) {
                val alias =
                    com.typewritermc.operations.collectOperations(
                        loaded.declarations.first().origin,
                        "fixture.AliasOperations",
                        TypeTemplate.Named(TagDefinition.id),
                        com.typewritermc.library.TagDraftProjection,
                    ) { scope ->
                        scope.include(
                            com.typewritermc.operations.ResourceOperationDefinition(
                                com.typewritermc.operations.ResourceOperationId("fixture", "main", "fixture.AliasOperations", "removeTag"),
                                com.typewritermc.operations.OperationPresentation("Remove tag"),
                                com.typewritermc.operations.OperationTargets
                                    .Single(TypeTemplate.Named(TagDefinition.id)),
                                skirout.editor.v1.action.EditorAction.createAuthoring(
                                    capability =
                                        skirout.editor.v1.type_catalog.CapabilityId(
                                            value = BuiltinResourceOperation.Delete.id.capability.value,
                                        ),
                                    targets =
                                        com.typewritermc.expression
                                            .input<Any?>(
                                                com.typewritermc.expression.ExpressionBindingId("context:selection"),
                                            ).toNode(),
                                    initialInput = null,
                                ),
                            ),
                        )
                    }
                linkable.copy(operations = linkable.operations.filterNot { it.target.definition == TagDefinition.id } + alias)
            } else {
                linkable
            }
        val pageType = TypeDefinitionId(TypeId.Qualified("fixture", "Page"), 1)
        val origin = contributions.declarations.first().origin

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
        val fixtureTypes =
            buildList {
                if (withPages || withElements) add(derived(pageType, PageDefinition.id, PageDefinition.declaration))
                if (withElements) {
                    add(derived(GRAPH_PAGE_TYPE, PageDefinition.id, PageDefinition.declaration, GraphLayoutDefinition.id))
                    add(derived(ENTRY_TYPE, ElementDefinition.id, ElementDefinition.declaration))
                }
            }
        val fixtureBindings =
            buildList {
                if (withPages || withElements) addAll(derivedBindings(pageType, PageDefinition.id))
                if (withElements) {
                    addAll(derivedBindings(GRAPH_PAGE_TYPE, PageDefinition.id))
                    addAll(derivedBindings(ENTRY_TYPE, ElementDefinition.id))
                }
            }
        val fixtureContributions =
            contributions.copy(
                declarations = contributions.declarations + fixtureTypes,
                endpointBindings = contributions.endpointBindings + fixtureBindings,
            )
        val assembly = fixtureContributions.assemble(CatalogAssemblyContext(CatalogGeneration("core-operations")))
        brokenCapability =
            assembly.operations.definitions
                .firstOrNull { it.id.local == "broken" }
                ?.id
                ?.capability
                ?.value
                .orEmpty()
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
            type: TypeDefinitionId = pageType,
            elements: List<String> = emptyList(),
        ): AuthoringRecord {
            val values =
                mapOf(
                    "book" to
                        Ref<BookPages.Page, Book>(
                            ResourceId(book),
                            ValuePath(listOf(PathSegment.Field("pages"), PathSegment.Item(ItemId("native:$index")))),
                        ),
                    "name" to "Page",
                    "chapter" to ChapterPath.parse(chapter),
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
            placement: GraphPlacement,
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
        val resources =
            mutableMapOf(
                ResourceId("book") to record(Book(title = "Tutorial"), BookDefinition.id),
                ResourceId("tag") to
                    record(Tag(name = "Quest", parents = setOf(Ref(ResourceId("parent"))), placement = GraphPlacement()), TagDefinition.id),
                ResourceId("parent") to record(Tag(name = "Adventure", placement = GraphPlacement(5, 0)), TagDefinition.id),
            )
        if (withPages) {
            resources[ResourceId("book")] =
                record(
                    Book(
                        title = "Source",
                        pages =
                            listOf("first", "second", "other").map {
                                Ref(ResourceId(it), ValuePath(listOf(PathSegment.Field("book"))))
                            },
                    ),
                    BookDefinition.id,
                )
            resources[ResourceId("destination")] =
                record(
                    Book(
                        title = "Destination",
                        pages =
                            listOf("resident", "peer").map {
                                Ref(ResourceId(it), ValuePath(listOf(PathSegment.Field("book"))))
                            },
                    ),
                    BookDefinition.id,
                )

            resources[ResourceId("first")] = page("book", "intro", 100, 0)
            resources[ResourceId("second")] = page("book", "intro", 1, 1)
            resources[ResourceId("other")] = page("book", "outro", 77, 2)
            resources[ResourceId("resident")] = page("destination", "intro", 9, 0)
            resources[ResourceId("peer")] = page("destination", "outro", 3, 1)
        }
        if (withElements) {
            resources[ResourceId("library")] =
                record(
                    Book(
                        title = "Library",
                        pages =
                            listOf("graph", "canvas", "timeline").map {
                                Ref(ResourceId(it), ValuePath(listOf(PathSegment.Field("book"))))
                            },
                    ),
                    BookDefinition.id,
                )
            resources[ResourceId("graph")] = page("library", "intro", 0, 0, GRAPH_PAGE_TYPE, listOf("graph-entry"))
            resources[ResourceId("canvas")] = page("library", "intro", 1, 1, GRAPH_PAGE_TYPE, listOf("resident-entry"))
            resources[ResourceId("timeline")] = page("library", "intro", 2, 2, elements = listOf("timeline-entry"))
            resources[ResourceId("graph-entry")] = entry("graph", 0, GraphPlacement(0, 0, 2, 2))
            resources[ResourceId("resident-entry")] = entry("canvas", 0, GraphPlacement(0, 0, 2, 2))
            resources[ResourceId("timeline-entry")] = entry("timeline", 0, GraphPlacement(4, 4, 1, 1))
        }
        if (withTagLink) {
            resources[ResourceId("loose")] = record(Tag(name = "Loose", placement = GraphPlacement(9, 0)), TagDefinition.id)
        }
        views = InMemoryAuthoringViewStore(lease, AuthoringSeed(resources))
        routes = ResourceOperationRoutes(ResourceOperationRuntime(views), EditorContracts(RealmRouteScope("organization", "realm")))
    }

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
        views.read { root ->
            ResolveResourceOperationsRequest(
                invocation =
                    OperationInvocation(
                        invocationId = InvocationId(value = "operation-test"),
                        catalog =
                            skirout.editor.v1.type_catalog
                                .CatalogGeneration(value = root.catalog.generation.value),
                        targets =
                            ids.map {
                                skirout.editor.v1.type_catalog
                                    .ResourceId(value = it)
                            },
                        origin = OperationOrigin(container = null, occurrences = emptyList()),
                    ),
                context =
                    OperationWorkingContext(
                        confirmedObservation = AuthoringObservationId(value = root.observationId),
                        overlay = OperationWorkingOverlay(upserts = emptyList(), removals = emptyList()),
                    ),
            )
        }

    fun prepare(
        operation: BuiltinResourceOperation,
        vararg ids: String,
    ): PrepareAuthoringActionRequest {
        val resolved = resolveRequest(*ids)
        return PrepareAuthoringActionRequest(
            invocation = resolved.invocation,
            capability =
                skirout.editor.v1.type_catalog
                    .CapabilityId(value = operation.id.capability.value),
            context = resolved.context,
            inputRevision = 0,
            input = null,
            choices = emptyList(),
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
    fun plan(edit: com.typewritermc.authoring.PreparedEdit): MutationPlanningResult =
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

private val GRAPH_PAGE_TYPE = TypeDefinitionId(TypeId.Qualified("fixture", "GraphPage"), 1)
private val ENTRY_TYPE = TypeDefinitionId(TypeId.Qualified("fixture", "Entry"), 1)

private fun AuthoringRecord.graphPlacement(): GraphPlacement {
    val fields = ((fields.getValue("placement") as DataValue.Named).payload as DataValue.Record).fields

    fun int(name: String) = (fields.getValue(name) as DataValue.Integer).value.toInt()
    return GraphPlacement(int("x"), int("y"), int("width"), int("height"))
}

private fun GraphPlacement.intersectsWithGap(other: GraphPlacement): Boolean =
    x.toLong() < other.x.toLong() + other.width + 1 && x.toLong() + width + 1 > other.x &&
        y.toLong() < other.y.toLong() + other.height + 1 && y.toLong() + height + 1 > other.y

private fun AuthoringRecord.linkTarget(field: String): ResourceId =
    ((fields.getValue(field) as DataValue.Named).payload as DataValue.Link).target.resource

private fun AuthoringRecord.linkTargets(field: String): List<ResourceId> {
    val payload = (fields.getValue(field) as DataValue.Named).payload
    val items =
        when (payload) {
            is DataValue.ListValue -> payload.items
            is DataValue.SetValue -> payload.items
            else -> error("Expected a collection in $field.")
        }
    return items.map { ((it.value as DataValue.Named).payload as DataValue.Link).target.resource }
}
