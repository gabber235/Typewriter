package com.typewritermc.engine.runtime

import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompilationContext
import com.typewritermc.engine.CompiledResource
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.engine.RuntimeCompilationFacts
import com.typewritermc.engine.canonicalized
import com.typewritermc.types.DataValue
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow

val RuntimeCompilationEncodingTest by testSuite {
    test("conflicting declarations with one identity are rejected before canonical encoding") {
        val id = TypeDefinitionId(TypeId.Qualified("test", "runtime"), 1)
        val facts =
            RuntimeCompilationFacts(
                formatRevision = 2,
                root = CompiledResourceKey(ResourceId("page"), CompilationContext.Root),
                resources = emptyList(),
                edges = emptyList(),
                types =
                    listOf(
                        TypeDefinition(id, representation = RepresentationTemplate.Scalar(ScalarKind.Text)),
                        TypeDefinition(id, representation = RepresentationTemplate.Scalar(ScalarKind.Boolean)),
                    ),
                relations = emptyList(),
            )

        shouldThrow<IllegalArgumentException> { facts.canonicalized() }
    }

    test("admission closes declarations from the resource level actual type") {
        val resourceId = TypeDefinitionId(TypeId.Qualified("test", "resource"), 1)
        val payloadId = TypeDefinitionId(TypeId.Qualified("test", "payload"), 1)
        val resourceDefinition = TypeDefinition(resourceId, representation = RepresentationTemplate.Scalar(ScalarKind.Text))
        val payloadDefinition = TypeDefinition(payloadId, representation = RepresentationTemplate.Scalar(ScalarKind.Text))
        val key = CompiledResourceKey(ResourceId("page"), CompilationContext.Root)
        val facts =
            RuntimeCompilationFacts(
                formatRevision = 2,
                root = key,
                resources =
                    listOf(
                        CompiledResource(
                            key = key,
                            definition = ResourceDefinitionId("page"),
                            actualType = TypeUse.Named(resourceId),
                            bindingProvider = NativeBindingId("test"),
                            bindingSignature = "test:v1",
                            value = DataValue.Named(TypeUse.Named(payloadId), DataValue.StringValue("value")),
                        ),
                    ),
                edges = emptyList(),
                types = listOf(resourceDefinition, payloadDefinition),
                relations = emptyList(),
            )
        val catalog = DefaultCheckedCatalog(CatalogGeneration("runtime encoding test"), listOf(resourceDefinition, payloadDefinition))

        facts.requireAccepted(catalog, emptyList())
    }
}
