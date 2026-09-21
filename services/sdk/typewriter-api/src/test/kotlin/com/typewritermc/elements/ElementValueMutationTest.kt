package com.typewritermc.elements

import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe

val ElementValueMutationTest by testSuite {
    test("set value preserves an abstract target expression") {
        val messageType = ResolvedTypeRef(TypeId.Qualified("test", "Message"), 1)
        val literalType = ResolvedTypeRef(TypeId.Qualified("test", "LiteralMessage"), 1)
        val graph =
            TypeGraph(
                TypeExpression.Record(
                    listOf(TypeField("message", TypeExpression.Named(messageType))),
                ),
                listOf(
                    TypeDefinition(messageType, NominalTypeKind.SEALED_ABSTRACT),
                    TypeDefinition(
                        id = literalType,
                        kind = NominalTypeKind.CONCRETE,
                        representation =
                            TypeExpression.Record(
                                listOf(TypeField("value", TypeExpression.StringType())),
                            ),
                        parents = listOf(messageType),
                    ),
                ),
            )
        val initialMessage = literalMessage(literalType, "")
        val stored =
            decomposer().decompose(
                graph,
                DataValue.Record(mapOf("message" to initialMessage)),
            )
        val replacement = literalMessage(literalType, "Edited")

        val result =
            mutator()
                .apply(
                    graph,
                    stored,
                    listOf(
                        ElementValueMutation.SetValue(
                            ElementValuePath(listOf(ElementValuePathSegment.Field("message"))),
                            replacement,
                        ),
                    ),
                ).success()

        ReferenceAssembler().assemble(graph, result) shouldBe
            ReferenceAssemblyResult.Success(
                DataValue.Record(mapOf("message" to replacement)),
            )
    }

    test("list reorder preserves reference slots") {
        val graph = TypeGraph(TypeExpression.ListType(refTo(elementType)), emptyList())
        val stored = decomposer().decompose(graph, references("element:first", "element:second"))
        val originalSlots = stored.references.associate { it.target.value to it.slot }

        val result =
            mutator()
                .apply(
                    graph,
                    stored,
                    listOf(ElementValueMutation.ReorderListItems(ElementValuePath(), 0, 1, 1)),
                ).success()

        ReferenceAssembler().assemble(graph, result) shouldBe
            ReferenceAssemblyResult.Success(references("element:second", "element:first"))
        result.references.associate { it.target.value to it.slot } shouldBe originalSlots
    }

    test("list duplication allocates fresh slots") {
        val graph = TypeGraph(TypeExpression.ListType(refTo(elementType)), emptyList())
        val decomposer = decomposer()
        val stored = decomposer.decompose(graph, references("element:first"))

        val result =
            ElementValueMutator(decomposer)
                .apply(
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
                    "left" to DataValue.Reference(ResourceId("element:left")),
                    "right" to DataValue.Reference(ResourceId("element:right")),
                ),
            )
        val stored = decomposer().decompose(graph, logical)
        val rightSlot = stored.references.single { it.target.value == "element:right" }.slot

        val result =
            mutator()
                .apply(
                    graph,
                    stored,
                    listOf(
                        ElementValueMutation.SetValue(
                            ElementValuePath(listOf(ElementValuePathSegment.Field("left"))),
                            DataValue.Reference(ResourceId("element:new")),
                        ),
                    ),
                ).success()

        result.references.single { it.target.value == "element:right" }.slot shouldBe rightSlot
        ReferenceAssembler().assemble(graph, result) shouldBe
            ReferenceAssemblyResult.Success(
                logical.copy(fields = logical.fields + ("left" to DataValue.Reference(ResourceId("element:new")))),
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
                            DataValue.Reference(ResourceId("element:key")),
                            DataValue.Reference(ResourceId("element:value")),
                        ),
                    ),
                ),
            )

        val result =
            mutator()
                .apply(
                    graph,
                    stored,
                    listOf(
                        ElementValueMutation.PutMapEntries(
                            ElementValuePath(),
                            listOf(
                                DataMapEntry(
                                    DataValue.Reference(ResourceId("element:key")),
                                    DataValue.Reference(ResourceId("element:replacement")),
                                ),
                            ),
                        ),
                    ),
                ).success()

        result.references.map { it.target.value }.toSet() shouldBe
            setOf("element:key", "element:replacement")
    }
}

private fun ElementValueMutationResult.success(): StoredElementValue = (this as ElementValueMutationResult.Success).value

private fun references(vararg targets: String): DataValue.ListValue =
    DataValue.ListValue(targets.map { DataValue.Reference(ResourceId(it)) })

private fun literalMessage(
    type: ResolvedTypeRef,
    value: String,
): DataValue.Polymorphic =
    DataValue.Polymorphic(
        concreteType = type,
        value = DataValue.Record(mapOf("value" to DataValue.StringValue(value))),
    )

private fun mutator(): ElementValueMutator = ElementValueMutator(decomposer())

private fun decomposer(): ReferenceDecomposer {
    var next = 0
    return ReferenceDecomposer { ReferenceSlotId("mutation_slot_${next++}") }
}

private fun refTo(target: ResolvedTypeRef): TypeExpression.Reference = TypeExpression.Reference(target)

private val elementType = ResolvedTypeRef(TypeId.Qualified("test", "MutationEntry"), 1)
