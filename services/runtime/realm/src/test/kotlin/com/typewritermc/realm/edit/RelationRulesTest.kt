package com.typewritermc.realm.edit

import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.Refusal
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.refusals
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.text
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.resource_id.ResourceId
import kotlin.time.Duration.Companion.minutes

val RelationRulesTest by testSuite {
    val first = ResourceId(value = "first")

    val second = ResourceId(value = "second")

    val target = ResourceId(value = "target")

    test("a second owner of an owned resource is refused at the owned resource") {
        val seed = mapOf(first to node(first = link(PAIR_FIRST, target)), target to node())
        RealmFixture.of(nodeCatalog(pairRelation(families = OWNERSHIP_FAMILY)), seed).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createCreateResource(id = second, record = node(first = link(PAIR_FIRST, target))),
                ).refusals shouldContain
                Refusal(target.value, "multiple_immediate_owners")
        }
    }

    test("closing an ownership cycle is refused at every resource on it") {
        val seed = mapOf(first to node(first = link(PAIR_FIRST, second)), second to node())
        RealmFixture.of(nodeCatalog(pairRelation(families = OWNERSHIP_FAMILY + ACYCLIC_FAMILY)), seed).use { realm ->
            realm
                .expectRefused(EditIntent.createSetValue(at = at(second, "first"), value = link(PAIR_FIRST, first)))
                .filter { it.code == "relation_cycle" }
                .map { it.location.resource }
                .toSet() shouldBe setOf(first, second)
        }
    }

    // A hundred thousand resources load, plan and commit for real, which outlasts the default minute on a busy machine.
    test(
        "a long chain through an acyclic relation stays editable and closing it into a cycle is refused",
        testConfig = TestConfig.testScope(isEnabled = true, timeout = 5.minutes),
    ) {
        val chain = (0 until 100_000).map { ResourceId(value = "chain_$it") }
        val seed =
            chain.withIndex().associate { (index, id) ->
                id to node(first = chain.getOrNull(index + 1)?.let { link(PAIR_FIRST, it) } ?: DataValue.UNFILLED)
            }
        RealmFixture.of(nodeCatalog(pairRelation(families = ACYCLIC_FAMILY)), seed).use { realm ->
            realm
                .commit(
                    EditIntent.createSetValue(at = at(chain.first(), "label"), value = DataValue.StringValueWrapper("head")),
                ).shouldBeCommitted()
            realm.resources.getValue(chain.first()).text("label") shouldBe "head"

            realm
                .expectRefused(EditIntent.createSetValue(at = at(chain.last(), "first"), value = link(PAIR_FIRST, chain.first())))
                .map { it.code }
                .toSet() shouldBe setOf("relation_cycle")
        }
    }

    test("a relation outside the acyclic family may form a cycle") {
        val seed = mapOf(first to node(first = link(PAIR_FIRST, second)), second to node())
        RealmFixture.of(nodeCatalog(pairRelation()), seed).use { realm ->
            realm.commit(EditIntent.createSetValue(at = at(second, "first"), value = link(PAIR_FIRST, first))).shouldBeCommitted()

            realm.resources.getValue(second).link("first") shouldBe first
        }
    }

    test("a second link to a target whose side holds one link is refused at the target") {
        val seed = mapOf(first to node(first = link(PAIR_FIRST, target)), target to node())
        RealmFixture.of(nodeCatalog(pairRelation()), seed).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createCreateResource(id = second, record = node(first = link(PAIR_FIRST, target))),
                ).refusals shouldContain
                Refusal(target.value, "first_endpoint_cardinality_exceeded")
        }
    }

    test("a second link to a source whose side holds one link is refused at the source") {
        val seed = mapOf(first to node(), second to node(second = link(PAIR_SECOND, first)))
        RealmFixture.of(nodeCatalog(pairRelation()), seed).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createCreateResource(id = target, record = node(second = link(PAIR_SECOND, first))),
                ).refusals shouldContain
                Refusal(first.value, "second_endpoint_cardinality_exceeded")
        }
    }

    test("an invalid resource the edit does not touch does not block it") {
        val invalid = node().let { it.copy(fields = it.fields.filterNot { field -> field.name == "label" }) }
        RealmFixture.of(nodeCatalog(pairRelation()), mapOf(first to invalid, second to node())).use { realm ->
            realm
                .commit(
                    EditIntent.createSetValue(at = at(second, "label"), value = DataValue.StringValueWrapper("changed")),
                ).shouldBeCommitted()

            realm.resources.getValue(second).text("label") shouldBe "changed"
        }
    }
}
