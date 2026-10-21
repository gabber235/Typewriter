@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.resource
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.PresentationId

val NativeTypeIdentityTest by testSuite {
    test("abstract resource identity builds queries without a native codec") {
        val assembly = nativeIdentityAssembly(ambiguous = false)
        assembly.snapshot.presentationMaterials.size shouldBe 1
        assembly.snapshot.diagnostics.any { it.code == "presentation_material_build_failed" } shouldBe false
    }

    test("conflicting declarations cannot choose an arbitrary native class identity") {
        val assembly = nativeIdentityAssembly(ambiguous = true)
        assembly.snapshot.presentationMaterials shouldBe emptyList()
        assembly.snapshot.diagnostics.any { it.code == "presentation_material_build_failed" } shouldBe true
    }
}

private interface AbstractQueryResource : Resource

private fun nativeIdentityAssembly(ambiguous: Boolean): CatalogAssembly {
    val origin =
        ProviderOrigin(
            owner =
                DeclarationOwner(
                    ContributionKey(ContributionSourceId("test"), "main", ProducerId("query"), ContributionName("native_identity")),
                    "native identity",
                ),
            artifact = ArtifactId("test:native_identity"),
            sourcePart = "main",
        )
    val id = TypeDefinitionId(TypeId.Qualified("query.test", "Abstract"), 1)
    val definition = TypeDefinition(id, representation = RepresentationTemplate.Record(emptyList(), abstract = true))
    val descriptor =
        PresentationDescriptor(
            PresentationId(namespace = "test", name = "native_identity"),
            origin.owner,
            PresentationTarget.Named(TypeTemplate.Named(id)),
            setOf(PresentationRole.INSPECTOR),
            0,
        )
    val provider =
        object : PresentationProvider {
            override fun build(binding: PresentationBuildBinding) =
                DefaultPresentationRuntime().build(binding) { scope ->
                    with(scope) {
                        val observed = resource<AbstractQueryResource>(literal(ResourceId("observed")))
                        text(observed.id.text.orElse(literal("")))
                    }
                }
        }
    return CatalogContributions(
        declarations =
            listOf(
                OwnedTypeDeclaration(origin, definition, nativeClass = AbstractQueryResource::class),
                OwnedTypeDeclaration(origin, ResourceIdDefinition.declaration, nativeClass = ResourceId::class),
            ) +
                if (ambiguous) {
                    listOf(
                        OwnedTypeDeclaration(
                            origin,
                            definition.copy(id = TypeDefinitionId(TypeId.Qualified("query.test", "Conflicting"), 1)),
                            nativeClass = AbstractQueryResource::class,
                        ),
                    )
                } else {
                    emptyList()
                },
        presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
    ).assemble(CatalogAssemblyContext(CatalogGeneration("native identity")))
}
