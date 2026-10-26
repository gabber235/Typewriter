package com.typewritermc.realm.operation

import com.typewritermc.authoring.with
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.resource_id.ResourceId

private val quest = ResourceId(value = "quest")
private val saved = mapOf(quest to record(name = "Quest"))
private val catalog = DefinitionCatalog(TEST_DEFINITIONS)

/** The reason the saved state refuses an operation overlay that upserts [upserts] and removes [removals]. */
private suspend fun refusedOverlay(
    upserts: Map<ResourceId, AuthoringRecord> = emptyMap(),
    removals: Set<ResourceId> = emptySet(),
): String? =
    RealmFixture.of(catalog, saved).use { realm ->
        realm.views.capture().use { lease: AuthoringLease ->
            shouldThrow<IllegalArgumentException> { lease.operationObservation(lease.root.observationId, upserts, removals) }.message
        }
    }

val OperationObservationTest by testSuite {
    test("an overlay that replaces and removes the same resource is refused") {
        refusedOverlay(upserts = saved, removals = setOf(quest)) shouldBe "An overlay cannot replace and remove the same resource"
    }

    test("an overlay that removes a resource the saved state does not hold is refused") {
        refusedOverlay(removals = setOf(ResourceId(value = "missing"))) shouldBe "An overlay removes an unknown resource"
    }

    test("an overlay whose resource has invalid authored structure is refused") {
        refusedOverlay(
            upserts = mapOf(quest to record(name = "Quest").with("unknown", DataValue.StringValueWrapper("stray"))),
        ) shouldStartWith
            "An overlay resource has invalid authored structure"
    }
}
