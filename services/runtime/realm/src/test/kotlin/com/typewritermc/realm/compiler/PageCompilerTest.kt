package com.typewritermc.realm.compiler

import com.typewritermc.authoring.GRAPH_PLACEMENT_TYPE_ID
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.ResourceRelationOrigin
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

private val pageId = ResourceId("page")
private val childId = ResourceId("child")
private val cueId = ResourceId("cue")
private val ownership = RelationId("349b4d11c4464d13ad4ca063ead60c62")
private val cueOwnership = RelationId("37bcfc796a124301a3c8ac3fcfce2cee")
private val pageType = ResolvedTypeRef(TypeId.Qualified("test", "Page"), 1)
private val childType = ResolvedTypeRef(TypeId.Qualified("test", "Child"), 1)
private val cueType = ResolvedTypeRef(TypeId.Qualified("test", "Cue"), 1)

val PageCompilerTest by testSuite {
    test("graph layout changes retain the execution fingerprint") {
        val compiler = PageCompiler(setOf(ownership))
        val first = compiler.compile(pageId, graph(graphPlacement(1)), "catalog:1")
        val second = compiler.compile(pageId, graph(graphPlacement(2)), "catalog:1")

        first as PageCompileResult.Success
        second as PageCompileResult.Success
        second.shard.inputFingerprint shouldBe first.shard.inputFingerprint
        second.shard.digest shouldBe first.shard.digest
    }

    test("authored content changes produce a new shard identity") {
        val compiler = PageCompiler(setOf(ownership))
        val first = compiler.compile(pageId, graph(DataValue.Integer(java.math.BigInteger.ONE)), "catalog:1")
        val second = compiler.compile(pageId, graph(DataValue.Integer(java.math.BigInteger.TWO)), "catalog:1")

        first as PageCompileResult.Success
        second as PageCompileResult.Success
        (second.shard.inputFingerprint == first.shard.inputFingerprint) shouldBe false
        (second.shard.digest == first.shard.digest) shouldBe false
    }

    test("a missing owned resource blocks publication") {
        val graph = graph(DataValue.Unit).copy(resources = mapOf(pageId to pageResource()))
        val result = PageCompiler(setOf(ownership)).compile(pageId, graph, "catalog:1")
        (result is PageCompileResult.Blocked) shouldBe true
    }

    test("nested owned cues retain their resource and ordered edge") {
        val original = graph(DataValue.Unit)
        val nested = original.copy(
            resources = original.resources + (cueId to StoredTypedResource(
                cueId,
                ResourceDefinitionId("test.cue"),
                cueType,
                DataValue.Record(emptyMap()),
            )),
            relations = original.relations + ("cue-edge" to StoredResourceRelation(
                "cue-edge", childId, cueId,
                ResourceRelationOrigin.Declared(cueOwnership, sourceIndex = 2),
            )),
        )

        val result = PageCompiler(setOf(ownership, cueOwnership)).compile(pageId, nested, "catalog:1")
        result as PageCompileResult.Success
        result.shard.resources.map { it.key.source }.toSet() shouldBe setOf(pageId, childId, cueId)
        result.shard.edges.single { it.target.source == cueId }.origin shouldBe
            com.typewritermc.engine.CompiledEdgeOrigin.Declared(cueOwnership, sourceIndex = 2)
    }
}

private fun graph(value: DataValue): AuthoringWorkingGraph = AuthoringWorkingGraph(
    resources = mapOf(pageId to pageResource(), childId to StoredTypedResource(
        childId,
        ResourceDefinitionId("test.child"),
        childType,
        DataValue.Record(mapOf("value" to value)),
    )),
    relations = mapOf("edge" to StoredResourceRelation(
        "edge", pageId, childId, ResourceRelationOrigin.Declared(ownership, sourceIndex = 0),
    )),
)

private fun pageResource() = StoredTypedResource(
    pageId, ResourceDefinitionId("test.page"), pageType, DataValue.Record(emptyMap()),
)

private fun graphPlacement(value: Int) = DataValue.Polymorphic(
    ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse(GRAPH_PLACEMENT_TYPE_ID)), 1),
    DataValue.Record(mapOf("x" to DataValue.Integer(java.math.BigInteger.valueOf(value.toLong())))),
)
