package com.typewritermc.discovery

import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.TagDefinition
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.catalog.toWire
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val PlacementFieldPublicationTest by testSuite {
    test("the single field typed as a placement is published with its path") {
        val assembly = assemble()
        val placement = ValuePath(listOf(PathSegment.Field("placement")))

        assembly.placementField(TagDefinition.id) shouldBe placement
        // Fields typed as the sealed placement base count as placements too.
        assembly.placementField(ElementDefinition.id) shouldBe placement
        assembly.placementField(BookDefinition.id) shouldBe null
        assembly.snapshot
            .toWire()
            .types
            .single { it.definition == SkirTypeCodec.encode(TagDefinition.declaration).getOrThrow() }
            .placementField
            ?.segments
            ?.size shouldBe 1
    }

    test("a type with two placement fields publishes none and reports the ambiguity") {
        val twice = TypeDefinitionId(TypeId.Qualified("fixture", "TwicePlaced"), 1)
        val declaration =
            TypeDefinition(
                twice,
                representation =
                    RepresentationTemplate.Record(
                        listOf("first", "second").map { name ->
                            FieldDeclaration(FieldOwner(twice, name), TypeTemplate.Named(GraphPlacementDefinition.id))
                        },
                    ),
            )
        val assembly = assemble(declaration)

        assembly.placementField(twice) shouldBe null
        assembly.snapshot.diagnostics
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

private fun CatalogAssembly.placementField(type: TypeDefinitionId): ValuePath? =
    snapshot.types.single { it.definition.id == type }.placementField
