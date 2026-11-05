package com.typewritermc.engine.runtime.testing

import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.RESOURCE_GRAPH_MEDIA_TYPE
import com.typewritermc.engine.RESOURCE_GRAPH_PROJECTION
import com.typewritermc.engine.Root
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir
import skirout.editor.v1.compilation_root.CompilationRoot
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledArtifactReference
import skirout.editor.v1.compiled_content.CompiledBlobPointer
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.PublishedOutput
import skirout.editor.v1.compiled_content.ResourceGraphShard
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.PublicationId

/** A resource graph shard rooted at [pageKey], whose digest is [digestCharacter] repeated to 64 characters. */
fun shard(
    digestCharacter: String,
    pageKey: String,
) = ResourceGraphShard(
    digest = ContentDigest(digestCharacter.repeat(64)).value,
    facts =
        RuntimeCompilationFacts(
            formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
            root = CompiledResourceKey(source = ResourceId(pageKey).toSkir(), context = CompilationContext.Root),
            resources = emptyList(),
            edges = emptyList(),
            types = emptyList(),
            relations = emptyList(),
        ),
)

/** A published content at [revision] with one output per shard; each shard blob is stored in [blobs]. */
fun activation(
    revision: Long,
    shards: List<ResourceGraphShard>,
    blobs: InMemoryBlobEndpoint,
): PublishedContent {
    val outputs =
        shards.map { shard ->
            PublishedOutput(
                reference =
                    CompiledArtifactReference(
                        root =
                            CompilationRoot(
                                projection = RESOURCE_GRAPH_PROJECTION,
                                resource = shard.facts.root.source,
                            ),
                        formatRevision = shard.facts.formatRevision,
                        mediaType = RESOURCE_GRAPH_MEDIA_TYPE,
                        semanticDigest = shard.digest,
                    ),
                blob = blobs.put(ResourceGraphShard.serializer.toJsonCode(shard).encodeToByteArray()).toPointer(),
            )
        }
    return PublishedContent(
        publication = PublicationId(value = "publication:$revision"),
        formatRevision = com.typewritermc.engine.PUBLISHED_CONTENT_FORMAT_REVISION,
        catalog = CatalogGeneration(value = "catalog:1"),
        implementationToken = "implementation",
        outputs = outputs,
    )
}

/** The digest of the single blob that [PublishedContent] holds, as the blob endpoint names it. */
fun PublishedContent.blobDigest() = outputs.single().blob.artifactDigest()

private fun CompiledBlobPointer.artifactDigest() =
    ArtifactDigest(
        DigestAlgorithm.SHA_256,
        digest,
    )

private fun BlobMetadata.toPointer() = CompiledBlobPointer(digest = ContentDigest(digest.value).value, size = size)
