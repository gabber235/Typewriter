package com.typewritermc.authoring

import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.TypeDefinitionId

val EditExpectationCodecTest by testSuite {
    test("all six focused facts round trip through the shared editor contract") {
        val resource = ResourceId("quest")
        val at = ValueLocation(resource, ValuePath(listOf(PathSegment.Field("chapter"))))
        val selection = TypeSelection.Complete(TypeDefinitionId.qualified("test", "chapter").namedUse())
        val record = AuthoringRecord(selection, mapOf("title" to DataValue.StringValue("Quest")))
        val projection = LinkProjection(RelationId("chapters"), resource, ResourceId("chapter"), at.path, null)
        val expectations =
            listOf(
                EditExpectation.Value(at, null),
                EditExpectation.Value(at, DataValue.Null),
                EditExpectation.Resource(resource, record),
                EditExpectation.ResourceExists(resource, true),
                EditExpectation.Configuration(at, selection),
                EditExpectation.ResourceIds(setOf(resource, ResourceId("chapter"))),
                EditExpectation.Links(resource, projection.contract, TraversalDirection.Both, setOf(projection)),
            )
        val prepared = PreparedEdit(CatalogGeneration("catalog"), expectations, emptyList())
        SkirAuthoringOperationCodec.decode(SkirAuthoringOperationCodec.encode(prepared).getOrThrow()).getOrThrow() shouldBe prepared
    }
}
