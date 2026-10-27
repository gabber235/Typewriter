@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.requireValid
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.Page
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagFields
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.library.tag
import com.typewritermc.library.taxonomy
import com.typewritermc.operations.Delete
import com.typewritermc.operations.Duplicate
import com.typewritermc.operations.LinkWith
import com.typewritermc.operations.LinkWithDuplicate
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.operations.MoveToOwner
import com.typewritermc.operations.MoveToOwnerInput
import com.typewritermc.operations.MoveToOwnerInputDefinition
import com.typewritermc.operations.Unlink
import com.typewritermc.operations.UnlinkInput
import com.typewritermc.operations.UnlinkInputDefinition
import com.typewritermc.operations.capability
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.testing.RealmCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.value
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.SetupHandle
import com.typewritermc.setup.setup
import com.typewritermc.testing.routes.fixtureGraphEntry
import com.typewritermc.testing.routes.fixtureGraphPage
import com.typewritermc.testing.routes.fixtureTimelineEntry
import com.typewritermc.testing.routes.fixtureTimelinePage
import com.typewritermc.types.Ref
import com.typewritermc.types.fieldMap
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationSelectionEffect
import skirout.editor.v1.resource_operations.ResolveDropCandidatesResult
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val ResourceOperationRoutesTest by testSuite {
    val tagGraph =
        setup("tag-graph") {
            val (parent, tag, loose) =
                taxonomy {
                    val parent = tags.tag("parent") { name = "Adventure" }
                    Triple(
                        parent,
                        tags.tag("tag") {
                            name = "Quest"
                            parents = setOf(parent)
                        },
                        tags.tag("loose") { name = "Loose" },
                    )
                }
            val book =
                library {
                    books.book("book") {
                        title = "Tutorial"
                        handle
                    }
                }
            TagGraph(book, tag, parent, loose)
        }

    val shelves =
        setup("shelves") {
            library {
                val moved =
                    books.book("source") {
                        title = "Source"
                        listOf(
                            pages.fixtureTimelinePage("first") {
                                chapter = HierarchyPath.parse("intro")
                                priority = 100
                                handle
                            },
                            pages.fixtureTimelinePage("second") {
                                chapter = HierarchyPath.parse("intro")
                                priority = 1
                                handle
                            },
                            pages.fixtureTimelinePage("other") {
                                chapter = HierarchyPath.parse("outro")
                                priority = 77
                                handle
                            },
                        )
                    }
                val (destination, residents) =
                    books.book("destination") {
                        title = "Destination"
                        handle to
                            listOf(
                                pages.fixtureTimelinePage("resident") {
                                    chapter = HierarchyPath.parse("intro")
                                    priority = 9
                                    handle
                                },
                                pages.fixtureTimelinePage("peer") {
                                    chapter = HierarchyPath.parse("outro")
                                    priority = 3
                                    handle
                                },
                            )
                    }
                Shelves(destination, moved, residents)
            }
        }

    val canvas =
        setup("canvas") {
            library {
                books.book("elements") {
                    title = "Library"
                    val (graph, graphEntry) =
                        pages.fixtureGraphPage("graph") {
                            name = "Page 0"
                            handle to elements.fixtureGraphEntry("graph-entry") { placement = GraphPlacement(0, 0, 2, 2) }
                        }
                    val (canvas, residentEntry) =
                        pages.fixtureGraphPage("canvas") {
                            name = "Page 1"
                            priority = 1
                            handle to elements.fixtureGraphEntry("resident-entry") { placement = GraphPlacement(0, 0, 2, 2) }
                        }
                    val (timeline, timelineEntry) =
                        pages.fixtureTimelinePage("timeline") {
                            name = "Page 2"
                            priority = 2
                            handle to elements.fixtureTimelineEntry("timeline-entry") { placement = TimelineEntryPlacement(0) }
                        }
                    Canvas(handle, graph, canvas, timeline, graphEntry, residentEntry, timelineEntry)
                }
            }
        }

    test("every resource gets the core operations its graph facts allow") {
        withSetup(tagGraph) { graph ->
            operationsOf(graph.book.resource) shouldBe setOf("MoveToOwner", "LinkWith", "Duplicate", "Delete")
            operationsOf(graph.tag.resource) shouldBe setOf("MoveToOwner", "LinkWith", "Unlink", "Duplicate", "LinkWithDuplicate", "Delete")
            operationsOf(graph.book.resource, graph.tag.resource) shouldBe setOf("MoveToOwner", "LinkWith", "Unlink", "Duplicate", "Delete")
            operationsOf(singleOf(LibraryDefinition.id)) shouldBe emptySet()
            operationsOf(singleOf(RealmRootDefinition.id)) shouldBe emptySet()
        }
    }

    test("operations resolve in group order and carry their capability and drop") {
        withSetup(tagGraph) { graph ->
            val resolved = (operations.resolve(graph.tag.resource) as ResolveResourceOperationsResult.ResolvedWrapper).value.operations
            resolved.map { it.definition.id.simpleName } shouldBe
                listOf("MoveToOwner", "LinkWith", "Unlink", "Duplicate", "LinkWithDuplicate", "Delete")
            val move = resolved.first().definition
            move.capability.value shouldBe operations.operation(MoveToOwner).capability.value
            move.drop?.hint shouldBe "Move here"
            resolved
                .last()
                .definition.presentation.shortcut shouldBe skirout.editor.v1.operation.OperationShortcut.DELETE
        }
    }

    test("a linked duplicate of a tag is saved under the same parents, linked to the original, and selected") {
        withSetup(tagGraph) { graph ->
            val before = resources
            val preview =
                operations.routes
                    .prepare(operations.prepare(operations.operation(LinkWithDuplicate), graph.tag.resource))
                    .shouldBeInstanceOf<AuthoringActionResult.PreviewWrapper>()
            resources shouldBe before

            commit(preview.value.edit.requireValid()) shouldBe CommitPreparedEditResponse.COMMITTED

            val saved = resources
            val copy = (saved.keys - before.keys).single()
            (preview.value.selection as OperationSelectionEffect.ReplaceWrapper).value.map { it.value } shouldBe listOf(copy.value)
            saved.getValue(graph.tag.resource).links("parents").toSet() shouldBe setOf(graph.parent.resource, copy)
            saved.getValue(copy).links("parents") shouldBe listOf(graph.parent.resource)
        }
    }

    test("moving pages to another book keeps their chapters and priorities") {
        withSetup(shelves, catalog = routeFixtureCatalog) { (destination, moved, residents) ->
            val before = resources

            val saved =
                operations.commit(
                    operations.prepare(
                        operations.operation(MoveToOwner),
                        moved[1].resource,
                        moved[0].resource,
                        moved[2].resource,
                        input = operations.input(MoveToOwnerInput(destination.id), MoveToOwnerInputDefinition.id),
                    ),
                )

            moved.forEach { page ->
                val id = page.resource
                saved.getValue(id).link("book") shouldBe destination.resource
                saved.getValue(id).value("chapter") shouldBe before.getValue(id).value("chapter")
                saved.getValue(id).value("priority") shouldBe before.getValue(id).value("priority")
            }
            saved.getValue(destination.resource).links("pages") shouldContainAll (residents + moved).map { it.resource }
        }
    }

    test("moving an entry into a page that is not a graph layout keeps its placement") {
        withSetup(canvas, catalog = routeFixtureCatalog) { page ->
            val before = resources

            val saved = move(page.graphEntry, page.timeline, PlacementAnchor(40.0, 40.0))

            val moved = saved.getValue(page.graphEntry.resource)
            moved.link("page") shouldBe page.timeline.resource
            moved.value("placement") shouldBe before.getValue(page.graphEntry.resource).value("placement")
        }
    }

    test("moving an entry into a graph layout places it clear of the members already there and keeps its size") {
        withSetup(canvas, catalog = routeFixtureCatalog) { page ->
            val saved = move(page.graphEntry, page.canvas)

            val moved = saved.getValue(page.graphEntry.resource)
            moved.link("page") shouldBe page.canvas.resource
            val placement = moved.graphPlacement()
            placement.intersectsWithGap(saved.getValue(page.residentEntry.resource).graphPlacement()) shouldBe false
            (placement.width to placement.height) shouldBe (2 to 2)
        }
    }

    test("moving an entry onto a graph canvas places it at the anchor") {
        withSetup(canvas, catalog = routeFixtureCatalog) { page ->
            val saved = move(page.graphEntry, page.canvas, PlacementAnchor(20.0, 20.0))

            saved.getValue(page.graphEntry.resource).graphPlacement() shouldBe GraphPlacement(19, 19, 2, 2)
        }
    }

    test("a preparation the planner rejects is invalid with the broken rule") {
        withSetup(tagGraph, catalog = RealmCatalog(operations = { origin -> listOf(orphanTag(origin)) })) { graph ->
            val result = operations.routes.prepare(operations.prepare(operations.operation("fixture.OrphanTag"), graph.tag.resource))

            result
                .shouldBeInstanceOf<AuthoringActionResult.InvalidErrorWrapper>()
                .value.diagnostics
                .map { it.code } shouldContain
                "owner_required"
        }
    }

    test("duplicating an entry inside a page that is not a graph layout needs no placement") {
        withSetup(canvas, catalog = routeFixtureCatalog) { page ->
            val before = resources

            val saved = operations.commit(operations.prepare(operations.operation(Duplicate), page.timelineEntry.resource))

            val copy = saved.getValue((saved.keys - before.keys).single())
            copy.link("page") shouldBe page.timeline.resource
            copy.value("placement") shouldBe before.getValue(page.timelineEntry.resource).value("placement")
        }
    }

    test("deleting a selection removes it with everything it owns") {
        withSetup(canvas, catalog = routeFixtureCatalog) { page ->
            val saved = operations.commit(operations.prepare(operations.operation(Delete), page.graph.resource))

            (page.graph.resource in saved) shouldBe false
            (page.graphEntry.resource in saved) shouldBe false
            (page.canvas.resource in saved) shouldBe true
        }
    }

    test("a tag dropped onto a book is linked through the book's tags") {
        withSetup(tagGraph) { graph ->
            val before = resources

            val saved = link(LinkWith, graph.tag, LinkWithInput(graph.book.id))

            saved.getValue(graph.book.resource).links("tags") shouldBe listOf(graph.tag.resource)
            saved.getValue(graph.tag.resource).fields shouldBe before.getValue(graph.tag.resource).fields
        }
    }

    test("a tag dropped onto a tag becomes its child") {
        withSetup(tagGraph) { graph ->
            val saved = link(LinkWith, graph.loose, LinkWithInput(graph.tag.id))

            saved.getValue(graph.loose.resource).links("parents") shouldBe listOf(graph.tag.resource)
            saved.getValue(graph.tag.resource).links("parents") shouldBe listOf(graph.parent.resource)
        }
    }

    test("linking a tag to the parent it already has changes nothing") {
        withSetup(tagGraph) { graph ->
            val before = resources

            link(LinkWith, graph.tag, LinkWithInput(graph.parent.id)) shouldBe before
        }
    }

    test("unlinking a tag from its parent removes the link") {
        withSetup(tagGraph) { graph ->
            val saved = link(Unlink, graph.tag, UnlinkInput(graph.parent.id))

            saved.getValue(graph.tag.resource).links("parents") shouldBe emptyList()
        }
    }

    test("a tag cycle written directly into the parents field is refused and changes nothing") {
        withSetup(tagGraph) { graph ->
            // The panel's raw write of the field, as an author editing it by hand sends it.
            val cyclic =
                encoder.record(
                    TagDefinition.id.use(),
                    Tag(taxonomy = Ref(graph.parent.id), parents = setOf(Ref(graph.tag.id)), placement = GraphPlacement()),
                )
            val write =
                EditIntent.createSetValue(
                    at = ValueLocation.of(graph.parent.resource, TagFields.parents.path),
                    value = cyclic.fieldMap.getValue("parents"),
                )

            expectRefused(write).codes.toSet() shouldBe setOf("relation_cycle")
        }
    }

    test("drop candidates come from the declared candidates of enabled operations") {
        withSetup(tagGraph + canvas, catalog = routeFixtureCatalog) { (graph, page) ->
            val entry = drops(page.graphEntry.resource)
            entry.keys shouldBe setOf("MoveToOwner")
            entry.getValue("MoveToOwner").destinations.toSet() shouldBe setOf(page.canvas.resource, page.timeline.resource)
            entry.getValue("MoveToOwner").complete shouldBe true

            val tag = drops(graph.tag.resource)
            tag.getValue("LinkWith").destinations.toSet() shouldBe setOf(graph.book.resource, page.book.resource, graph.loose.resource)
            tag.getValue("Unlink").destinations shouldBe listOf(graph.parent.resource)
            drops(singleOf(LibraryDefinition.id)) shouldBe emptyMap()
        }
    }

    test("drop candidates are capped and marked incomplete") {
        withSetup(tagGraph, catalog = RealmCatalog(operations = { origin -> listOf(manyCandidates(origin)) })) { graph ->
            val many = drops(graph.tag.resource).getValue("ManyCandidates")

            many.destinations.size shouldBe 200
            many.complete shouldBe false
        }
    }

    test("a failing availability callback fails menu resolution but not drops or the preparation of another operation") {
        withSetup(tagGraph, catalog = RealmCatalog(operations = { origin -> listOf(brokenAvailability(origin)) })) { graph ->
            operations
                .resolve(graph.tag.resource)
                .shouldBeInstanceOf<ResolveResourceOperationsResult.FailedErrorWrapper>()
                .value.diagnostics
                .map { it.code } shouldBe listOf("resolution_failed")
            // Drops only evaluate operations that declare a drop field.
            operations.dropCandidates(graph.tag.resource).shouldBeInstanceOf<ResolveDropCandidatesResult.ResolvedWrapper>()
            operations.routes
                .prepare(operations.prepare(operations.operation(Delete), graph.tag.resource))
                .shouldBeInstanceOf<AuthoringActionResult.PreviewWrapper>()
            operations.routes
                .prepare(operations.prepare(operations.operation("fixture.BrokenAvailability"), graph.tag.resource))
                .shouldBeInstanceOf<AuthoringActionResult.FailedErrorWrapper>()
                .value.diagnostics
                .map { it.code } shouldBe listOf("resolution_failed")
        }
    }

    test("an operation whose callbacks deny permission is refused as permission_denied when resolving, dropping or preparing it") {
        withSetup(tagGraph, catalog = RealmCatalog(operations = { origin -> listOf(guarded(origin)) })) { graph ->
            val denied = listOf("permission_denied" to LOCKED)

            operations
                .resolve(graph.tag.resource)
                .shouldBeInstanceOf<ResolveResourceOperationsResult.PermissionDeniedErrorWrapper>()
                .value.diagnostics
                .map { it.code to it.message } shouldBe denied
            operations
                .dropCandidates(graph.tag.resource)
                .shouldBeInstanceOf<ResolveDropCandidatesResult.PermissionDeniedErrorWrapper>()
                .value.diagnostics
                .map { it.code to it.message } shouldBe denied
            operations.routes
                .prepare(operations.prepare(operations.operation("fixture.Guarded"), graph.tag.resource))
                .shouldBeInstanceOf<AuthoringActionResult.PermissionDeniedErrorWrapper>()
                .value.diagnostics
                .map { it.code to it.message } shouldBe denied
        }
    }

    test("a resolution against an older saved observation answers with the current one") {
        withSetup(tagGraph) { graph ->
            val request = operations.resolveRequest(graph.book.resource)
            val current = request.context.confirmedObservation

            val response =
                operations.routes.resolve(
                    request.copy(context = request.context.copy(confirmedObservation = AuthoringObservationId(value = "previous"))),
                )

            response.shouldBeInstanceOf<ResolveResourceOperationsResult.StaleObservationErrorWrapper>().value.actual shouldBe current
        }
    }

    test("a resolution against an older catalog answers with the current generation") {
        withSetup(tagGraph) { graph ->
            val request = operations.resolveRequest(graph.book.resource)

            val response =
                operations.routes.resolve(
                    request.copy(invocation = request.invocation.copy(catalog = CatalogGeneration(value = "previous"))),
                )

            response.shouldBeInstanceOf<ResolveResourceOperationsResult.CatalogChangedErrorWrapper>().value.actualGeneration shouldBe
                request.invocation.catalog
        }
    }

    test("a resolution without targets is invalid") {
        withSetup(tagGraph) { graph ->
            val request = operations.resolveRequest(graph.book.resource)

            val response = operations.routes.resolve(request.copy(invocation = request.invocation.copy(targets = emptyList())))

            response
                .shouldBeInstanceOf<ResolveResourceOperationsResult.InvalidErrorWrapper>()
                .value.diagnostics
                .map { it.code } shouldBe
                listOf("invalid_operation_context")
        }
    }
}
