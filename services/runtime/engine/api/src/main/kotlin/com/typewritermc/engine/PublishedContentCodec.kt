package com.typewritermc.engine

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.scripting.RuntimeMemberId
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.scripting.ScriptCapabilityId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.compiled_content.CompilationProjectionId as WireProjectionId
import skirout.editor.v1.compiled_content.CompilationRoot as WireCompilationRoot
import skirout.editor.v1.compiled_content.CompiledArtifactReference as WireArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer as WireBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent as WirePublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput as WirePublishedOutput
import skirout.editor.v1.type_catalog.CatalogGeneration as WireCatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId as WirePublicationId
import skirout.editor.v1.type_catalog.ResourceId as WireResourceId

object PublishedContentCodec {
    fun encode(value: PublishedContent): WirePublishedContent =
        WirePublishedContent(
            publication = WirePublicationId(value = value.publication.value),
            formatRevision = value.formatRevision,
            catalog = WireCatalogGeneration(value = value.catalog.value),
            implementationToken = value.implementationToken,
            runtimeSignatures =
                value.runtimeSignatures.sortedBy { it.id.value }.map { signature ->
                    skirout.editor.v1.publication.RuntimeMemberSignature(
                        id =
                            skirout.editor.v1.type_catalog
                                .RuntimeMemberId(value = signature.id.value),
                        receiver = signature.receiver?.let { SkirTypeCodec.encode(it).getOrThrow() },
                        parameters = signature.parameters.map { SkirTypeCodec.encode(it).getOrThrow() },
                        result = SkirTypeCodec.encode(signature.result).getOrThrow(),
                        requiredCapabilities =
                            signature.requiredCapabilities
                                .sortedBy {
                                    it.value
                                }.map {
                                    skirout.editor.v1.type_catalog
                                        .ScriptCapabilityId(value = it.value)
                                },
                    )
                },
            outputs =
                value.outputs.map { output ->
                    WirePublishedOutput(
                        reference =
                            WireArtifactReference(
                                root =
                                    WireCompilationRoot(
                                        projection = WireProjectionId(value = output.reference.root.projection.value),
                                        resource = WireResourceId(value = output.reference.root.resource.value),
                                    ),
                                formatRevision = output.reference.formatRevision,
                                mediaType = output.reference.mediaType,
                                semanticDigest = output.reference.semanticDigest.value,
                            ),
                        blob = WireBlobPointer(digest = output.blob.digest.value, size = output.blob.size),
                    )
                },
        )

    fun decode(value: WirePublishedContent): PublishedContent =
        PublishedContent(
            publication = PublicationId(value.publication.value),
            formatRevision = value.formatRevision,
            catalog = CatalogGeneration(value.catalog.value),
            implementationToken = value.implementationToken,
            runtimeSignatures =
                value.runtimeSignatures.mapTo(linkedSetOf()) { signature ->
                    RuntimeMemberSignature(
                        id = RuntimeMemberId(signature.id.value),
                        receiver = signature.receiver?.let { SkirTypeCodec.decode(it).getOrThrow() },
                        parameters =
                            signature.parameters.map {
                                SkirTypeCodec.decode(it).getOrThrow()
                            },
                        result = SkirTypeCodec.decode(signature.result).getOrThrow(),
                        requiredCapabilities = signature.requiredCapabilities.mapTo(linkedSetOf()) { ScriptCapabilityId(it.value) },
                    )
                },
            outputs =
                value.outputs.map { output ->
                    PublishedOutput(
                        reference =
                            CompiledArtifactReference(
                                CompilationRoot(
                                    CompilationProjectionId(output.reference.root.projection.value),
                                    ResourceId(output.reference.root.resource.value),
                                ),
                                output.reference.formatRevision,
                                output.reference.mediaType,
                                ContentDigest(output.reference.semanticDigest),
                            ),
                        blob = CompiledBlobPointer(ContentDigest(output.blob.digest), output.blob.size),
                    )
                },
        )
}
