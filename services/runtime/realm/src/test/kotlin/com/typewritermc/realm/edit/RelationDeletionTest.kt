package com.typewritermc.realm.edit

import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.operation.RuntimeOperationPreparation
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.Refusal
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.itemIds
import com.typewritermc.realm.testing.linkOrNull
import com.typewritermc.realm.testing.refusals
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.types.toResourceIds
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.kernel.v1.resource_id.ResourceId

val RelationDeletionTest by testSuite {
    val first = ResourceId(value = "first")

    val second = ResourceId(value = "second")

    val unrelated = ResourceId(value = "unrelated")

    val parent = ResourceId(value = "parent")

    val child = ResourceId(value = "child")

    val childItem = ItemId(value = "child")

    /** Two nodes paired through a relation that restricts deleting either side, and an unrelated node. */
    val restricted =
        nodeCatalog(pairRelation(RelationDeletePolicy.RESTRICT)) to
            mapOf(
                first to node(first = link(PAIR_FIRST, second, path("second"))),
                second to node(second = link(PAIR_SECOND, first, path("first"))),
                unrelated to node(),
            )

    /** A parent whose children list holds one child, linked both ways. */
    val family =
        mapOf(
            parent to node(children = listOf(ListItem(id = childItem, value = link(PARENT_FIRST, child, path("parent"))))),
            child to node(parent = link(PARENT_SECOND, parent, path("children").item(childItem))),
        )

    test("deleting both sides of a restricted relation in one run deletes both") {
        RealmFixture.of(restricted.first, restricted.second).use { realm ->
            realm.commit(EditIntent.createDeleteResource(id = first), EditIntent.createDeleteResource(id = second)).shouldBeCommitted()

            realm.resources.keys shouldBe setOf(unrelated)
        }
    }

    test("deleting one side of a restricted relation is refused at that side") {
        RealmFixture.of(restricted.first, restricted.second).use { realm ->
            realm.expectRefused(EditIntent.createDeleteResource(id = first)).refusals shouldBe
                listOf(Refusal(first.value, "relation_restricts_deletion"))
        }
    }

    test("deletes of both restricted sides separated by another write are refused") {
        RealmFixture.of(restricted.first, restricted.second).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createDeleteResource(id = first),
                    EditIntent.createSetValue(at = at(unrelated, "label"), value = DataValue.StringValueWrapper("between")),
                    EditIntent.createDeleteResource(id = second),
                ).refusals shouldBe listOf(Refusal(first.value, "relation_restricts_deletion"))
        }
    }

    test("deleting a child removes its item from the parent's collection") {
        RealmFixture.of(nodeCatalog(parentRelation()), family).use { realm ->
            realm.commit(EditIntent.createDeleteResource(id = child)).shouldBeCommitted()

            realm.resources.keys shouldBe setOf(parent)
            realm.resources.getValue(parent).itemIds("children") shouldBe emptyList()
        }
    }

    test("deleting a parent that clears its children clears each child's link") {
        RealmFixture.of(nodeCatalog(parentRelation()), family).use { realm ->
            realm.commit(EditIntent.createDeleteResource(id = parent)).shouldBeCommitted()

            realm.resources.keys shouldBe setOf(child)
            realm.resources
                .getValue(child)
                .linkOrNull("parent")
                .shouldBeNull()
        }
    }

    test("deleting a parent that cascades to its children deletes them too") {
        RealmFixture.of(nodeCatalog(parentRelation(RelationDeletePolicy.CASCADE)), family).use { realm ->
            realm.commit(EditIntent.createDeleteResource(id = parent)).shouldBeCommitted()

            realm.resources shouldBe emptyMap()
        }
    }

    test("deleting a selection of a parent and the child it cascades to deletes both") {
        RealmFixture.of(nodeCatalog(parentRelation(RelationDeletePolicy.CASCADE)), family).use { realm ->
            val selection = listOf(parent, child).toResourceIds()

            realm
                .commit {
                    RuntimeOperationPreparation(OperationInvocation("delete-selection", selection), PreparationChoices(), this)
                        .delete(selection)
                }.shouldBeCommitted()

            realm.resources shouldBe emptyMap()
        }
    }
}
