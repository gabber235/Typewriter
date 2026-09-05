package com.typewritermc.realm.routes

import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.services.libs.communicator.client.Communicator
import skirout.library.v1.compiled_content.WatchCompiledContentResponse

class CompiledContentEvents {
    @Volatile
    private var publisher: Publisher? = null

    internal fun configure(
        contracts: LibraryContracts,
        address: RealmAddress,
        communicator: Communicator,
    ) {
        publisher = Publisher(communicator, contracts, address)
    }

    suspend fun publishActivated(activation: CompiledContentActivation) {
        publish(WatchCompiledContentResponse.ActivatedWrapper(activation.toSkir()))
    }

    suspend fun publishBlocked() {
        publish(WatchCompiledContentResponse.createBlocked())
    }

    private suspend fun publish(event: WatchCompiledContentResponse) {
        val current = publisher ?: return
        current.communicator.publish(
            current.contracts.compiledContentChanged,
            current.address,
            event,
        )
    }

    private data class Publisher(
        val communicator: Communicator,
        val contracts: LibraryContracts,
        val address: RealmAddress,
    )
}

internal fun CompiledContentActivation.toSkir() =
    skirout.library.v1.compiled_content.CompiledContentActivation(
        activationRevision = activationRevision,
        manifestDigest = manifestDigest.value,
        manifest = manifest.toSkir(),
        shards =
            shards.map {
                skirout.library.v1.compiled_content.CompiledShardPointer(
                    shardDigest = it.shard.value,
                    blob = it.blob.toSkir(),
                )
            },
    )

private fun CompiledBlobPointer.toSkir() =
    skirout.library.v1.compiled_content
        .CompiledBlobPointer(digest = digest.value, size = size)
