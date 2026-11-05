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
import com.typewritermc.testkit.elementsOf
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldNotContain
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
        assembly.editorCatalog.diagnostics.map { it.code } shouldNotContain "presentation_material_build_failed"
        val label =
            assembly.editorCatalog.presentationMaterials
                .single()
                .layout
                .elementsOf<skirout.editor.v1.presentation.PresentationElement.TextWrapper>()
                .single()
                .value.value
        com.typewritermc.expression.evaluate(label) shouldBe
            com.typewritermc.authoring.Availability
                .Available(
                    skirout.editor.v1.type_catalog.DataValue
                        .StringValueWrapper("observed"),
                )
    }

    test("conflicting declarations cannot choose an arbitrary native class identity") {
        val assembly = nativeIdentityAssembly(ambiguous = true)
        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
        assembly.editorCatalog.diagnostics.any { it.code == "presentation_material_build_failed" } shouldBe true
    }
}
