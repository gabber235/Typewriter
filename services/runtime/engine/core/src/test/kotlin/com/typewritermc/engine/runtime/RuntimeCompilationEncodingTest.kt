package com.typewritermc.engine.runtime

import com.typewritermc.engine.CompilationContext
import com.typewritermc.engine.CompiledResource
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.engine.RuntimeCompilationFacts
import com.typewritermc.engine.canonicalized
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

val RuntimeCompilationEncodingTest by testSuite {
    test("conflicting declarations with one identity are rejected before canonical encoding") {
        val id = TypeDefinitionId.qualified("test", "runtime")
        val facts =
            RuntimeCompilationFacts(
                formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
                root = CompiledResourceKey(ResourceId("page"), CompilationContext.Root),
                resources = emptyList(),
                edges = emptyList(),
                types =
                    listOf(
                        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT)),
                        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createScalar(kind = ScalarKind.BOOLEAN)),
                    ),
                relations = emptyList(),
            )

        shouldThrow<IllegalArgumentException> { facts.canonicalized() }
    }

    test("admission closes declarations from the resource level actual type") {
        val resourceId = TypeDefinitionId.qualified("test", "resource")
        val payloadId = TypeDefinitionId.qualified("test", "payload")
        val resourceDefinition =
            TypeDefinition.partial(id = resourceId, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
        val payloadDefinition =
            TypeDefinition.partial(id = payloadId, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
        val key = CompiledResourceKey(ResourceId("page"), CompilationContext.Root)
        val facts =
            RuntimeCompilationFacts(
                formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
                root = key,
                resources =
                    listOf(
                        CompiledResource(
                            key = key,
                            actualType = resourceId.namedUse(),
                            bindingProvider = NativeBindingId(value = "test"),
                            bindingSignature = "test:v1",
                            value = DataValue.named(payloadId.namedUse(), DataValue.StringValueWrapper("value")),
                        ),
                    ),
                edges = emptyList(),
                types = listOf(resourceDefinition, payloadDefinition),
                relations = emptyList(),
            )
        val catalog =
            DefaultCheckedCatalog(CatalogGeneration(value = "runtime encoding test"), listOf(resourceDefinition, payloadDefinition))

        facts.requireAccepted(catalog, emptyList())
    }
}
