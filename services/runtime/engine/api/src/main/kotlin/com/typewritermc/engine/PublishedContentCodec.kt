package com.typewritermc.engine

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import skirout.editor.v1.compiled_content.CompiledArtifactReference as WireArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer as WireBlobPointer
import skirout.editor.v1.compiled_content.PublishedContent as WirePublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput as WirePublishedOutput
import skirout.editor.v1.type_catalog.CatalogGeneration as WireCatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId as WirePublicationId

object PublishedContentCodec {
    fun encode(value: PublishedContent): WirePublishedContent =
        WirePublishedContent(
            publication = WirePublicationId(value = value.publication.value),
            formatRevision = value.formatRevision,
            catalog = WireCatalogGeneration(value = value.catalog.value),
            implementationToken = value.implementationToken,
            outputs =
                value.outputs.map { output ->
                    WirePublishedOutput(
                        reference =
                            WireArtifactReference(
                                root = output.reference.root.toSkir(),
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
            outputs =
                value.outputs.map { output ->
                    PublishedOutput(
                        reference =
                            CompiledArtifactReference(
                                output.reference.root.toDomain(),
                                output.reference.formatRevision,
                                output.reference.mediaType,
                                ContentDigest(output.reference.semanticDigest),
                            ),
                        blob = CompiledBlobPointer(ContentDigest(output.blob.digest), output.blob.size),
                    )
                },
        )
}
