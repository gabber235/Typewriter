package com.typewritermc.realm.edit

import com.typewritermc.authoring.item
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.text
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toResourceIds
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.kernel.v1.resource_id.ResourceId

val CloneAndMoveTest by testSuite {
    /** The parent relation as ownership: a parent owns its children and deleting it deletes them. */
    val owning = parentRelation(RelationDeletePolicy.CASCADE, OWNERSHIP_FAMILY)

    test("moving a selection to another owner reparents every member and keeps their content") {
        val root = ResourceId(value = "root")
        val from = ResourceId(value = "from")
        val to = ResourceId(value = "to")
        val first = ResourceId(value = "first")
        val second = ResourceId(value = "second")
        val seed =
            mapOf(
                root to node(children = childItems(from, to)),
                from to
                    node(
                        parent = ownedBy(root, from),
                        children = childItems(first, second),
                    ),
                to to node(parent = ownedBy(root, to)),
                first to node(parent = ownedBy(from, first), label = "first"),
                second to node(parent = ownedBy(from, second), label = "second"),
            )
        RealmFixture.of(nodeCatalog(owning), seed).use { realm ->
            val origin = OperationOrigin(from.toResourceId(), realm.views.read { view -> view.links.values.filter { it.source == from } })

            realm
                .operate(
                    listOf(first, second),
                    origin,
                ) { move(listOf(first, second).toResourceIds(), to.toResourceId(), null) }
                .shouldBeCommitted()

            realm.resources.getValue(to).links("children") shouldBe listOf(first, second)
            realm.resources.getValue(from).links("children") shouldBe emptyList()
            realm.resources.getValue(first).link("parent") shouldBe to
            realm.resources.getValue(second).link("parent") shouldBe to
            realm.resources.getValue(first).text("label") shouldBe "first"
        }
    }

    test("a batch move the destination cannot hold is refused and changes nothing") {
        val ownerA = ResourceId(value = "owner_a")
        val ownerB = ResourceId(value = "owner_b")
        val destination = ResourceId(value = "single_owner")
        val childA = ResourceId(value = "child_a")
        val childB = ResourceId(value = "child_b")
        val seed =
            mapOf(
                ownerA to node(first = link(PAIR_FIRST, childA, path("second"))),
                ownerB to node(first = link(PAIR_FIRST, childB, path("second"))),
                destination to node(),
                childA to node(second = link(PAIR_SECOND, ownerA, path("first"))),
                childB to node(second = link(PAIR_SECOND, ownerB, path("first"))),
            )
        RealmFixture.of(nodeCatalog(pairRelation(families = OWNERSHIP_FAMILY)), seed).use { realm ->
            val before = realm.resources

            shouldThrow<IllegalArgumentException> {
                realm.operate(listOf(childA, childB)) { move(listOf(childA, childB).toResourceIds(), destination.toResourceId(), null) }
            }.message shouldBe "The destination cannot accept the complete resource selection"
            realm.resources shouldBe before
        }
    }

    test("duplicating a book and its page copies the owned closure once and keeps the outside link") {
        val root = ResourceId(value = "root")
        val book = ResourceId(value = "book")
        val page = ResourceId(value = "page")
        val element = ResourceId(value = "element")
        val outside = ResourceId(value = "outside")
        val outsideItem = ItemId(value = "outside")
        val bookLink = ItemId(value = "book_link")
        val seed =
            mapOf(
                // Every node is ownable, so the top node owns itself.
                root to node(parent = ownedBy(root, root), children = childItems(root, book, outside)),
                book to
                    node(
                        parent = ownedBy(root, book),
                        children = childItems(page),
                        manyFirst =
                            listOf(
                                ListItem(id = bookLink, value = link(MANY_FIRST, outside, path("manySecond").item(outsideItem))),
                            ),
                    ),
                page to
                    node(
                        parent = ownedBy(book, page),
                        children = childItems(element),
                    ),
                element to node(parent = ownedBy(page, element)),
                outside to
                    node(
                        parent = ownedBy(root, outside),
                        manySecond = listOf(ListItem(id = outsideItem, value = link(MANY_SECOND, book, path("manyFirst").item(bookLink)))),
                    ),
            )
        RealmFixture.of(nodeCatalog(owning, manyRelation()), seed).use { realm ->
            lateinit var copies: List<ResourceId>

            realm
                .operate(
                    listOf(book, page),
                ) { copies = duplicate(listOf(book, page).toResourceIds()).map { it.toSkir() } }
                .shouldBeCommitted()

            val (bookCopy, pageCopy) = copies
            val saved = realm.resources
            (saved.keys - seed.keys) shouldBe setOf(bookCopy, pageCopy, saved.getValue(pageCopy).links("children").single())
            saved.getValue(bookCopy).link("parent") shouldBe root
            saved.getValue(bookCopy).links("children") shouldBe listOf(pageCopy)
            saved.getValue(pageCopy).link("parent") shouldBe bookCopy
            saved.getValue(bookCopy).links("manyFirst") shouldBe listOf(outside)
            saved.getValue(outside).links("manySecond") shouldBe listOf(book, bookCopy)
        }
    }

    test("duplicating a resource copies its outgoing links and leaves incoming links on the original") {
        val source = ResourceId(value = "source")
        val outside = ResourceId(value = "outside")
        val incoming = ResourceId(value = "incoming")
        val outgoing = ItemId(value = "outgoing")
        val outsideInverse = ItemId(value = "outside_inverse")
        val incomingItem = ItemId(value = "incoming")
        val sourceInverse = ItemId(value = "source_inverse")
        val seed =
            mapOf(
                source to
                    node(
                        manyFirst =
                            listOf(
                                ListItem(id = outgoing, value = link(MANY_FIRST, outside, path("manySecond").item(outsideInverse))),
                            ),
                        manySecond =
                            listOf(
                                ListItem(id = sourceInverse, value = link(MANY_SECOND, incoming, path("manyFirst").item(incomingItem))),
                            ),
                    ),
                outside to
                    node(
                        manySecond =
                            listOf(
                                ListItem(id = outsideInverse, value = link(MANY_SECOND, source, path("manyFirst").item(outgoing))),
                            ),
                    ),
                incoming to
                    node(
                        manyFirst =
                            listOf(
                                ListItem(id = incomingItem, value = link(MANY_FIRST, source, path("manySecond").item(sourceInverse))),
                            ),
                    ),
            )
        RealmFixture.of(nodeCatalog(manyRelation()), seed).use { realm ->
            lateinit var copy: ResourceId

            realm.operate(listOf(source)) { copy = duplicate(listOf(source).toResourceIds()).single().toSkir() }.shouldBeCommitted()

            realm.resources.getValue(copy).links("manyFirst") shouldBe listOf(outside)
            realm.resources.getValue(copy).links("manySecond") shouldBe emptyList()
            realm.resources.getValue(incoming) shouldBe seed.getValue(incoming)
        }
    }

    test("duplicating a resource whose outside link has room for only one is refused and changes nothing") {
        val source = ResourceId(value = "source")
        val outside = ResourceId(value = "outside")
        val seed =
            mapOf(
                source to node(first = link(PAIR_FIRST, outside, path("second"))),
                outside to node(second = link(PAIR_SECOND, source, path("first"))),
            )
        RealmFixture.of(nodeCatalog(pairRelation()), seed).use { realm ->
            shouldThrow<IllegalArgumentException> {
                realm.operate(listOf(source)) { duplicate(listOf(source).toResourceIds()) }
            }.message shouldBe "No compatible inverse counterpart has capacity"
            realm.resources shouldBe seed
        }
    }

    test("duplicating a resource whose selected link lacks its counterpart is refused until the relation is repaired") {
        val source = ResourceId(value = "source")
        val outside = ResourceId(value = "outside")
        val seed = mapOf(source to node(first = link(PAIR_FIRST, outside, path("second"))), outside to node())
        RealmFixture.of(nodeCatalog(pairRelation()), seed).use { realm ->
            shouldThrow<IllegalArgumentException> {
                realm.operate(listOf(source)) { duplicate(listOf(source).toResourceIds()) }
            }.message shouldBe "Repair the selected relations before duplicating resources."
            realm.resources shouldBe seed
        }
    }

    test("running the same duplicating operation again is refused because its copy already exists") {
        val source = ResourceId(value = "source")
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(label = "source"))).use { realm ->
            realm.operate(listOf(source)) { duplicate(listOf(source).toResourceIds()) }.shouldBeCommitted()
            val saved = realm.resources

            shouldThrow<IllegalArgumentException> {
                realm.operate(listOf(source)) { duplicate(listOf(source).toResourceIds()) }
            }.message shouldBe "A copy identity already exists. Start a new operation."
            realm.resources shouldBe saved
        }
    }
}
