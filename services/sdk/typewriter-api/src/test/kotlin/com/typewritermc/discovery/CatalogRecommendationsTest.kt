package com.typewritermc.discovery

import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

val CatalogRecommendationsTest by testSuite {
    test("counts direct and nested complete custom uses") {
        val weighted = id("Weighted")
        val source = id("Source")
        val weightedText = weighted.namedTemplate(listOf(ScalarKind.TEXT.template))
        val definitions =
            listOf(
                TypeDefinition.partial(
                    id = weighted,
                    parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = weighted, index = 0), name = "T")),
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                record(
                    source,
                    field(source, "primary", weightedText.template),
                    field(source, "choices", StandardTypes.list.template(listOf(weightedText.template))),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, catalog(definitions)).map { it.type to it.occurrences } shouldBe
            listOf(weightedText.toUse() to 2L)
    }

    test("skips overrides and unavailable targets") {
        val available = id("Available")
        val unavailable = id("Unavailable")
        val parent = id("Parent")
        val child = id("Child")
        val definitions =
            listOf(
                TypeDefinition.partial(
                    id = available,
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                TypeDefinition.partial(
                    id = unavailable,
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                record(parent, field(parent, "value", available.template())),
                record(
                    child,
                    FieldDeclaration.partial(
                        owner = FieldOwner(definition = child, name = "value"),
                        type = available.template(),
                        overrides = listOf(FieldOwner(definition = parent, name = "value")),
                    ),
                    field(child, "invalid", unavailable.template()),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, catalog(definitions, unavailable)).map { it.type.definition to it.occurrences } shouldBe
            listOf(available to 1L)
    }

    test("orders equal counts by canonical type") {
        val alpha = id("Alpha")
        val beta = id("Beta")
        val source = id("Source")
        val definitions =
            listOf(
                TypeDefinition.partial(
                    id = alpha,
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                TypeDefinition.partial(
                    id = beta,
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                record(
                    source,
                    field(source, "beta", beta.template()),
                    field(source, "alpha", alpha.template()),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, catalog(definitions)).map { it.type.definition } shouldBe listOf(alpha, beta)
    }
}

private fun id(name: String) = TypeDefinitionId.qualified("recommendation", name)

private fun field(
    owner: TypeDefinitionId,
    name: String,
    type: TypeTemplate,
) = FieldDeclaration.partial(owner = FieldOwner(definition = owner, name = name), type = type)

private fun record(
    id: TypeDefinitionId,
    vararg fields: FieldDeclaration,
) = TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = fields.toList(), abstract_ = false))

private fun NamedTypeTemplate.toUse() =
    definition.namedUse(
        arguments.map {
            when (it) {
                is TypeTemplate.ScalarWrapper -> {
                    it.value.use
                }

                else -> {
                    error("Test template is not complete.")
                }
            }
        },
    )

private fun catalog(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    unavailable: TypeDefinitionId? = null,
) = DefaultCheckedCatalog(
    CatalogGeneration(value = "recommendations"),
    StandardTypes.definitions + definitions.values,
    quarantine = listOfNotNull(unavailable?.let { DeclarationDiagnostic(it, "fixture_unavailable") }),
)
