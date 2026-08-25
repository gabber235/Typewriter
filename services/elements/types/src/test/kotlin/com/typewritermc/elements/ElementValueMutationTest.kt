package com.typewritermc.elements

import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import com.typewritermc.types.ResolvedTypeRef
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe

val ElementValueMutationTest by testSuite {
    test("list reorder preserves reference slots") {
        val graph = TypeGraph(TypeExpression.ListType(refTo(elementType)), emptyList())
        val stored = decomposer().decompose(graph, references("element:first", "element:second"))
        val originalSlots = stored.references.associate { it.target.referenceString() to it.slot }

        val result =
            mutator().apply(
                graph,
                stored,
                listOf(ElementValueMutation.ReorderListItems(ElementValuePath(), 0, 1, 1)),
            ).success()

        ReferenceAssembler().assemble(graph, result) shouldBe
            ReferenceAssemblyResult.Success(references("element:second", "element:first"))
        result.references.associate { it.target.referenceString() to it.slot } shouldBe originalSlots
    }

    test("list duplication allocates fresh slots") {
        val graph = TypeGraph(TypeExpression.ListType(refTo(elementType)), emptyList())
        val decomposer = decomposer()
        val stored = decomposer.decompose(graph, references("element:first"))

        val result =
            ElementValueMutator(decomposer).apply(
                graph,
                stored,
                listOf(ElementValueMutation.DuplicateListItems(ElementValuePath(), 0, 1, 1)),
            ).success()

        ReferenceAssembler().assemble(graph, result) shouldBe
            ReferenceAssemblyResult.Success(references("element:first", "element:first"))
        result.references shouldHaveSize 2
        result.references.map(StoredReference::slot).distinct() shouldHaveSize 2
    }

    test("nested replacement changes only replaced subtree references") {
        val graph =
            TypeGraph(
                TypeExpression.Record(
                    listOf(
                        TypeField("left", refTo(elementType)),
                        TypeField("right", refTo(elementType)),
                    ),
                ),
                emptyList(),
            )
        val logical =
            DataValue.Record(
                mapOf(
                    "left" to DataValue.StringValue("element:left"),
                    "right" to DataValue.StringValue("element:right"),
                ),
            )
        val stored = decomposer().decompose(graph, logical)
        val rightSlot = stored.references.single { it.target.referenceString() == "element:right" }.slot

        val result =
            mutator().apply(
                graph,
                stored,
                listOf(
                    ElementValueMutation.SetValue(
                        ElementValuePath(listOf(ElementValuePathSegment.Field("left"))),
                        DataValue.StringValue("element:new"),
                    ),
                ),
            ).success()

        result.references.single { it.target.referenceString() == "element:right" }.slot shouldBe rightSlot
        ReferenceAssembler().assemble(graph, result) shouldBe
            ReferenceAssemblyResult.Success(
                logical.copy(fields = logical.fields + ("left" to DataValue.StringValue("element:new"))),
            )
    }

    test("map replacement removes old key and value slots") {
        val graph = TypeGraph(TypeExpression.MapType(refTo(elementType), refTo(elementType)), emptyList())
        val stored =
            decomposer().decompose(
                graph,
                DataValue.MapValue(
                    listOf(
                        DataMapEntry(
                            DataValue.StringValue("element:key"),
                            DataValue.StringValue("element:value"),
                        ),
                    ),
                ),
            )

        val result =
            mutator().apply(
                graph,
                stored,
                listOf(
                    ElementValueMutation.PutMapEntries(
                        ElementValuePath(),
                        listOf(
                            DataMapEntry(
                                DataValue.StringValue("element:key"),
                                DataValue.StringValue("element:replacement"),
                            ),
                        ),
                    ),
                ),
            ).success()

        result.references.map { it.target.referenceString() }.toSet() shouldBe
            setOf("element:key", "element:replacement")
    }
}

private fun ElementValueMutationResult.success(): StoredElementValue =
    (this as ElementValueMutationResult.Success).value

private fun references(vararg targets: String): DataValue.ListValue =
    DataValue.ListValue(targets.map(DataValue::StringValue))

private fun mutator(): ElementValueMutator = ElementValueMutator(decomposer())

private fun decomposer(): ReferenceDecomposer {
    var next = 0
    return ReferenceDecomposer { ReferenceSlotId("mutation_slot_${next++}") }
}

private fun refTo(target: ResolvedTypeRef): TypeExpression.Named =
    TypeExpression.Named(
        ResolvedTypeRef(
            id = TypeId.Qualified("typewriter/v1", "Ref"),
            revision = 1,
            arguments = listOf(TypeExpression.Named(target)),
        ),
    )

private val elementType = ResolvedTypeRef(TypeId.Qualified("test", "MutationEntry"), 1)
