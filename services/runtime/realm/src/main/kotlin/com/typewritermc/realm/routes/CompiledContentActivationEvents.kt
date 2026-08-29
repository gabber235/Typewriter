package com.typewritermc.realm.routes

import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.CompiledContentActivation
import com.typewritermc.realm.outbox.OutboxEvent
import skirout.library.v2.authoring.WatchCompiledContentResponse

class CompiledContentActivationEvents {
    @Volatile
    private var encoder: ((CompiledContentActivation) -> List<OutboxEvent>)? = null

    internal fun configure(
        contracts: LibraryContracts,
        address: RealmAddress,
    ) {
        encoder = { activation ->
            listOf(
                contracts.watchCompiledContent.encodeUpdate(
                    address,
                    WatchCompiledContentResponse.ActivatedWrapper(activation.toSkir()),
                ),
            )
        }
    }

    fun encode(activation: CompiledContentActivation): List<OutboxEvent> = encoder?.invoke(activation).orEmpty()
}

internal fun CompiledContentActivation.toSkir() =
    skirout.library.v2.authoring.CompiledContentActivation(
        activationRevision = activationRevision,
        manifestDigest = manifestDigest.value,
        manifest = manifest.toSkir(),
        shards =
            shards.map {
                skirout.library.v2.authoring.CompiledShardPointer(
                    shardDigest = it.shard.value,
                    blob = it.blob.toSkir(),
                )
            },
    )

private fun CompiledBlobPointer.toSkir() =
    skirout.library.v2.authoring
        .CompiledBlobPointer(digest = digest.value, size = size)
