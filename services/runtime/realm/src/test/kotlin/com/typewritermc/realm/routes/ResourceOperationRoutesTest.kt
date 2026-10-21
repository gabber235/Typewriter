@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.library.TAXONOMY_TAGS_RELATION_ID
import com.typewritermc.library.TagDefinition
import com.typewritermc.operations.AnyResourceSubjects
import com.typewritermc.operations.Delete
import com.typewritermc.operations.Duplicate
import com.typewritermc.operations.LinkWith
import com.typewritermc.operations.LinkWithDuplicate
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.operations.LinkWithInputFields
import com.typewritermc.operations.MoveToOwner
import com.typewritermc.operations.MoveToOwnerInput
import com.typewritermc.operations.MoveToOwnerInputDefinition
import com.typewritermc.operations.OperationInput
import com.typewritermc.operations.ResourceOperationSpecImpl
import com.typewritermc.operations.Unlink
import com.typewritermc.operations.UnlinkInput
import com.typewritermc.operations.UnlinkInputDefinition
import com.typewritermc.operations.capability
import com.typewritermc.operations.collectOperation
import com.typewritermc.operations.fillOnDrop
import com.typewritermc.realm.TestRealmStructure
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.realm.testTag
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.endpointId
import com.typewritermc.types.fieldMap
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.payload
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationSelectionEffect
import skirout.editor.v1.resource_operations.ResolveDropCandidatesResult
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val ResourceOperationRoutesTest by testSuite {
    test("every resource gets the core operations its graph facts allow") {
        CoreOperationsFixture().use { fixture ->
            fixture.operationsOf("book") shouldBe setOf("MoveToOwner", "LinkWith", "Duplicate", "Delete")
            fixture.operationsOf("tag") shouldBe setOf("MoveToOwner", "LinkWith", "Unlink", "Duplicate", "LinkWithDuplicate", "Delete")
            fixture.operationsOf("book", "tag") shouldBe setOf("MoveToOwner", "LinkWith", "Unlink", "Duplicate", "Delete")
            fixture.operationsOf(TestRealmStructure.library.value) shouldBe emptySet()
            fixture.operationsOf(TestRealmStructure.root.value) shouldBe emptySet()
        }
    }

    test("operations resolve in group order and carry their capability and drop") {
        CoreOperationsFixture().use { fixture ->
            val resolved = (fixture.resolve("tag") as ResolveResourceOperationsResult.ResolvedWrapper).value.operations
            resolved.map {
                it.definition.id.declaration
                    .substringAfterLast('.')
            } shouldBe
                listOf("MoveToOwner", "LinkWith", "Unlink", "Duplicate", "LinkWithDuplicate", "Delete")
            val move = resolved.first().definition
            move.capability.value shouldBe fixture.operation(MoveToOwner).capability.value
            move.drop?.hint shouldBe "Move here"
            resolved
                .last()
                .definition.presentation.shortcut shouldBe skirout.editor.v1.operation.OperationShortcut.DELETE
        }
    }

    test("linked tag duplicate crosses wire preparation and replay without changing saved state") {
        runTest {
            CoreOperationsFixture().use { fixture ->
                val before = fixture.views.read { it.resources }
                val result = fixture.routes.prepare(fixture.prepare(LinkWithDuplicate, "tag")) as AuthoringActionResult.PreviewWrapper
                val selected = result.value.selection as OperationSelectionEffect.ReplaceWrapper
                val copy = ResourceId(selected.value.single().value)
                val edit = SkirAuthoringOperationCodec.decode(result.value.edit).getOrThrow()
                val after =
                    (fixture.plan(edit) as MutationPlanningResult.Accepted).let {
                        before + it.plan.resources -
                            it.plan.removedResources
                    }
                after.getValue(ResourceId("tag")).linkTargets("parents").toSet() shouldBe setOf(ResourceId("parent"), copy)
                after.getValue(copy).linkTargets("parents") shouldBe listOf(ResourceId("parent"))
                fixture.views.read { it.resources } shouldBe before
            }
        }
    }

    test("moving pages to another book keeps their chapters and priorities") {
        runTest {
            CoreOperationsFixture(withPages = true).use { fixture ->
                val before = fixture.views.read { it.resources }
                val after =
                    fixture.replay(
                        fixture
                            .prepare(MoveToOwner, "second", "first", "other")
                            .copy(input = fixture.input(MoveToOwnerInput(ResourceId("destination")), MoveToOwnerInputDefinition.id)),
                    )
                listOf("first", "second", "other").forEach { id ->
                    val moved = after.getValue(ResourceId(id))
                    moved.linkTarget("book") shouldBe ResourceId("destination")
                    moved.field("chapter") shouldBe before.getValue(ResourceId(id)).field("chapter")
                    moved.field("priority") shouldBe before.getValue(ResourceId(id)).field("priority")
                }
                after.getValue(ResourceId("destination")).linkTargets("pages") shouldContainAll
                    listOf("resident", "peer", "first", "second", "other").map(::ResourceId)
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
                            .prepare(MoveToOwner, "graph-entry")
                            .copy(
                                input =
                                    fixture.input(
                                        MoveToOwnerInput(ResourceId("timeline"), PlacementAnchor(40.0, 40.0)),
                                        MoveToOwnerInputDefinition.id,
                                    ),
                            ),
                    )
                val moved = after.getValue(ResourceId("graph-entry"))
                moved.linkTarget("page") shouldBe ResourceId("timeline")
                moved.field("placement") shouldBe before.getValue(ResourceId("graph-entry")).field("placement")
            }
        }
    }

    test("moving an entry into a graph layout places it clear of the members already there") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val after =
                    fixture.replay(
                        fixture
                            .prepare(MoveToOwner, "graph-entry")
                            .copy(input = fixture.input(MoveToOwnerInput(ResourceId("canvas")), MoveToOwnerInputDefinition.id)),
                    )
                val moved = after.getValue(ResourceId("graph-entry"))
                moved.linkTarget("page") shouldBe ResourceId("canvas")
                val placement = moved.graphPlacement()
                placement.intersectsWithGap(after.getValue(ResourceId("resident-entry")).graphPlacement()) shouldBe false
                (placement.width to placement.height) shouldBe (2 to 2)
            }
        }
    }

    test("moving an entry onto a graph canvas places it at the anchor") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val after =
                    fixture.replay(
                        fixture
                            .prepare(MoveToOwner, "graph-entry")
                            .copy(
                                input =
                                    fixture.input(
                                        MoveToOwnerInput(ResourceId("canvas"), PlacementAnchor(20.0, 20.0)),
                                        MoveToOwnerInputDefinition.id,
                                    ),
                            ),
                    )
                after.getValue(ResourceId("graph-entry")).graphPlacement() shouldBe GraphPlacement(19, 19, 2, 2)
            }
        }
    }

    test("moving an entry with another placement kind into a graph layout gives it a fresh graph placement") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val after =
                    fixture.replay(
                        fixture
                            .prepare(MoveToOwner, "timeline-entry")
                            .copy(input = fixture.input(MoveToOwnerInput(ResourceId("canvas")), MoveToOwnerInputDefinition.id)),
                    )
                val moved = after.getValue(ResourceId("timeline-entry"))
                moved.linkTarget("page") shouldBe ResourceId("canvas")
                val placement = moved.graphPlacement()
                placement.intersectsWithGap(after.getValue(ResourceId("resident-entry")).graphPlacement()) shouldBe false
            }
        }
    }

    test("a preparation the planner rejects is invalid with the broken rule") {
        runTest {
            CoreOperationsFixture(extraOperations = { origin -> listOf(orphanTag(origin)) }).use { fixture ->
                val request =
                    fixture
                        .prepare(Delete, "tag")
                        .copy(
                            capability =
                                skirout.editor.v1.type_catalog.CapabilityId(
                                    value = fixture.operationId("fixture.OrphanTag").capability.value,
                                ),
                        )
                val result = fixture.routes.prepare(request) as AuthoringActionResult.InvalidErrorWrapper
                result.value.diagnostics.map { it.code } shouldContain "owner_required"
            }
        }
    }

    test("duplicating an entry inside a page that is not a graph layout needs no placement") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val before = fixture.views.read { it.resources }
                val after = fixture.replay(fixture.prepare(Duplicate, "timeline-entry"))
                val copy = (after.keys - before.keys).single()
                after.getValue(copy).linkTarget("page") shouldBe ResourceId("timeline")
                after.getValue(copy).field("placement") shouldBe before.getValue(ResourceId("timeline-entry")).field("placement")
            }
        }
    }

    test("deleting a selection removes it with everything it owns") {
        runTest {
            CoreOperationsFixture(withElements = true).use { fixture ->
                val after = fixture.replay(fixture.prepare(Delete, "graph"))
                (ResourceId("graph") in after) shouldBe false
                (ResourceId("graph-entry") in after) shouldBe false
                (ResourceId("canvas") in after) shouldBe true
            }
        }
    }

    test("a tag dropped onto a book is linked through the book's tags") {
        runTest {
            CoreOperationsFixture().use { fixture ->
                val before = fixture.views.read { it.resources }
                val after =
                    fixture.replay(
                        fixture
                            .prepare(LinkWith, "tag")
                            .copy(input = fixture.input(LinkWithInput(ResourceId("book")), LinkWithInputDefinition.id)),
                    )
                after.getValue(ResourceId("book")).linkTargets("tags") shouldBe listOf(ResourceId("tag"))
                after.getValue(ResourceId("tag")).fields shouldBe before.getValue(ResourceId("tag")).fields
            }
        }
    }

    test("a tag dropped onto a tag becomes its child") {
        runTest {
            CoreOperationsFixture().use { fixture ->
                val after =
                    fixture.replay(
                        fixture
                            .prepare(LinkWith, "loose")
                            .copy(input = fixture.input(LinkWithInput(ResourceId("tag")), LinkWithInputDefinition.id)),
                    )
                after.getValue(ResourceId("loose")).linkTargets("parents") shouldBe listOf(ResourceId("tag"))
                after.getValue(ResourceId("tag")).linkTargets("parents") shouldBe listOf(ResourceId("parent"))
            }
        }
    }

    test("linking an already linked tag changes nothing and unlink removes the link") {
        runTest {
            CoreOperationsFixture().use { fixture ->
                val before = fixture.views.read { it.resources }
                val relinked =
                    fixture.replay(
                        fixture
                            .prepare(LinkWith, "tag")
                            .copy(input = fixture.input(LinkWithInput(ResourceId("parent")), LinkWithInputDefinition.id)),
                    )
                relinked shouldBe before
                val unlinked =
                    fixture.replay(
                        fixture
                            .prepare(Unlink, "tag")
                            .copy(input = fixture.input(UnlinkInput(ResourceId("parent")), UnlinkInputDefinition.id)),
                    )
                unlinked.getValue(ResourceId("tag")).linkTargets("parents") shouldBe emptyList()
            }
        }
    }

    test("a tag cycle written directly into the parents field is rejected") {
        CoreOperationsFixture().use { fixture ->
            val cyclic =
                fixture.record(
                    testTag(name = "Adventure", parents = setOf(Ref(ResourceId("tag"))), placement = GraphPlacement(5, 0)),
                    TagDefinition.id,
                )
            val generation = fixture.views.read { it.catalog.generation }
            val edit =
                PreparedEdit(
                    generation,
                    emptyList(),
                    listOf(
                        EditIntent.SetValue(
                            ValueLocation.of(ResourceId("parent"), ValuePath.root.field("parents")),
                            cyclic.fieldMap.getValue("parents"),
                        ),
                    ),
                )
            val rejected = fixture.plan(edit) as MutationPlanningResult.Rejected
            rejected.problems.map { it.code }.toSet() shouldBe setOf("relation_cycle")
        }
    }

    test("drop candidates come from the declared candidates of enabled operations") {
        CoreOperationsFixture(withElements = true).use { fixture ->
            val entry = fixture.drops("graph-entry")
            entry.keys shouldBe setOf("MoveToOwner")
            entry
                .getValue("MoveToOwner")
                .destinations
                .map { it.value }
                .toSet() shouldBe setOf("canvas", "timeline")
            entry.getValue("MoveToOwner").complete shouldBe true

            val tag = fixture.drops("tag")
            tag
                .getValue("LinkWith")
                .destinations
                .map { it.value }
                .toSet() shouldBe setOf("book", "library", "loose")
            tag.getValue("Unlink").destinations.map { it.value } shouldBe listOf("parent")
            fixture.drops(TestRealmStructure.library.value) shouldBe emptyMap()
        }
    }

    test("drop candidates are capped and marked incomplete") {
        CoreOperationsFixture(extraOperations = { origin -> listOf(manyCandidates(origin)) }).use { fixture ->
            val many = fixture.drops("tag").getValue("ManyCandidates")
            many.destinations.size shouldBe 200
            many.complete shouldBe false
        }
    }

    test("a failing availability callback fails menu resolution but not drops or the preparation of another operation") {
        runTest {
            CoreOperationsFixture(extraOperations = { origin -> listOf(brokenAvailability(origin)) }).use { fixture ->
                (fixture.resolve("tag") is ResolveResourceOperationsResult.FailedErrorWrapper) shouldBe true
                // Drops only evaluate operations that declare a drop field.
                (fixture.dropCandidates("tag") is ResolveDropCandidatesResult.ResolvedWrapper) shouldBe true
                (fixture.routes.prepare(fixture.prepare(Delete, "tag")) is AuthoringActionResult.PreviewWrapper) shouldBe true
                val broken =
                    fixture
                        .prepare(Delete, "tag")
                        .copy(
                            capability =
                                skirout.editor.v1.type_catalog.CapabilityId(
                                    value =
                                        fixture
                                            .operationId("fixture.BrokenAvailability")
                                            .capability.value,
                                ),
                        )
                (fixture.routes.prepare(broken) is AuthoringActionResult.FailedErrorWrapper) shouldBe true
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
            (stale is ResolveResourceOperationsResult.StaleObservationErrorWrapper) shouldBe true
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
            (catalog is ResolveResourceOperationsResult.CatalogChangedErrorWrapper) shouldBe true
            val empty = fixture.routes.resolve(request.copy(invocation = request.invocation.copy(targets = emptyList())))
            (empty is ResolveResourceOperationsResult.InvalidErrorWrapper) shouldBe true
        }
    }
}

