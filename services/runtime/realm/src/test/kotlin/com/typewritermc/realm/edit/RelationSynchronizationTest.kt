package com.typewritermc.realm.edit

import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.itemIds
import com.typewritermc.realm.testing.linkAt
import com.typewritermc.realm.testing.linkOrNull
import com.typewritermc.realm.testing.linkTargets
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.testkit.definitions
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val RelationSynchronizationTest by testSuite {
    val source = ResourceId(value = "source")

    val target = ResourceId(value = "target")

    val other = ResourceId(value = "other")

    /** The node catalog whose `children` embed wrapper records, each able to hold one nested link back. */
    val wrapperCatalog = nodeCatalog(nestedRelation(EndpointCardinality.MANY), childItem = WRAPPER)

    test("connecting a link writes both sides and disconnecting it clears both") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(), target to node())).use { realm ->
            val inverse = occurrence(PAIR_SECOND, at(target, "second"), source)

            realm.commit(connect(PAIR_FIRST, at(source, "first"), target, CounterpartChoice.ExistingWrapper(inverse))).shouldBeCommitted()

            realm.resources.getValue(source).linkOrNull("first") shouldBe LinkTarget(resource = target, opposite = path("second"))
            realm.resources.getValue(target).linkOrNull("second") shouldBe LinkTarget(resource = source, opposite = path("first"))

            realm
                .commit(
                    EditIntent.DisconnectRelationWrapper(LinkOccurrenceId(endpoint = PAIR_FIRST, location = at(source, "first"))),
                ).shouldBeCommitted()

            realm.resources.shouldHoldNoPairLink(source, target)
        }
    }

    test("connecting a scalar link appends its inverse to the target's collection") {
        RealmFixture.of(nodeCatalog(parentRelation()), mapOf(target to node(), source to node())).use { realm ->
            realm.commit(connect(PARENT_SECOND, at(source, "parent"), target)).shouldBeCommitted()

            val parent = realm.resources.getValue(target)
            val item = parent.itemIds("children").single()
            parent.linkTargets("children") shouldBe listOf(LinkTarget(resource = source, opposite = path("parent")))
            realm.resources.getValue(source).linkOrNull("parent") shouldBe
                LinkTarget(resource = target, opposite = path("children").item(item))
        }
    }

    test("connecting a scalar link fills the target's unfilled collection with its inverse") {
        val seed = mapOf(target to node().with("children", DataValue.UNFILLED), source to node())
        RealmFixture.of(nodeCatalog(parentRelation()), seed).use { realm ->
            realm.commit(connect(PARENT_SECOND, at(source, "parent"), target)).shouldBeCommitted()

            realm.resources.getValue(target).links("children") shouldBe listOf(source)
        }
    }

    test("connecting a proposed collection item writes the scalar inverse on the target") {
        val item = ItemId(value = "page_occurrence")
        val occurrence = ValueLocation.of(target, path("children").item(item))
        RealmFixture.of(nodeCatalog(parentRelation()), mapOf(target to node(), source to node())).use { realm ->
            realm.commit(connect(PARENT_FIRST, occurrence, source)).shouldBeCommitted()

            val parent = realm.resources.getValue(target)
            parent.itemIds("children") shouldBe listOf(item)
            parent.linkTargets("children") shouldBe listOf(LinkTarget(resource = source, opposite = path("parent")))
            realm.resources.getValue(source).linkOrNull("parent") shouldBe LinkTarget(resource = target, opposite = occurrence.path)
        }
    }

    test("connecting a proposed item of an unfilled collection fills the collection with it") {
        val item = ItemId(value = "page_occurrence")
        val occurrence = ValueLocation.of(target, path("children").item(item))
        val seed = mapOf(target to node().with("children", DataValue.UNFILLED), source to node())
        RealmFixture.of(nodeCatalog(parentRelation()), seed).use { realm ->
            realm.commit(connect(PARENT_FIRST, occurrence, source)).shouldBeCommitted()

            realm.resources.getValue(target).itemIds("children") shouldBe listOf(item)
            realm.resources.getValue(source).linkOrNull("parent") shouldBe LinkTarget(resource = target, opposite = occurrence.path)
        }
    }

    test("setting a link writes its inverse and clearing the link removes the inverse") {
        RealmFixture.of(nodeCatalog(parentRelation()), mapOf(target to node(), source to node())).use { realm ->
            realm.commit(EditIntent.createSetValue(at = at(source, "parent"), value = link(PARENT_SECOND, target))).shouldBeCommitted()

            realm.resources.getValue(target).links("children") shouldBe listOf(source)

            realm.commit(EditIntent.createSetValue(at = at(source, "parent"), value = DataValue.UNFILLED)).shouldBeCommitted()

            realm.resources.getValue(target).links("children") shouldBe emptyList()
            realm.resources
                .getValue(source)
                .linkOrNull("parent")
                .shouldBeNull()
        }
    }

    test("removing a collection item clears its scalar inverse") {
        val item = ItemId(value = "page_occurrence")
        val seed =
            mapOf(
                target to node(children = listOf(ListItem(id = item, value = link(PARENT_FIRST, source, path("parent"))))),
                source to node(parent = link(PARENT_SECOND, target, path("children").item(item))),
            )
        RealmFixture.of(nodeCatalog(parentRelation()), seed).use { realm ->
            realm.commit(EditIntent.createRemove(at = at(target, "children"), item = item)).shouldBeCommitted()

            realm.resources
                .getValue(source)
                .linkOrNull("parent")
                .shouldBeNull()
            realm.resources.getValue(target).itemIds("children") shouldBe emptyList()
        }
    }

    test("setting and clearing a record that contains a link writes and clears the nested link's inverse") {
        val nested = path("wrapper").field("inner")
        RealmFixture.of(nodeCatalog(nestedRelation()), mapOf(source to node(), target to node())).use { realm ->
            realm
                .commit(
                    EditIntent.createSetValue(at = at(source, "wrapper"), value = wrapper(link(NESTED_FIRST, target))),
                ).shouldBeCommitted()

            realm.resources.getValue(source).linkAt(nested) shouldBe LinkTarget(resource = target, opposite = path("nestedSecond"))
            realm.resources.getValue(target).linkOrNull("nestedSecond") shouldBe LinkTarget(resource = source, opposite = nested)

            realm.commit(EditIntent.createSetValue(at = at(source, "wrapper"), value = wrapper(DataValue.UNFILLED))).shouldBeCommitted()

            realm.resources
                .getValue(target)
                .linkOrNull("nestedSecond")
                .shouldBeNull()
        }
    }

    test("a list may link one target twice and disconnecting one occurrence keeps the other") {
        val first = ItemId(value = "first")
        val second = ItemId(value = "second")
        val repeated =
            node(
                manyFirst = listOf(ListItem(id = first, value = link(MANY_FIRST, target))),
            ).let { it }
        RealmFixture.of(nodeCatalog(manyRelation()), mapOf(target to node())).use { realm ->
            realm
                .commit(
                    EditIntent.createCreateResource(
                        id = source,
                        record =
                            node(
                                manyFirst =
                                    listOf(
                                        ListItem(id = first, value = link(MANY_FIRST, target)),
                                        ListItem(id = second, value = link(MANY_FIRST, target)),
                                    ),
                            ),
                    ),
                ).shouldBeCommitted()
            realm.resources.getValue(source).links("manyFirst") shouldBe listOf(target, target)

            realm
                .commit(
                    EditIntent.DisconnectRelationWrapper(
                        LinkOccurrenceId(endpoint = MANY_FIRST, location = ValueLocation.of(source, path("manyFirst").item(first))),
                    ),
                ).shouldBeCommitted()

            realm.resources.getValue(source).itemIds("manyFirst") shouldBe listOf(second)
            realm.resources.getValue(source).links("manyFirst") shouldBe listOf(target)
        }
    }

    test("removing one of two repeated links keeps the other") {
        val removed = ItemId(value = "removed")
        val retained = ItemId(value = "retained")
        val seed =
            mapOf(
                source to
                    node(
                        manyFirst =
                            listOf(
                                ListItem(id = removed, value = link(MANY_FIRST, target)),
                                ListItem(id = retained, value = link(MANY_FIRST, target)),
                            ),
                    ),
                target to node(),
            )
        RealmFixture.of(nodeCatalog(manyRelation()), seed).use { realm ->
            realm.commit(EditIntent.createRemove(at = at(source, "manyFirst"), item = removed)).shouldBeCommitted()

            realm.resources.getValue(source).itemIds("manyFirst") shouldBe listOf(retained)
            realm.resources.getValue(source).links("manyFirst") shouldBe listOf(target)
        }
    }

    test("connecting two one sided occurrences pairs them in place") {
        val sourceItem = path("manyFirst").item(ItemId(value = "source_occurrence"))
        val targetItem = path("manySecond").item(ItemId(value = "target_occurrence"))
        val seed =
            mapOf(
                source to node(manyFirst = listOf(ListItem(id = ItemId(value = "source_occurrence"), value = link(MANY_FIRST, target)))),
                target to node(manySecond = listOf(ListItem(id = ItemId(value = "target_occurrence"), value = link(MANY_SECOND, source)))),
            )
        RealmFixture.of(nodeCatalog(manyRelation()), seed).use { realm ->
            val inverse = occurrence(MANY_SECOND, ValueLocation.of(target, targetItem), source)

            realm
                .commit(connect(MANY_FIRST, ValueLocation.of(source, sourceItem), target, CounterpartChoice.ExistingWrapper(inverse)))
                .shouldBeCommitted()

            realm.resources.getValue(source).linkTargets("manyFirst") shouldBe listOf(LinkTarget(resource = target, opposite = targetItem))
            realm.resources.getValue(target).linkTargets("manySecond") shouldBe listOf(LinkTarget(resource = source, opposite = sourceItem))
        }
    }

    test("two links whose opposites cross each other are refused at all four occurrences") {
        val sourceFirst = path("manyFirst").item(ItemId(value = "source_first"))
        val sourceSecond = path("manyFirst").item(ItemId(value = "source_second"))
        val targetFirst = path("manySecond").item(ItemId(value = "target_first"))
        val targetSecond = path("manySecond").item(ItemId(value = "target_second"))
        RealmFixture.of(nodeCatalog(manyRelation())).use { realm ->
            val problems =
                realm.expectRefused(
                    EditIntent.createCreateResource(
                        id = source,
                        record =
                            node(
                                manyFirst =
                                    listOf(
                                        ListItem(id = ItemId(value = "source_first"), value = link(MANY_FIRST, target, targetFirst)),
                                        ListItem(id = ItemId(value = "source_second"), value = link(MANY_FIRST, target, targetSecond)),
                                    ),
                            ),
                    ),
                    EditIntent.createCreateResource(
                        id = target,
                        record =
                            node(
                                manySecond =
                                    listOf(
                                        ListItem(id = ItemId(value = "target_first"), value = link(MANY_SECOND, source, sourceSecond)),
                                        ListItem(id = ItemId(value = "target_second"), value = link(MANY_SECOND, source, sourceFirst)),
                                    ),
                            ),
                    ),
                )

            problems.map { it.location to it.code }.toSet() shouldBe
                setOf(
                    ValueLocation.of(source, sourceFirst) to "opposite_occurrence_mismatch",
                    ValueLocation.of(source, sourceSecond) to "opposite_occurrence_mismatch",
                    ValueLocation.of(target, targetFirst) to "opposite_occurrence_mismatch",
                    ValueLocation.of(target, targetSecond) to "opposite_occurrence_mismatch",
                )
        }
    }

    test("connecting, disconnecting and connecting again in one edit embeds two inverses and links only the last") {
        RealmFixture.of(wrapperCatalog, mapOf(source to node(), target to node())).use { realm ->
            val connected = connection(NESTED_SECOND, at(source, "nestedSecond"), target, newWrapper(at(target, "children")))

            realm
                .commit {
                    connect(connected)
                    disconnect(connected.source.id)
                    connect(connected)
                }.shouldBeCommitted()

            val (released, linked) = realm.resources.getValue(target).itemIds("children")
            val inverse = path("children").item(linked).field("inner")
            realm.resources
                .getValue(target)
                .linkAt(path("children").item(released).field("inner"))
                .shouldBeNull()
            realm.resources.getValue(target).linkAt(inverse) shouldBe LinkTarget(resource = source, opposite = path("nestedSecond"))
            realm.resources.getValue(source).linkOrNull("nestedSecond") shouldBe LinkTarget(resource = target, opposite = inverse)
        }
    }

    test("an inferred inverse keeps its identity when the edit is composed after another write") {
        val seed = mapOf(target to node(), source to node())
        val alone =
            RealmFixture.of(nodeCatalog(parentRelation()), seed).use { realm ->
                val edit = realm.asUser("author").edit { connect(connection(PARENT_SECOND, at(source, "parent"), target)) }
                realm.commit(realm.prepare(edit.intents)).shouldBeCommitted()
                realm.resources
                    .getValue(target)
                    .itemIds("children")
                    .single()
            }
        val composed =
            RealmFixture.of(nodeCatalog(parentRelation()), seed).use { realm ->
                val edit = realm.asUser("author").edit { connect(connection(PARENT_SECOND, at(source, "parent"), target)) }
                val earlier = EditIntent.createSetValue(at = at(target, "label"), value = DataValue.StringValueWrapper("earlier draft"))
                realm.commit(realm.prepare(listOf(earlier) + edit.intents)).shouldBeCommitted()
                realm.resources
                    .getValue(target)
                    .itemIds("children")
                    .single()
            }

        composed shouldBe alone
    }

    test("a connect that embeds a new inverse conflicts when the target changed after the author loaded it") {
        RealmFixture.of(wrapperCatalog, mapOf(source to node(), target to node(), other to node())).use { realm ->
            val author = realm.asUser("author")
            realm.commit(connect(NESTED_SECOND, at(other, "nestedSecond"), target, newWrapper(at(target, "children")))).shouldBeCommitted()
            val before = realm.resources

            author
                .commit {
                    connect(connection(NESTED_SECOND, at(source, "nestedSecond"), target, newWrapper(at(target, "children"))))
                }.shouldBeInstanceOf<CommitPreparedEditResponse.ConflictErrorWrapper>()
            realm.resources shouldBe before
        }
    }

    test("a connect that embeds a new inverse without the guards it requires is refused") {
        RealmFixture.of(wrapperCatalog, mapOf(source to node(), target to node())).use { realm ->
            val unguarded =
                realm
                    .prepare(listOf(connect(NESTED_SECOND, at(source, "nestedSecond"), target, newWrapper(at(target, "children")))))
                    .copy(expectations = emptyList())

            val problems = realm.commit(unguarded).shouldBeInstanceOf<CommitPreparedEditResponse.RejectedErrorWrapper>().value

            problems.map { it.code }.toSet() shouldBe setOf("missing_expectation")
            realm.resources.getValue(target).itemIds("children") shouldBe emptyList()
        }
    }

    test("a connect through an endpoint no relation declares is refused at its source") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(), target to node())).use { realm ->
            realm.expectRefused(connect(EndpointId(value = "absent"), at(source, "first"), target)).map { it.location to it.code } shouldBe
                listOf(at(source, "first") to "unknown_endpoint")
        }
    }

    test("a connect whose inverse field the target declares twice is refused until the author picks one") {
        val catalog = nodeCatalog(pairRelation()) { field("secondAlternative", linkType(PAIR_SECOND).template()) }
        val seed = mapOf(source to node(), target to node().with("secondAlternative", DataValue.UNFILLED))
        RealmFixture.of(catalog, seed).use { realm ->
            realm.expectRefused(connect(PAIR_FIRST, at(source, "first"), target)).map { it.location to it.code } shouldBe
                listOf(at(source, "first") to "counterpart_choice_required")
        }
    }

    test("a connect whose chosen inverse lies on another resource is refused at that inverse") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(), target to node(), other to node())).use { realm ->
            val elsewhere = occurrence(PAIR_SECOND, at(other, "second"), source)

            realm
                .expectRefused(connect(PAIR_FIRST, at(source, "first"), target, CounterpartChoice.ExistingWrapper(elsewhere)))
                .map { it.location to it.code } shouldBe listOf(at(other, "second") to "counterpart_resource_mismatch")
        }
    }

    test("a connect whose chosen inverse uses the wrong endpoint is refused at that inverse") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(), target to node())).use { realm ->
            val wrongSide = occurrence(PAIR_FIRST, at(target, "first"), source)

            realm
                .expectRefused(connect(PAIR_FIRST, at(source, "first"), target, CounterpartChoice.ExistingWrapper(wrongSide)))
                .map { it.location to it.code } shouldBe listOf(at(target, "first") to "counterpart_endpoint_mismatch")
        }
    }

    test("a self link whose inverse is the same occurrence is refused") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node())).use { realm ->
            val same = occurrence(PAIR_SECOND, at(source, "first"), source)

            realm
                .expectRefused(connect(PAIR_FIRST, at(source, "first"), source, CounterpartChoice.ExistingWrapper(same)))
                .map { it.location to it.code } shouldBe listOf(at(source, "first") to "self_link_requires_distinct_occurrences")
        }
    }

    test("a new inverse prepared as a plain value instead of a record is refused at its collection") {
        RealmFixture.of(wrapperCatalog, mapOf(source to node(), target to node())).use { realm ->
            val plain =
                CounterpartChoice.createNew(
                    containing = at(target, "children"),
                    prepared =
                        PreparedValue(
                            content = PreparedContent.ValueWrapper(DataValue.StringValueWrapper("inverse")),
                            findings = emptyList(),
                        ),
                )

            realm
                .expectRefused(connect(NESTED_SECOND, at(source, "nestedSecond"), target, plain))
                .map { it.location to it.code } shouldBe listOf(at(target, "children") to "counterpart_requires_record")
        }
    }

    test("a new inverse whose type is still pending is refused at its collection") {
        val generic = TypeDefinitionId.qualified("test", "generic_wrapper")
        val genericWrapper =
            definitions {
                record(
                    generic,
                    parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = generic, index = 0), name = "T")),
                )
            }
        val catalog =
            DefinitionCatalog(nodeDefinitions(childItem = WRAPPER) + genericWrapper, listOf(nestedRelation(EndpointCardinality.MANY)))
        RealmFixture.of(catalog, mapOf(source to node(), target to node())).use { realm ->
            val pending =
                CounterpartChoice.createNew(
                    containing = at(target, "children"),
                    prepared =
                        PreparedValue(
                            content =
                                PreparedContent.RecordWrapper(
                                    AuthoringRecord.of(
                                        TypeSelection.of(generic),
                                        emptyMap(),
                                    ),
                                ),
                            findings = emptyList(),
                        ),
                )

            realm
                .expectRefused(connect(NESTED_SECOND, at(source, "nestedSecond"), target, pending))
                .map { it.location to it.code } shouldBe listOf(at(target, "children") to "counterpart_type_pending")
        }
    }

    test("a new inverse without exactly one place for the inverse link is refused at its collection") {
        RealmFixture.of(nodeCatalog(pairRelation(), childItem = WRAPPER), mapOf(source to node(), target to node())).use { realm ->
            realm
                .expectRefused(connect(PAIR_FIRST, at(source, "first"), target, newWrapper(at(target, "children"))))
                .map { it.location to it.code } shouldBe listOf(at(target, "children") to "new_counterpart_location_ambiguous")
        }
    }

    test("a connect whose source occurrence lies on another resource is refused") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(), target to node(), other to node())).use { realm ->
            val misplaced =
                LinkOccurrence(
                    id = LinkOccurrenceId(endpoint = PAIR_FIRST, location = at(other, "first")),
                    source = source,
                    target = LinkTarget(resource = target, opposite = null),
                )

            realm
                .expectRefused(EditIntent.ConnectRelationWrapper(ConnectIntent(source = misplaced, target = target, counterpart = null)))
                .map { it.location to it.code } shouldBe listOf(at(other, "first") to "source_location_resource_mismatch")
        }
    }

    test("disconnecting an occurrence that holds no link is refused") {
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(source to node(), target to node())).use { realm ->
            realm
                .expectRefused(
                    EditIntent.DisconnectRelationWrapper(LinkOccurrenceId(endpoint = PAIR_FIRST, location = at(source, "first"))),
                ).map { it.location to it.code } shouldBe listOf(at(source, "first") to "link_occurrence_missing")
        }
    }
}
