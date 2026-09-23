package com.typewritermc.elements.codegen

import com.typewritermc.elements.ContentSearchMode
import com.typewritermc.elements.ContentSearchPolicy
import com.typewritermc.elements.ContentSearchPropertyOverride
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val ElementSearchDefinitionGeneratorTest by testSuite {
    test("revision inputs include nested collection and polymorphic definitions") {
        val root = reference("Entry", 4)
        val message = reference("Message", 2)
        val literal = reference("LiteralMessage", 7)
        val graph =
            TypeGraph(
                root = TypeExpression.Named(root),
                definitions =
                    listOf(
                        TypeDefinition(
                            root,
                            NominalTypeKind.CONCRETE,
                            TypeExpression.Record(
                                listOf(
                                    TypeField(
                                        "messages",
                                        TypeExpression.ListType(TypeExpression.Named(message)),
                                    ),
                                ),
                            ),
                        ),
                        TypeDefinition(message, NominalTypeKind.SEALED_ABSTRACT),
                        TypeDefinition(
                            literal,
                            NominalTypeKind.CONCRETE,
                            TypeExpression.Record(listOf(TypeField("text", TypeExpression.StringType()))),
                            parents = listOf(message),
                        ),
                    ),
            )

        val result = ElementSearchDefinitionGenerator.generate(graph, emptyList()) as ElementSearchGenerationResult.Success

        result.definition.policy shouldBe ContentSearchPolicy.ORDINARY_TEXT
        result.definition.revisionFingerprintInputs shouldBe listOf(root, literal, message).sortedBy { it.toString() }
    }

    test("subtree overrides accept nested logical strings") {
        val root = reference("Entry")
        val logical = reference("LocalizedText")
        val graph =
            TypeGraph(
                TypeExpression.Named(root),
                listOf(
                    TypeDefinition(
                        root,
                        NominalTypeKind.CONCRETE,
                        TypeExpression.Record(
                            listOf(TypeField("lines", TypeExpression.ListType(TypeExpression.Named(logical)))),
                        ),
                    ),
                    TypeDefinition(logical, NominalTypeKind.CONCRETE, TypeExpression.StringType()),
                ),
            )
        val override = ContentSearchPropertyOverride(root, "lines", ContentSearchMode.SUMMARY)

        val result = ElementSearchDefinitionGenerator.generate(graph, listOf(override)) as ElementSearchGenerationResult.Success

        result.definition.propertyOverrides shouldBe listOf(override)
    }

    test("text modes reject subtrees without text") {
        val root = reference("Entry")
        val graph =
            TypeGraph(
                TypeExpression.Named(root),
                listOf(
                    TypeDefinition(
                        root,
                        NominalTypeKind.CONCRETE,
                        TypeExpression.Record(
                            listOf(TypeField("count", TypeExpression.Integer(IntegerWidth.SIGNED_32))),
                        ),
                    ),
                ),
            )
        val override = ContentSearchPropertyOverride(root, "count", ContentSearchMode.BODY)

        ElementSearchDefinitionGenerator.generate(graph, listOf(override)) shouldBe
            ElementSearchGenerationResult.InvalidOverrides(listOf(override))
    }

    test("references remain excluded under explicit text modes") {
        val root = reference("Entry")
        val target = ResolvedTypeRef(TypeId.Qualified("test", "Target"), 1)
        val graph =
            TypeGraph(
                TypeExpression.Named(root),
                listOf(
                    TypeDefinition(
                        root,
                        NominalTypeKind.CONCRETE,
                        TypeExpression.Record(listOf(TypeField("target", TypeExpression.Reference(target)))),
                    ),
                ),
            )
        val override = ContentSearchPropertyOverride(root, "target", ContentSearchMode.KEYWORD)

        ElementSearchDefinitionGenerator.generate(graph, listOf(override)) shouldBe
            ElementSearchGenerationResult.InvalidOverrides(listOf(override))
    }

    test("none accepts an otherwise non searchable subtree") {
        val root = reference("Entry")
        val graph =
            TypeGraph(
                TypeExpression.Named(root),
                listOf(
                    TypeDefinition(
                        root,
                        NominalTypeKind.CONCRETE,
                        TypeExpression.Record(listOf(TypeField("count", TypeExpression.Integer(IntegerWidth.SIGNED_32)))),
                    ),
                ),
            )
        val override = ContentSearchPropertyOverride(root, "count", ContentSearchMode.NONE)

        val result = ElementSearchDefinitionGenerator.generate(graph, listOf(override)) as ElementSearchGenerationResult.Success

        result.definition.propertyOverrides shouldBe listOf(override)
    }
}

private fun reference(
    name: String,
    revision: Int = 1,
) = ResolvedTypeRef(TypeId.Qualified("example", name), revision)
