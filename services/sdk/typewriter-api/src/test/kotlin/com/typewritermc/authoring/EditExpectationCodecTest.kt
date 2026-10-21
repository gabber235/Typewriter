package com.typewritermc.authoring

import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val EditExpectationCodecTest by testSuite {
    test("all six focused facts round trip through the shared editor contract") {
        val resource = ResourceId("quest")
        val at = ValueLocation.of(resource, ValuePath.root.field("chapter"))
        val selection = TypeSelection.CompleteWrapper(TypeDefinitionId.qualified("test", "chapter").namedUse())
        val record = AuthoringRecord.of(selection, mapOf("title" to DataValue.StringValueWrapper("Quest")))
        val projection = LinkProjection(RelationId("chapters"), resource, ResourceId("chapter"), at.path, null)
        val expectations =
            listOf(
                EditExpectation.Value(at, null),
                EditExpectation.Value(at, DataValue.NULL),
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
