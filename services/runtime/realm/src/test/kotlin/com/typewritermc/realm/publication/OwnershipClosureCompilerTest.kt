package com.typewritermc.realm.publication

import com.typewritermc.authoring.of
import com.typewritermc.engine.ResourceGraphCompileResult
import com.typewritermc.engine.relation
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val OwnershipClosureCompilerTest by testSuite {
    val pageId = ResourceId(value = "page")

    val childId = ResourceId(value = "child")

    val missingId = ResourceId(value = "missing")

    test("one sided ownership links compile the complete owned shard") {
        val result =
            compileOwnershipClosure(mapOf(pageId to ownershipPageRecord(listOf(childId)), childId to ownershipChildRecord("first")), pageId)

        result as ResourceGraphCompileResult.Success
        result.shard.facts.resources
            .map { it.key.source }
            .toSet() shouldBe setOf(pageId, childId)
        result.shard.facts.edges.single().let { edge ->
            edge.source.source shouldBe pageId
            edge.target.source shouldBe childId
            edge.relation shouldBe OWNERSHIP_RELATION
        }
    }

    test("authored content changes produce a new shard identity") {
        val first =
            compileOwnershipClosure(mapOf(pageId to ownershipPageRecord(listOf(childId)), childId to ownershipChildRecord("first")), pageId)
        val second =
            compileOwnershipClosure(
                mapOf(pageId to ownershipPageRecord(listOf(childId)), childId to ownershipChildRecord("second")),
                pageId,
            )

        first as ResourceGraphCompileResult.Success
        second as ResourceGraphCompileResult.Success
        (second.inputFingerprint == first.inputFingerprint) shouldBe false
        (second.shard.digest == first.shard.digest) shouldBe false
    }

    test("a nested compilation unit is its own shard, not part of its owner's") {
        val nested = ResourceId(value = "nested")
        val records =
            mapOf(
                pageId to ownershipPageRecord(listOf(childId, nested)),
                childId to ownershipChildRecord("first"),
                nested to ownershipNestedRecord(),
            )
        val page = compileOwnershipClosure(records, pageId) as ResourceGraphCompileResult.Success
        val unit = compileOwnershipClosure(records, nested) as ResourceGraphCompileResult.Success

        page.shard.facts.resources
            .map { it.key.source }
            .toSet() shouldBe setOf(pageId, childId)
        page.shard.facts.edges
            .map { it.target.source }
            .toSet() shouldBe setOf(childId, nested)
        unit.shard.facts.resources
            .map { it.key.source } shouldBe listOf(nested)
    }

    test("missing owned resources block publication") {
        val result = compileOwnershipClosure(mapOf(pageId to ownershipPageRecord(listOf(missingId))), pageId)

        result as ResourceGraphCompileResult.Blocked
        result.diagnostics.single().code shouldBe "missing_owned_resource"
    }

    test("parallel occurrences retain distinct endpoint locations") {
        val result =
            compileOwnershipClosure(
                mapOf(pageId to ownershipPageRecord(listOf(childId, childId)), childId to ownershipChildRecord("child")),
                pageId,
            )
                as ResourceGraphCompileResult.Success

        result.shard.facts.edges
            .map { (it.origin as CompiledEdgeOrigin.RelationWrapper).value.firstLocation }
            .toSet() shouldBe setOf(ownershipChildPath(0), ownershipChildPath(1))
    }

    test("a resource whose type the catalog no longer declares blocks its shard with unresolved_type") {
        val unavailable =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(TypeDefinitionId.qualified("removed", "page").namedUse()),
                mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
            )
        val result = compileOwnershipClosure(mapOf(pageId to unavailable), pageId) as ResourceGraphCompileResult.Blocked

        result.diagnostics.map { it.code to it.primary } shouldBe listOf("unresolved_type" to ValueLocation.of(pageId))
    }

    test("an invalid ownership edge does not block an independent page") {
        val other = ResourceId(value = "other")
        val records = mapOf(pageId to ownershipPageRecord(listOf(missingId)), other to ownershipPageRecord(emptyList()))

        compileOwnershipClosure(records, pageId).shouldBeInstanceOf<ResourceGraphCompileResult.Blocked>()
        val independent = compileOwnershipClosure(records, other) as ResourceGraphCompileResult.Success
        independent.shard.facts.resources
            .map { it.key.source } shouldBe listOf(other)
    }

    test("a complete sibling cannot hide an unfinished owned resource") {
        val sibling = ResourceId(value = "sibling")
        val unfinished = AuthoringRecord.of(ownershipChildRecord("draft").configuration, mapOf("value" to DataValue.UNFILLED))
        val original = mapOf(pageId to ownershipPageRecord(listOf(childId)), childId to unfinished)
        val findings =
            listOf(original, original + (sibling to ownershipChildRecord("complete"))).map { records ->
                (compileOwnershipClosure(records, pageId) as ResourceGraphCompileResult.Blocked).diagnostics
            }

        findings[0] shouldBe findings[1]
        findings[0].map { it.code to it.primary?.resource } shouldBe listOf("unfinished_value" to childId)
    }
}
