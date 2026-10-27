package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.Root
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.compiled_content.RuntimeRelationFact
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

/** One refused admission: the case name, the facts offered, and the start of the refusal message. */
data class AdmissionRejection(
    val name: String,
    val facts: RuntimeCompilationFacts,
    val reason: String,
)

private val TEXT = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT)

/** The resource type of the admission fixtures: text, reached as the resource of the page. */
val resourceDefinition = TypeDefinition.partial(id = TypeDefinitionId.qualified("test", "resource"), representation = TEXT)

/** The payload type of the admission fixtures: text, nested in the value of the page resource. */
val payloadDefinition = TypeDefinition.partial(id = TypeDefinitionId.qualified("test", "payload"), representation = TEXT)

/** A text type that no admission fixture resource reaches. */
val unrelatedDefinition = TypeDefinition.partial(id = TypeDefinitionId.qualified("test", "unrelated"), representation = TEXT)

/** The runtime catalog that declares the admission fixture types. */
fun admissionCatalog() =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "runtime encoding test"),
        listOf(resourceDefinition, payloadDefinition, unrelatedDefinition),
    )

/** A page resource of the resource type whose value nests a value of the payload type. */
fun admissionFacts(
    types: List<TypeDefinition> = listOf(resourceDefinition, payloadDefinition),
    relations: List<RuntimeRelationFact> = emptyList(),
): RuntimeCompilationFacts {
    val key = CompiledResourceKey(source = ResourceId("page").toSkir(), context = CompilationContext.Root)
    return RuntimeCompilationFacts(
        formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
        root = key,
        resources =
            listOf(
                CompiledResource(
                    key = key,
                    actualType = resourceDefinition.id.namedUse(),
                    bindingProvider = NativeBindingId(value = "test"),
                    bindingSignature = "test:v1",
                    value =
                        (
                            DataValue.named(
                                payloadDefinition.id.namedUse(),
                                DataValue.StringValueWrapper("value"),
                            ) as DataValue.NamedWrapper
                        ).value,
                ),
            ),
        edges = emptyList(),
        types = types,
        relations = relations,
    )
}
