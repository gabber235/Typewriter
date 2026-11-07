package com.typewritermc.realm.edit

import com.typewritermc.authoring.requireValid
import com.typewritermc.operations.Duplicate
import com.typewritermc.operations.LinkWith
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.realm.routeFixtureCatalog
import com.typewritermc.realm.routes.drops
import com.typewritermc.realm.routes.operations
import com.typewritermc.realm.routes.operationsOf
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.commit
import com.typewritermc.realm.testing.commitDefinition
import com.typewritermc.realm.testing.contentLink
import com.typewritermc.realm.testing.declares
import com.typewritermc.realm.testing.delete
import com.typewritermc.realm.testing.entryRef
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.formulaPage
import com.typewritermc.realm.testing.graphLinkRuns
import com.typewritermc.realm.testing.graphLinksOf
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.listType
import com.typewritermc.realm.testing.listValue
import com.typewritermc.realm.testing.plainType
import com.typewritermc.realm.testing.plainVar
import com.typewritermc.realm.testing.publicationBlockers
import com.typewritermc.realm.testing.record
import com.typewritermc.realm.testing.recordValue
import com.typewritermc.realm.testing.refTo
import com.typewritermc.realm.testing.rename
import com.typewritermc.realm.testing.setGiver
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeRejected
import com.typewritermc.realm.testing.shouldContainLocation
import com.typewritermc.realm.testing.usageRuns
import com.typewritermc.realm.testing.usagesOf
import com.typewritermc.realm.testing.value
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.setup.setup
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.integer
import com.typewritermc.types.nullable
import com.typewritermc.types.toResourceId
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldNotBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.kernel.v1.resource_id.ResourceId

