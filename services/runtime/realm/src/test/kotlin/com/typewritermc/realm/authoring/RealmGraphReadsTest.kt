package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.LinkInspectionQuery
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.RouteQuery
import com.typewritermc.authoring.TraversalBudget
import com.typewritermc.authoring.UnresolvedLink
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.of
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

val RealmGraphReadsTest by testSuite {
    val a = ResourceId(value = "a")

    val b = ResourceId(value = "b")

    val c = ResourceId(value = "c")

    val d = ResourceId(value = "d")

    val e = ResourceId(value = "e")

    val missingSelected = ResourceId(value = "missing_selected")

    val selected = RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.FORWARD)

    /**
     * Through the selected edge relation, a links to b, c and a missing resource, b and c link to d, and d links back to a
     * and on to e. a also links to a missing resource and `unrelated` to e only through the other relation.
     */
    val diamond =
        mapOf(
            a to graphRecord(a, listOf(b, c, missingSelected), badTarget = ResourceId(value = "missing_unrelated")),
            b to graphRecord(b, listOf(d)),
            c to graphRecord(c, listOf(d)),
            d to graphRecord(d, listOf(a, e)),
            e to graphRecord(e, emptyList()),
            ResourceId(value = "unrelated") to graphRecord(ResourceId(value = "unrelated"), emptyList(), badTarget = e),
        )

    val sourceResource = ResourceId(value = "source")

    val targetResource = ResourceId(value = "target")

    val bothRelations = RelationSelection.Contracts(setOf(EDGE.id, BAD.id), TraversalDirection.FORWARD)

    /** A source linking to a target through the edge relation, with its link of the other relation left unfilled. */
    val sourceAndTarget =
        mapOf(
            sourceResource to graphRecord(sourceResource, listOf(targetResource)),
            targetResource to graphRecord(targetResource, emptyList()),
        )

    test("reachability visits the resources linked through the selected relation in breadth first order") {
        graphReads(diamond) {
            reachable(a, selected, maxDepth = 3).resources.map { it.id.toSkir() } shouldBe listOf(a, b, c, d, e)
        }
    }

    test("a selected link to a missing resource is reported and interrupts reachability") {
        graphReads(diamond) {
            val reachable = reachable(a, selected, maxDepth = 3)

            reachable.unresolved.map { it.shouldBeInstanceOf<UnresolvedLink.UnavailableTarget>().target.toSkir() } shouldBe
                listOf(missingSelected)
            reachable.completion shouldBe InspectionCompletion.Interrupted("selected link target unavailable")
        }
    }

    test("reachability depends on the seed's selected incoming links and followed field and not on other relations") {
        graphReads(diamond) {
            reachable(a, selected, maxDepth = 3)

            val dependencies = observedInputs()
            (InputIdentity.Incoming(a, EDGE.id) in dependencies) shouldBe true
            observedContentAt(ValueLocation.of(a, ValuePath.root.field("outgoing"))) shouldBe true
            (InputIdentity.Incoming(a, BAD.id) in dependencies) shouldBe false
            (InputIdentity.Incoming(a, null) in dependencies) shouldBe false
        }
    }

    test("reverse reachability reaches the resources that link to the seed") {
        graphReads(diamond) {
            reachable(d, RelationSelection.Contracts(setOf(EDGE.id), TraversalDirection.REVERSE), maxDepth = 1)
                .resources
                .mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(b, c, d)
        }
    }

    test("a resource budget below the reachable graph interrupts reachability") {
        graphReads(diamond) {
            val reachable = reachable(a, selected, budget = TraversalBudget(maxResources = 2))

            reachable.resources.map { it.id.toSkir() } shouldBe listOf(a, b)
            reachable.completion shouldBe InspectionCompletion.Interrupted("resource budget exceeded")
        }
    }

    test("routes list every path to the target within the depth limit") {
        graphReads(diamond) {
            route(a, d, selected, maxDepth = 3).resourcePaths() shouldBe listOf(listOf(a, b, d), listOf(a, c, d))
        }
    }

    test("a route budget that admits exactly the routes found completes the search") {
        graphReads(diamond) {
            val routes = route(b, d, selected, maxDepth = 1, budget = TraversalBudget(maxRoutes = 1))

            routes.resourcePaths() shouldBe listOf(listOf(b, d))
            routes.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("a route budget below the routes found interrupts the search with the routes found first") {
        graphReads(diamond) {
            val routes = route(a, d, selected, maxDepth = 3, budget = TraversalBudget(maxRoutes = 1))

            routes.resourcePaths() shouldBe listOf(listOf(a, b, d))
            routes.completion shouldBe InspectionCompletion.Interrupted("route budget exceeded")
        }
    }

    test("a resource budget that admits exactly the resources on the route completes the search") {
        graphReads(diamond) {
            val routes = route(b, d, selected, maxDepth = 1, budget = TraversalBudget(maxResources = 2))

            routes.resourcePaths() shouldBe listOf(listOf(b, d))
            routes.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("a resource budget below the resources on the route interrupts the search without a route") {
        graphReads(diamond) {
            val routes = route(b, d, selected, maxDepth = 1, budget = TraversalBudget(maxResources = 1))

            routes.paths shouldBe emptyList()
            routes.completion shouldBe InspectionCompletion.Interrupted("resource budget exceeded")
        }
    }

    test("graph reads of a staged view follow the staged links instead of the saved ones") {
        val source = ResourceId(value = "source")
        val savedTarget = ResourceId(value = "saved_target")
        val stagedTarget = ResourceId(value = "staged_target")
        val saved =
            mapOf(
                source to graphRecord(source, listOf(savedTarget)),
                savedTarget to graphRecord(savedTarget, emptyList()),
                stagedTarget to graphRecord(stagedTarget, emptyList()),
            )
        graphReads(saved) {
            reachable(source, selected, maxDepth = 1).resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, savedTarget)
        }
        graphReads(saved, staged = mapOf(source to graphRecord(source, listOf(stagedTarget)))) {
            reachable(source, selected, maxDepth = 1).resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(source, stagedTarget)
            val occurrence = RealmGraphReads.occurrences(LinkInspectionQuery(setOf(source.toResourceId()), selected)).occurrences.single()
            RealmGraphReads
                .follow(occurrence)
                .shouldBeInstanceOf<Availability.Available<DraftBinding>>()
                .value.location.resource shouldBe stagedTarget

            val dependencies = observedInputs()
            (InputIdentity.Incoming(source, EDGE.id) in dependencies) shouldBe true
            observedContentAt(ValueLocation.of(source, ValuePath.root.field("outgoing"))) shouldBe true
        }
    }

    test("a resource linking to a target whose type is unavailable stays an undecided incoming candidate") {
        val source = ResourceId(value = "source")
        val target = ResourceId(value = "pending_target")
        val pending =
            graphRecord(target, emptyList())
                .copy(configuration = TypeSelection.createPending(definition = graphDefinition("missing"), arguments = emptyList()))
        graphReads(mapOf(source to graphRecord(source, listOf(target)), target to pending)) {
            val incoming = RealmGraphReads.incomingResources(target, RelationFamilyId(value = "selected"))

            incoming.knownMatches shouldBe emptyList()
            incoming.undecided.map { it.resource.toSkir() } shouldBe listOf(source)
            incoming.completion shouldBe InspectionCompletion.Complete
            (InputIdentity.Form(ValueLocation.of(target)) in observedInputs()) shouldBe true
        }
    }

    test("an unfilled link of a selected relation is reported while reachability through its sibling completes") {
        graphReads(sourceAndTarget) {
            val reachable = reachable(sourceResource, bothRelations, maxDepth = 1)

            reachable.resources.mapTo(linkedSetOf()) { it.id.toSkir() } shouldBe setOf(sourceResource, targetResource)
            reachable.unresolved.unfilled() shouldBe listOf(sourceResource to BAD_ENDPOINT, targetResource to BAD_ENDPOINT)
            reachable.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("an unfilled link of a selected relation is reported while the route through its sibling completes") {
        graphReads(sourceAndTarget) {
            val routes =
                RealmGraphReads.routes(
                    RouteQuery(setOf(sourceResource.toResourceId()), targetResource.toResourceId(), bothRelations, maxDepth = 1),
                )

            routes.resourcePaths() shouldBe listOf(listOf(sourceResource, targetResource))
            routes.unresolved.unfilled() shouldBe listOf(sourceResource to BAD_ENDPOINT, targetResource to BAD_ENDPOINT)
            routes.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("link inspection lists the filled occurrence and reports the unfilled one") {
        graphReads(sourceAndTarget) {
            val occurrences = RealmGraphReads.occurrences(LinkInspectionQuery(setOf(sourceResource.toResourceId()), bothRelations))

            occurrences.occurrences.map { it.id.endpoint } shouldBe listOf(EDGE_SOURCE)
            occurrences.unresolved.unfilled() shouldBe listOf(sourceResource to BAD_ENDPOINT)
            occurrences.completion shouldBe InspectionCompletion.Complete
        }
    }

    test("traversal depends on every field of the source that can hold a selected link") {
        graphReads(sourceAndTarget) {
            reachable(sourceResource, bothRelations, maxDepth = 1)

            val dependencies = observedInputs()
            listOf("bad", "outgoing", "buttons").forEach { field ->
                observedContentAt(ValueLocation.of(sourceResource, ValuePath.root.field(field))) shouldBe true
            }
            listOf("optional", "message", "nested", "expanding").forEach { field ->
                (InputIdentity.Form(ValueLocation.of(sourceResource, ValuePath.root.field(field))) in dependencies) shouldBe true
            }
        }
    }

    test("unfilled links inside list items and optional records are reported at their paths") {
        val source =
            sourceAndTarget
                .getValue(sourceResource)
                .with(
                    "buttons",
                    DataValue.named(
                        BUTTON_LIST_USE,
                        DataValue.listValue(
                            listOf(
                                ListItem(
                                    id = ItemId(value = "button"),
                                    value = DataValue.named(BUTTON_USE, DataValue.record(mapOf("target" to DataValue.UNFILLED))),
                                ),
                            ),
                        ),
                    ),
                ).with("optional", DataValue.named(OPTIONAL_LINK_HOLDER_USE, DataValue.record(mapOf("target" to DataValue.UNFILLED))))
        graphReads(sourceAndTarget + (sourceResource to source)) {
            reachable(sourceResource, RelationSelection.Contracts(setOf(BAD.id), TraversalDirection.FORWARD), maxDepth = 0)
                .unresolved
                .mapTo(linkedSetOf()) {
                    it
                        .shouldBeInstanceOf<UnresolvedLink.Unfilled>()
                        .occurrence.location.path
                } shouldBe
                setOf(
                    ValuePath.root.field("bad"),
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "buttons"),
                                PathSegment.createItem(id = ItemId(value = "button")),
                                PathSegment.createField(name = "target"),
                            ),
                    ),
                    ValuePath.root.field("optional").field("target"),
                )
        }
    }
}
