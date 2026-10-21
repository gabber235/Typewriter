package com.typewritermc.discovery

import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.TagDefinition
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath

val PlacementFieldPublicationTest by testSuite {
    test("the single field typed as a placement is published with its path") {
        val assembly = assemble()
        val placement = ValuePath.root.field("placement")

        assembly.placementField(TagDefinition.id) shouldBe placement
        // Fields typed as the sealed placement base count as placements too.
        assembly.placementField(ElementDefinition.id) shouldBe placement
        assembly.placementField(BookDefinition.id) shouldBe null
        assembly.editorCatalog.types
            .single { it.definition == TagDefinition.declaration }
            .placementField
            ?.segments
            ?.size shouldBe 1
    }

    test("a type with two placement fields publishes none and reports the ambiguity") {
        val twice = TypeDefinitionId.qualified("fixture", "TwicePlaced")
        val declaration =
            TypeDefinition.partial(
                id = twice,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf("first", "second").map { name ->
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = twice, name = name),
                                    type = GraphPlacementDefinition.id.template(),
                                )
                            },
                        abstract_ = false,
                    ),
            )
        val assembly = assemble(declaration)

        assembly.placementField(twice) shouldBe null
        assembly.editorCatalog.diagnostics
            .filter { it.affected == twice }
            .map { it.code } shouldBe listOf("ambiguous_placement_field")
    }
}

private fun assemble(vararg extra: TypeDefinition): CatalogAssembly {
    val origin = providerOrigin()
    val generated = generatedTypeProviders().distinctBy { it.definition.id }
    return CatalogContributions(
        declarations =
            generated.map { OwnedTypeDeclaration(origin, it.definition, it.display) } +
                extra.map { OwnedTypeDeclaration(origin, it) },
    ).assemble(CatalogAssemblyContext(CatalogGeneration("placement field publication")))
}

private fun CatalogAssembly.placementField(type: TypeDefinitionId): ValuePath? = placementFields[type]
