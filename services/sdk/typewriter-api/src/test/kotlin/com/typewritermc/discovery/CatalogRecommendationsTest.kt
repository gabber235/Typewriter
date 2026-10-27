package com.typewritermc.discovery

import com.typewritermc.testkit.fieldDeclaration
import com.typewritermc.testkit.recordType
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.of
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
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
        val weighted = TypeDefinitionId.qualified("recommendation", "Weighted")
        val source = TypeDefinitionId.qualified("recommendation", "Source")
        val weightedText = weighted.namedTemplate(listOf(ScalarKind.TEXT.template))
        val definitions =
            listOf(
                TypeDefinition.partial(
                    id = weighted,
                    parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = weighted, index = 0), name = "T")),
                    representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                ),
                recordType(
                    source,
                    fieldDeclaration(source, "primary", weightedText.template),
                    fieldDeclaration(source, "choices", StandardTypes.list.template(listOf(weightedText.template))),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, catalog(definitions)).map { it.type to it.occurrences } shouldBe
            listOf(weightedText.toUse() to 2L)
    }

    test("skips overrides and unavailable targets") {
        val available = TypeDefinitionId.qualified("recommendation", "Available")
        val unavailable = TypeDefinitionId.qualified("recommendation", "Unavailable")
        val parent = TypeDefinitionId.qualified("recommendation", "Parent")
        val child = TypeDefinitionId.qualified("recommendation", "Child")
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
                recordType(parent, fieldDeclaration(parent, "value", available.template())),
                recordType(
                    child,
                    FieldDeclaration.partial(
                        owner = FieldOwner(definition = child, name = "value"),
                        type = available.template(),
                        overrides = listOf(FieldOwner(definition = parent, name = "value")),
                    ),
                    fieldDeclaration(child, "invalid", unavailable.template()),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, catalog(definitions, unavailable)).map { it.type.definition to it.occurrences } shouldBe
            listOf(available to 1L)
    }

    test("orders equal counts by canonical type") {
        val alpha = TypeDefinitionId.qualified("recommendation", "Alpha")
        val beta = TypeDefinitionId.qualified("recommendation", "Beta")
        val source = TypeDefinitionId.qualified("recommendation", "Source")
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
                recordType(
                    source,
                    fieldDeclaration(source, "beta", beta.template()),
                    fieldDeclaration(source, "alpha", alpha.template()),
                ),
            ).associateBy(TypeDefinition::id)

        typeRecommendations(definitions, catalog(definitions)).map { it.type.definition } shouldBe listOf(alpha, beta)
    }
}
