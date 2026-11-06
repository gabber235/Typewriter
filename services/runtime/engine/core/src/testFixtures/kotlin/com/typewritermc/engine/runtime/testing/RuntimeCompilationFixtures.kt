package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.Root
import com.typewritermc.engine.encodeShard
import com.typewritermc.engine.runtime.ResourceGraphContentGateway
import com.typewritermc.engine.semanticDigest
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.toTemplate
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.compiled_content.RuntimeRelationFact
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.PublicationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

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

/** The page every admission fixture resource is rooted at. */
val admissionPage = ResourceId("page").toSkir()

/** A page resource of the resource type whose value nests a value of [payload], declaring [types]. */
fun admissionFacts(
    types: List<TypeDefinition> = listOf(resourceDefinition, payloadDefinition),
    relations: List<RuntimeRelationFact> = emptyList(),
    payload: TypeDefinitionId = payloadDefinition.id,
): RuntimeCompilationFacts {
    val key = CompiledResourceKey(source = admissionPage, context = CompilationContext.Root)
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
                                payload.namedUse(),
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

/** A publication of one resource graph artifact per [facts], each payload matching its manifest. */
fun publicationOf(vararg facts: RuntimeCompilationFacts): LoadedPublishedContent =
    LoadedPublishedContent(
        PublishedContent(
            publication = PublicationId(value = "publication:admission"),
            formatRevision = PUBLISHED_CONTENT_FORMAT_REVISION,
            catalog = CatalogGeneration(value = "runtime encoding test"),
            implementationToken = "implementation",
            outputs = emptyList(),
        ),
        facts.map { compiled ->
            LoadedCompiledArtifact(
                CompiledArtifactReference(
                    root = CompilationRoot(projection = RESOURCE_GRAPH_PROJECTION, resource = compiled.root.source),
                    formatRevision = compiled.formatRevision,
                    mediaType = RESOURCE_GRAPH_MEDIA_TYPE,
                    semanticDigest = compiled.semanticDigest().value,
                ),
                compiled.encodeShard(),
            )
        },
    )

/** An engine content gateway over the admission catalog, with no native bindings: admission runs before any decoding. */
fun gateway(): ResourceGraphContentGateway =
    admissionCatalog().let { catalog ->
        ResourceGraphContentGateway(catalog, FactoryNativeBindingRegistry(catalog, emptyList()), emptyList())
    }

/** A concrete content record [id] with [fields], each declared by [id]. */
fun contentRecord(
    id: TypeDefinitionId,
    vararg fields: Pair<String, TypeUse>,
): TypeDefinition =
    TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    fields.map { (name, type) ->
                        FieldDeclaration(
                            owner = FieldOwner(definition = id, name = name),
                            type = type.toTemplate(),
                            overrides = emptyList(),
                            hasConstructorDefault = false,
                        )
                    },
                form = RecordForm.CONCRETE,
            ),
    )
