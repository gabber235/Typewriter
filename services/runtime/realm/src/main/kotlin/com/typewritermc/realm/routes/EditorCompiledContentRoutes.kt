package com.typewritermc.realm.routes

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.CompiledArtifactActivation
import com.typewritermc.engine.CompiledArtifactPointer
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.realm.compiler.RegisteredCompiledContentRepository
import com.typewritermc.realm.compiler.RegisteredCompiledState
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.compiled_content.WatchCompiledContentResponse

/** Serves the active generic compiled artifact activation and later activation updates. */
internal class EditorCompiledContentRoutes(
    private val content: RegisteredCompiledContentRepository,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchCompiledContent) {
                WatchCompiledContentResponse.createInitial(activation = content.activeActivation()?.toWire())
            }
        }
}

/** Publishes generic activation updates without decoding projection payloads. */
internal class EditorCompiledContentEvents {
    @Volatile
    private var publisher: Publisher? = null

    internal fun configure(
        contracts: EditorContracts,
        address: RealmAddress,
        communicator: Communicator,
    ) {
        publisher = Publisher(communicator, contracts, address)
    }

    suspend fun publishActivated(activation: CompiledArtifactActivation) {
        val current = publisher ?: return
        current.communicator.publish(
            current.contracts.compiledContentActivated,
            current.address,
            WatchCompiledContentResponse.ActivatedWrapper(activation.toWire()),
        )
    }

    suspend fun publishBlocked() {
        val current = publisher ?: return
        current.communicator.publish(
            current.contracts.compiledContentActivated,
            current.address,
            WatchCompiledContentResponse.createBlocked(),
        )
    }

    suspend fun publishStates(
        sourceSequence: String,
        generation: String,
        states: Map<CompilationRoot, RegisteredCompiledState>,
    ) {
        val current = publisher ?: return
        current.communicator.publish(
            current.contracts.compiledContentChanged,
            current.address,
            skirout.editor.v1.compiled_content.CompiledContentChanged(
                generation =
                    skirout.editor.v1.type_catalog
                        .CatalogGeneration(value = generation),
                sourceSequence = sourceSequence.toLongOrNull() ?: 0L,
                states = states.map { (root, state) -> state.toWire(root) },
            ),
        )
    }

    private data class Publisher(
        val communicator: Communicator,
        val contracts: EditorContracts,
        val address: RealmAddress,
    )
}

private fun RegisteredCompiledState.toWire(root: CompilationRoot) =
    when (this) {
        RegisteredCompiledState.NotCompiled -> {
            skirout.editor.v1.compiled_content.CompiledResourceStateChange.createUpsert(
                root = root.toWire(),
                state = skirout.editor.v1.compiled_content.CompiledResourceState.NOT_COMPILED,
            )
        }

        is RegisteredCompiledState.Active -> {
            skirout.editor.v1.compiled_content.CompiledResourceStateChange.createUpsert(
                root = root.toWire(),
                state =
                    skirout.editor.v1.compiled_content.CompiledResourceState
                        .createActive(manifestId = manifestId),
            )
        }

        is RegisteredCompiledState.Blocked -> {
            skirout.editor.v1.compiled_content.CompiledResourceStateChange.createUpsert(
                root = root.toWire(),
                state =
                    skirout.editor.v1.compiled_content.CompiledResourceState.createBlocked(
                        lastActiveManifestId = lastActiveManifestId,
                        diagnosticCount = diagnosticCount,
                    ),
            )
        }
    }

private fun CompilationRoot.toWire() =
    skirout.editor.v1.compiled_content.CompilationRoot(
        projection =
            skirout.editor.v1.compiled_content
                .CompilationProjectionId(value = projection.value),
        resource =
            skirout.editor.v1.type_catalog
                .ResourceId(value = resource.value),
    )

private fun CompiledArtifactActivation.toWire() =
    skirout.editor.v1.compiled_content.CompiledContentActivation(
        activationRevision = activationRevision,
        manifestDigest = manifestDigest.value,
        manifest = manifest.toWire(),
        artifacts = artifacts.map(CompiledArtifactPointer::toWire),
    )

private fun CompiledArtifactPointer.toWire() =
    skirout.editor.v1.compiled_content.CompiledArtifactPointer(
        semanticDigest = semanticDigest.value,
        blob = blob.toWire(),
    )

private fun CompiledBlobPointer.toWire() =
    skirout.editor.v1.compiled_content.CompiledBlobPointer(
        digest = digest.value,
        size = size,
    )
