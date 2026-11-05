package com.typewritermc.realm.authoring

import com.typewritermc.realm.edit.MANY_FIRST
import com.typewritermc.realm.edit.OWNERSHIP_FAMILY
import com.typewritermc.realm.edit.PAIR_FIRST
import com.typewritermc.realm.edit.link
import com.typewritermc.realm.edit.manyRelation
import com.typewritermc.realm.edit.node
import com.typewritermc.realm.edit.nodeCatalog
import com.typewritermc.realm.edit.pairRelation
import com.typewritermc.realm.search.ownershipClosure
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.kernel.v1.resource_id.ResourceId

val OwnershipClosureTest by testSuite {
    /** Nodes own each other through the ownership pair relation and refer to another node through a many relation outside it. */
    val catalog = nodeCatalog(pairRelation(families = OWNERSHIP_FAMILY), manyRelation())

    test("the ownership closure of a resource holds its owned descendants, ends at a cycle and leaves out other relations") {
        val root = ResourceId(value = "root")
        val child = ResourceId(value = "child")
        val grandchild = ResourceId(value = "grandchild")
        val outside = ResourceId(value = "outside")
        val resources =
            mapOf(
                root to
                    node(
                        first = link(PAIR_FIRST, child),
                        manyFirst = listOf(ListItem(id = ItemId(value = "related"), value = link(MANY_FIRST, outside))),
                    ),
                child to node(first = link(PAIR_FIRST, grandchild)),
                grandchild to node(first = link(PAIR_FIRST, root)),
                outside to node(),
            )
        catalog.lease().use { lease ->
            val view = AuthoringView(lease, resources, ResourceValueMapper.discover(resources).associateBy { it.id })

            view.ownershipClosure(setOf(root)) shouldBe setOf(root, child, grandchild)
        }
    }
}