val ContentReferencesTest by testSuite {
    val page =
        setup("content-references") {
            formulaPage {
                val smith = smith()
                val jones = smith("jones")
                definition(
                    "gift",
                    declares {
                        record {
                            field("giver", entryRef)
                            field("gold", intUse)
                        }
                    },
                ) { recordValue(it, "giver" to contentLink(smith), "gold" to DataValue.integer(5)) }
                definition("optional", declares { record { field("giver", entryRef.nullable()) } }) {
                    recordValue(it, "giver" to contentLink(smith))
                }
                definition("loan", declares { record { field("giver", entryRef) } }) { recordValue(it, "giver" to contentLink(jones)) }
            }
        }

    test("a record can hold two references in single fields") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val pair =
                declares {
                    record {
                        field("giver", entryRef)
                        field("helper", entryRef)
                    }
                }
            val id =
                commitDefinition("pair", pair) {
                    plainVar(it.use, recordValue(it.use, "giver" to contentLink(demo.smith), "helper" to contentLink(demo.smith)))
                }.created()
            value(id, "value", "value", "helper") shouldBe contentLink(demo.smith)
        }
    }

    test("a list of references commits") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val id =
                commitDefinition("givers", plainType(listType(entryRef))) {
                    plainVar(it.use, listValue(entryRef, contentLink(demo.smith), contentLink(demo.smith)))
                }.created()
            usagesOf(demo.smith) shouldContain id
        }
    }

    test("linksOf does not list a content reference, and a check over it does not rerun when one appears") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            graphLinksOf(demo.smith)
            val runs = graphLinkRuns(demo.smith)
            val id =
                commitDefinition("givers", plainType(listType(entryRef))) {
                    plainVar(it.use, listValue(entryRef, contentLink(demo.smith)))
                }.created()

            graphLinksOf(demo.smith) shouldNotContain id
            graphLinkRuns(demo.smith) shouldBe runs
        }
    }

    test("usages list a content reference, and a check over usages reruns when one appears") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            usagesOf(demo.smith)
            val runs = usageRuns(demo.smith)
            val id =
                commitDefinition("givers", plainType(listType(entryRef))) {
                    plainVar(it.use, listValue(entryRef, contentLink(demo.smith)))
                }.created()

            usagesOf(demo.smith) shouldContain id
            usageRuns(demo.smith) shouldBe runs + 1
        }
    }

    test("a reference to the wrong resource type is refused and nothing changes") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = record(demo.gift)
            commit(setGiver(demo.gift, to = demo.pageId)).shouldBeRejected("binding_target_type_mismatch")
            record(demo.gift) shouldBe before
        }
    }

    test("deleting a target empties a required reference and blocks publish") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.smith)).shouldBeCommitted()
            value(demo.gift, "value", "value", "giver") shouldBe DataValue.UNFILLED
            publicationBlockers() shouldContainLocation demo.gift
        }
    }

    test("deleting a target nulls a nullable reference") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            commit(delete(demo.smith)).shouldBeCommitted()
            value(demo.named("optional"), "value", "value", "giver") shouldBe DataValue.NULL
        }
    }

    test("renaming a target writes nothing to the reference holder") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val before = record(demo.gift)
            commit(rename(demo.smith, "blacksmith")).shouldBeCommitted()
            record(demo.gift) shouldBe before
        }
    }

    test("the target lists its holder as a usage") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            usagesOf(demo.smith) shouldContain demo.gift
            usagesOf(demo.smith) shouldNotContain demo.named("loan")
        }
    }

    test("a Ref can be a type argument directly") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val id = commitDefinition("ref", plainType(entryRef)) { plainVar(it.use, contentLink(demo.smith)) }.created()
            usagesOf(demo.smith) shouldContain id
        }
    }

    test("a Ref to a non resource type is refused as a declaration and nothing changes") {
        withSetup(page, catalog = routeFixtureCatalog) {
            val before = resources
            commitDefinition("bad", declares { record { field("giver", refTo(intUse)) } }).reply.shouldBeRejected("argument_bound")
            resources shouldBe before
        }
    }

    test("a One link inside a list is still refused") {
        val target = ResourceId(value = "target")
        RealmFixture.of(nodeCatalog(pairRelation(), childItem = linkType(PAIR_FIRST)), mapOf(target to node())).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createCreateResource(
                        id = ResourceId(value = "holder"),
                        record = node(children = listOf(ListItem(id = ItemId(value = "a"), value = link(PAIR_FIRST, target)))),
                    ),
                ).codes shouldContain "endpoint_binding_cardinality_mismatch"
        }
    }

    test("a resource only content references point at offers no unlink") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            operationsOf(demo.smith) shouldNotContain "Unlink"
        }
    }

    test("an emptied content reference cannot be filled by linking an entry") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val jones = demo.named("jones")
            commit(delete(demo.smith)).shouldBeCommitted()
            drops(jones)["LinkWith"]?.destinations.orEmpty() shouldNotContain demo.gift
            val link =
                operations.prepare(
                    operations.operation(LinkWith),
                    jones,
                    input = operations.input(LinkWithInput(demo.gift.toResourceId()), LinkWithInputDefinition.id),
                )
            operations.routes.prepare(link).shouldNotBeInstanceOf<AuthoringActionResult.PreviewWrapper>()
        }
    }

    test("an emptied content reference that could hold its own holder offers no link with duplicate") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val anyResource = refTo(ResourceDefinition.use.use)
            val holder =
                commitDefinition("holder", declares { record { field("subject", anyResource) } }) {
                    plainVar(it.use, recordValue(it.use, "subject" to contentLink(demo.smith, anyResource)))
                }.created()
            commit(delete(demo.smith)).shouldBeCommitted()
            operationsOf(holder) shouldNotContain "LinkWithDuplicate"
        }
    }

    test("a duplicate prepared before a content reference to its subject appears still commits") {
        withSetup(page, catalog = routeFixtureCatalog) { demo ->
            val jones = demo.named("jones")
            val preview =
                operations.routes
                    .prepare(operations.prepare(operations.operation(Duplicate), jones))
                    .shouldBeInstanceOf<AuthoringActionResult.PreviewWrapper>()
            commit(setGiver(demo.gift, to = jones)).shouldBeCommitted()
            commit(preview.value.edit.requireValid()).shouldBeCommitted()
        }
    }
}
