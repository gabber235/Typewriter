package com.typewritermc.realm.routes

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.compiler.EngineImplementationInputs
import com.typewritermc.realm.compiler.PublicationAttempt
import com.typewritermc.realm.compiler.PublicationResult
import com.typewritermc.realm.compiler.PublicationState
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.PublicationAttempt as WirePublicationAttempt
import skirout.editor.v1.publication.PublicationResult as WirePublicationResult
import skirout.editor.v1.publication.PublicationState as WirePublicationState

internal class PublicationRoutes(
    private val publisher: RealmPublicationCoordinator,
    private val contracts: EditorContracts,
    private val address: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.publishAuthoring) { call ->
                val request = call.request
                val result =
                    if (request.state == WirePublicationState.CHECKING) {
                        publisher.publish(
                            id = PublicationId(request.id.value),
                            capture = SnapshotId(request.capture.value),
                            catalog = CatalogGeneration(request.catalog.value),
                            onTransition = { attempt ->
                                call.communicator
                                    .publishUpdate(contracts.watchPublication, address, attempt.toWire())
                                    .requirePublished()
                            },
                        )
                    } else {
                        PublicationResult.Publishing
                    }
                PublishAuthoringResponse.ResultWrapper(result.toWire())
            }
            watch(contracts.watchPublication) {
                publisher.currentAttempt()?.toWire() ?: WirePublicationAttempt.partial()
            }
        }
}

private fun PublicationResult.toWire(): WirePublicationResult =
    when (this) {
        PublicationResult.Publishing -> {
            WirePublicationResult.PUBLISHING
        }

        is PublicationResult.Activated -> {
            WirePublicationResult.createActivated(
                publication =
                    skirout.editor.v1.type_catalog
                        .PublicationId(value = publication.value),
                manifest = manifest,
            )
        }

        is PublicationResult.Blocked -> {
            WirePublicationResult.BlockedWrapper(findings.map { SkirTypeCodec.encode(it).getOrThrow() })
        }

        is PublicationResult.Interrupted -> {
            WirePublicationResult.InterruptedWrapper(
                skirout.editor.v1.type_catalog
                    .PublicationId(value = publication.value),
            )
        }
    }

private fun PublicationAttempt.toWire() =
    WirePublicationAttempt(
        id =
            skirout.editor.v1.type_catalog
                .PublicationId(value = id.value),
        capture =
            skirout.editor.v1.type_catalog
                .SnapshotId(value = capture.value),
        catalog =
            skirout.editor.v1.type_catalog
                .CatalogGeneration(value = catalog.value),
        engineInputs = engineInputs.toWire(),
        state = state.toWire(),
    )

private fun EngineImplementationInputs.toWire() =
    skirout.editor.v1.publication.EngineImplementationInputs(
        signatures = signatures.sortedBy { it.id.value }.map(RuntimeMemberSignature::toWire),
        token =
            skirout.editor.v1.type_catalog
                .InputToken(value = token.value),
    )

private fun RuntimeMemberSignature.toWire() =
    skirout.editor.v1.publication.RuntimeMemberSignature(
        id =
            skirout.editor.v1.type_catalog
                .RuntimeMemberId(value = id.value),
        receiver = receiver?.let { SkirTypeCodec.encode(it).getOrThrow() },
        parameters = parameters.map { SkirTypeCodec.encode(it).getOrThrow() },
        result = SkirTypeCodec.encode(result).getOrThrow(),
        requiredCapabilities =
            requiredCapabilities.sortedBy { it.value }.map {
                skirout.editor.v1.type_catalog
                    .ScriptCapabilityId(value = it.value)
            },
    )

private fun PublicationState.toWire(): WirePublicationState =
    when (this) {
        PublicationState.Checking -> {
            WirePublicationState.CHECKING
        }

        PublicationState.Compiling -> {
            WirePublicationState.COMPILING
        }

        PublicationState.Activating -> {
            WirePublicationState.ACTIVATING
        }

        PublicationState.Complete -> {
            WirePublicationState.COMPLETE
        }

        is PublicationState.Blocked -> {
            WirePublicationState.BlockedWrapper(findings.map { SkirTypeCodec.encode(it).getOrThrow() })
        }

        PublicationState.Interrupted -> {
            WirePublicationState.INTERRUPTED
        }
    }
