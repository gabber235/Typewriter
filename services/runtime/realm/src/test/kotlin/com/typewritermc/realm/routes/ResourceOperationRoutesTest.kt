package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
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
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.LinkTarget
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
                val before = fixture.snapshots.read { it.resources }
                val result =
                    fixture.routes.prepare(
                        fixture.prepare(BuiltinResourceOperation.LinkWithDuplicate, "tag"),
                    ) as AuthoringActionResult.PreviewWrapper
                val selected = result.value.selection as OperationSelectionEffect.ReplaceWrapper
                val copy = ResourceId(selected.value.single().value)
                val edit = SkirAuthoringOperationCodec.decode(result.value.edit).getOrThrow()
                val replay =
                    fixture.snapshots.capture().use { lease ->
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
                fixture.snapshots.read { it.resources } shouldBe before
            }
        }
    }

    test("moving pages appends within each chapter in selection order and preserves saved state") {
        runTest {
            CoreOperationsFixture(withPages = true).use { fixture ->
                val before = fixture.snapshots.read { it.resources }
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
                    fixture.snapshots.capture().use { lease ->
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
                fixture.snapshots.read { it.resources } shouldBe before
            }
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
                val before = fixture.snapshots.read { it.resources }
                val replay =
                    fixture.snapshots.capture().use { lease ->
                        val catalog = lease.root.catalog
                        AuthoringMutationPlanner(
                            catalog.checked,
                            catalog.relations,
                            catalog.endpointBindings,
                        ).plan(before, edit) as MutationPlanningResult.Accepted
                    }
                replay.plan.removedResources shouldBe setOf(ResourceId("tag"))
                fixture.snapshots.read { it.resources } shouldBe before
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
) : AutoCloseable {
    private val catalogs = RealmCatalogStore()
    val snapshots: InMemoryAuthoringViewStore
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
        val loaded = deployment.providers.contributions
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
                loaded.copy(operations = loaded.operations.filterNot { it.target.definition == TagDefinition.id } + alias)
            } else {
                loaded
            }
        val pageType = TypeDefinitionId(TypeId.Qualified("fixture", "Page"), 1)
        val pageContractFields = (PageDefinition.declaration.representation as RepresentationTemplate.Record).fields
        val fixtureContributions =
            if (withPages) {
                contributions.copy(
                    declarations =
                        contributions.declarations +
                            OwnedTypeDeclaration(
                                contributions.declarations.first().origin,
                                TypeDefinition(
                                    pageType,
                                    representation =
                                        RepresentationTemplate.Record(
                                            pageContractFields.map { field ->
                                                field.copy(owner = FieldOwner(pageType, field.owner.name), overrides = listOf(field.owner))
                                            },
                                        ),
                                    parents = listOf(TypeTemplate.Named(PageDefinition.id)),
                                ),
                            ),
                    endpointBindings =
                        contributions.endpointBindings +
                            contributions.endpointBindings
                                .filter {
                                    it.valueOwner == PageDefinition.id
                                }.map { it.copy(containingResource = TypeTemplate.Named(pageType), valueOwner = pageType) },
                )
            } else {
                contributions
            }
        val assembly = fixtureContributions.assemble(CatalogAssemblyContext(CatalogGeneration("core-operations")))
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

            fun page(
                book: String,
                chapter: String,
                priority: Int,
                index: Int,
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
                        "elements" to emptyList<Ref<PageElements.Page, com.typewritermc.elements.Element>>(),
                    )
                val fields =
                    (PageDefinition.declaration.representation as RepresentationTemplate.Record).fields.associate { field ->
                        val use = (field.type.apply(emptyMap()) as Resolution.Ready).value
                        val checked = (lease.checked.resolve(use) as Resolution.Ready).value
                        field.owner.name to lease.nativeBindings.bind(checked).encodeGeneratedDefault(values.getValue(field.owner.name))
                    }
                return AuthoringRecord(TypeSelection.Complete(TypeUse.Named(pageType)), fields)
            }
            resources[ResourceId("first")] = page("book", "intro", 100, 0)
            resources[ResourceId("second")] = page("book", "intro", 1, 1)
            resources[ResourceId("other")] = page("book", "outro", 77, 2)
            resources[ResourceId("resident")] = page("destination", "intro", 9, 0)
            resources[ResourceId("peer")] = page("destination", "outro", 3, 1)
        }
        snapshots = InMemoryAuthoringViewStore(lease, AuthoringSeed(resources))
        routes = ResourceOperationRoutes(ResourceOperationRuntime(snapshots), EditorContracts(RealmRouteScope("organization", "realm")))
    }

    fun input(
        value: Any,
        type: TypeDefinitionId,
    ): skirout.editor.v1.type_catalog.DataValue =
        snapshots.read { root ->
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
        snapshots.read { root ->
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

    override fun close() {
        snapshots.close()
        catalogs.close()
    }
}
