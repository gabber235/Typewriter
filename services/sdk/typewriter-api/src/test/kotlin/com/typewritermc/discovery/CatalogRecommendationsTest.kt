package com.typewritermc.discovery

import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val CatalogRecommendationsTest by testSuite {
    test("counts direct and nested complete custom uses") {
        val weighted = id("Weighted")
        val source = id("Source")
        val weightedText = TypeTemplate.Named(weighted, listOf(TypeTemplate.Scalar(ScalarKind.Text)))
        val definitions =
            listOf(
                TypeDefinition(weighted, representation = RepresentationTemplate.Record(emptyList())),
                record(
                    source,
                    field(source, "primary", weightedText),
                    field(source, "choices", TypeTemplate.Named(StandardTypes.list, listOf(weightedText))),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions).map { it.type to it.occurrences } shouldBe
            listOf(weightedText.toUse() to 2L)
    }

    test("skips overrides and unavailable targets") {
        val available = id("Available")
        val unavailable = id("Unavailable")
        val parent = id("Parent")
        val child = id("Child")
        val definitions =
            listOf(
                TypeDefinition(available, representation = RepresentationTemplate.Record(emptyList())),
                TypeDefinition(unavailable, representation = RepresentationTemplate.Record(emptyList())),
                record(parent, field(parent, "value", TypeTemplate.Named(available))),
                record(
                    child,
                    FieldDeclaration(
                        owner = FieldOwner(child, "value"),
                        type = TypeTemplate.Named(available),
                        overrides = listOf(FieldOwner(parent, "value")),
                    ),
                    field(child, "invalid", TypeTemplate.Named(unavailable)),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, setOf(unavailable)).map { it.type.definition to it.occurrences } shouldBe
            listOf(available to 1L)
    }

    test("orders equal counts by canonical type") {
        val alpha = id("Alpha")
        val beta = id("Beta")
        val source = id("Source")
        val definitions =
            listOf(
                TypeDefinition(alpha, representation = RepresentationTemplate.Record(emptyList())),
                TypeDefinition(beta, representation = RepresentationTemplate.Record(emptyList())),
                record(
                    source,
                    field(source, "beta", TypeTemplate.Named(beta)),
                    field(source, "alpha", TypeTemplate.Named(alpha)),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions).map { it.type.definition } shouldBe listOf(alpha, beta)
    }
}

private fun id(name: String) = TypeDefinitionId(TypeId.Qualified("recommendation", name), 1)

private fun field(
    owner: TypeDefinitionId,
    name: String,
    type: TypeTemplate,
) = FieldDeclaration(FieldOwner(owner, name), type)

private fun record(
    id: TypeDefinitionId,
    vararg fields: FieldDeclaration,
) = TypeDefinition(id, representation = RepresentationTemplate.Record(fields.toList()))

private fun TypeTemplate.Named.toUse() =
    com.typewritermc.types.TypeUse.Named(
        definition,
        arguments.map {
            when (it) {
                is TypeTemplate.Scalar -> {
                    com.typewritermc.types.TypeUse
                        .Scalar(it.kind)
                }

                else -> {
                    error("Test template is not complete.")
                }
            }
        },
    )
