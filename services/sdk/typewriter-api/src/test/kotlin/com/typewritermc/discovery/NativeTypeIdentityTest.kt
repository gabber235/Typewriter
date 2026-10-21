@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.of
import com.typewritermc.presentation.resource
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

val NativeTypeIdentityTest by testSuite {
    test("abstract resource identity builds queries without a native codec") {
        val assembly = nativeIdentityAssembly(ambiguous = false)
        assembly.editorCatalog.presentationMaterials.size shouldBe 1
        assembly.editorCatalog.diagnostics.any { it.code == "presentation_material_build_failed" } shouldBe false
    }

    test("conflicting declarations cannot choose an arbitrary native class identity") {
        val assembly = nativeIdentityAssembly(ambiguous = true)
        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
        assembly.editorCatalog.diagnostics.any { it.code == "presentation_material_build_failed" } shouldBe true
    }
}

private interface AbstractQueryResource : Resource

private fun nativeIdentityAssembly(ambiguous: Boolean): CatalogAssembly {
    val origin =
        ProviderOrigin(
            owner =
                DeclarationOwner(
                    source =
                        contributionKey(
                            ContributionSourceId("test"),
                            "main",
                            ProducerId("query"),
                            ContributionName("native_identity"),
                        ),
                    localIdentity = "native identity",
                ),
            artifact = ArtifactId("test:native_identity"),
            sourcePart = "main",
        )
    val id = TypeDefinitionId.qualified("query.test", "Abstract")
    val definition =
        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true))
    val descriptor =
        PresentationDescriptor.of(
            PresentationId(namespace = "test", name = "native_identity"),
            origin.owner,
            PresentationTarget.NamedWrapper(id.namedTemplate()),
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
                            definition.copy(id = TypeDefinitionId.qualified("query.test", "Conflicting")),
                            nativeClass = AbstractQueryResource::class,
                        ),
                    )
                } else {
                    emptyList()
                },
        presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "native identity")))
}