/** The simple names of the operation objects resolved for [ids]. */
private fun CoreOperationsFixture.operationsOf(vararg ids: String): Set<String> =
    (resolve(*ids) as ResolveResourceOperationsResult.ResolvedWrapper)
        .value.operations
        .map {
            it.definition.id.declaration
                .substringAfterLast('.')
        }.toSet()

/** Drop candidates for dragging [ids], by operation object simple name. */
private fun CoreOperationsFixture.drops(vararg ids: String) =
    (dropCandidates(*ids) as ResolveDropCandidatesResult.ResolvedWrapper)
        .value
        .associateBy { it.operation.declaration.substringAfterLast('.') }

private fun CoreOperationsFixture.operationId(declaration: String) =
    views.read { root ->
        root.catalog.operations.operations
            .single { it.definition.id.declaration == declaration }
            .definition.id
    }

/** A Tag operation whose drop field declares more candidates than one drag may receive. */
private fun manyCandidates(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, LinkWithInput>(
        origin,
        "fixture.ManyCandidates",
        ResourceTarget.Type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.Typed(LinkWithInputDefinition.use),
        "Many candidates",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            input {
                LinkWithInputFields.target {
                    candidates { (0 until 250).asSequence().map { ResourceId("candidate-$it") } }
                    fillOnDrop()
                }
            }
            prepare { }
        }
    }

