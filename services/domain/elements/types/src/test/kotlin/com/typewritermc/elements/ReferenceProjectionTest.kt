package com.typewritermc.elements

import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ReferenceProjectionTest by testSuite {
    test("direct references decompose and assemble without duplicate target ownership") {
        val value = DataValue.StringValue("element:target")
        val stored = decomposer().decompose(TypeGraph(refTo(elementType), emptyList()), value)

        stored.references.single().target.referenceString() shouldBe "element:target"
        ReferenceAssembler().assemble(TypeGraph(refTo(elementType), emptyList()), stored) shouldBe
            ReferenceAssemblyResult.Success(value)
    }

    test("reordering records preserves optional reference slot targets") {
        val optionalReference = TypeExpression.Named(StandardTypes.optionOf(refTo(elementType)))
        val itemType = TypeExpression.Record(listOf(TypeField("next", optionalReference)))
        val graph = TypeGraph(TypeExpression.ListType(itemType), emptyList())
        val first = optionalReference("element:first")
        val second = optionalReference("element:second")
        val logical = DataValue.ListValue(listOf(first, second))
        val stored = decomposer().decompose(graph, logical)
        val storedList = stored.valueWithSlots as DataValue.ListValue
        val reordered = stored.copy(valueWithSlots = DataValue.ListValue(storedList.values.reversed()))

        ReferenceAssembler().assemble(graph, reordered) shouldBe
            ReferenceAssemblyResult.Success(DataValue.ListValue(listOf(second, first)))
    }

    test("references inside a selected polymorphic branch assemble") {
        val pageChoice = ResolvedTypeRef(TypeId.Qualified("test", "PageChoice"), 1)
        val pageBranch = ResolvedTypeRef(TypeId.Qualified("test", "PageBranch"), 1)
        val graph =
            TypeGraph(
                root = TypeExpression.Named(pageChoice),
                definitions =
                    listOf(
                        TypeDefinition(pageChoice, NominalTypeKind.SEALED_ABSTRACT),
                        TypeDefinition(
                            id = pageBranch,
                            kind = NominalTypeKind.CONCRETE,
                            parents = listOf(pageChoice),
                            representation = TypeExpression.Record(listOf(TypeField("page", refTo(pageType)))),
                        ),
                    ),
            )
        val logical =
            DataValue.Polymorphic(
                pageBranch,
                DataValue.Record(mapOf("page" to DataValue.StringValue("page:intro"))),
            )
        val stored = decomposer().decompose(graph, logical)

        ReferenceAssembler().assemble(graph, stored) shouldBe ReferenceAssemblyResult.Success(logical)
    }
}

private fun decomposer(): ReferenceDecomposer {
    var next = 0
    return ReferenceDecomposer { ReferenceSlotId("slot_${next++}") }
}

private fun refTo(target: ResolvedTypeRef): TypeExpression.Named =
    TypeExpression.Named(
        ResolvedTypeRef(
            id = TypeId.Qualified("typewriter/v1", "Ref"),
            revision = 1,
            arguments = listOf(TypeExpression.Named(target)),
        ),
    )

private fun optionalReference(target: String): DataValue =
    DataValue.Record(
        mapOf(
            "next" to
                DataValue.Polymorphic(
                    StandardTypes.someOf(refTo(elementType)),
                    DataValue.Record(mapOf("value" to DataValue.StringValue(target))),
                ),
        ),
    )

private val elementType = ResolvedTypeRef(TypeId.Qualified("test", "Entry"), 1)
private val pageType = ResolvedTypeRef(TypeId.Qualified("test", "Page"), 1)