/** A Tag operation that releases its subject from the taxonomy, leaving it without an owner. */
private fun orphanTag(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, Unit>(
        origin,
        "fixture.OrphanTag",
        ResourceTarget.Type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.None,
        "Orphan tag",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            prepare {
                val owner = RelationId(TAXONOMY_TAGS_RELATION_ID).endpointId(EndpointSlot.Second)
                disconnect(
                    LinkOccurrenceId(
                        endpoint = owner,
                        location =
                            ValueLocation.of(
                                subjects.single(),
                                ValuePath.root.field("taxonomy"),
                            ),
                    ),
                )
            }
        }
    }

/** A Tag operation whose availability always fails. */
private fun brokenAvailability(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, Unit>(
        origin,
        "fixture.BrokenAvailability",
        ResourceTarget.Type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.None,
        "Broken availability",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            availableWhen { error("Unselected callback failure") }
            prepare { error("Unavailable operation must never prepare") }
        }
    }

private fun AuthoringRecord.graphPlacement(): GraphPlacement {
    val fields = ((fieldMap.getValue("placement") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper).value.fieldMap

    fun int(name: String) = (fields.getValue(name) as DataValue.IntegerWrapper).value.toInt()
    return GraphPlacement(int("x"), int("y"), int("width"), int("height"))
}

private fun GraphPlacement.intersectsWithGap(other: GraphPlacement): Boolean =
    x.toLong() < other.x.toLong() + other.width + 1 && x.toLong() + width + 1 > other.x &&
        y.toLong() < other.y.toLong() + other.height + 1 && y.toLong() + height + 1 > other.y

private fun AuthoringRecord.linkTarget(field: String): ResourceId =
    ((fieldMap.getValue(field) as DataValue.NamedWrapper).payload as DataValue.LinkWrapper)
        .value.target.resource
        .toResourceId()

private fun AuthoringRecord.linkTargets(field: String): List<ResourceId> {
    val payload = (fieldMap.getValue(field) as DataValue.NamedWrapper).payload
    val items =
        when (payload) {
            is DataValue.ListValueWrapper -> payload.items
            is DataValue.SetValueWrapper -> payload.items
            else -> error("Expected a collection in $field.")
        }
    return items.map {
        ((it.value as DataValue.NamedWrapper).payload as DataValue.LinkWrapper)
            .value.target.resource
            .toResourceId()
    }
}
