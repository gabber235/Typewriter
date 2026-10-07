package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.PublicationAttempt
import com.typewritermc.realm.compiler.PublicationReport
import com.typewritermc.realm.compiler.PublicationResult
import com.typewritermc.realm.compiler.PublicationResults
import com.typewritermc.realm.compiler.PublicationState
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.publication.PublishAuthoringResponse
import skirout.editor.v1.publication.PublicationReport as WirePublicationReport
import skirout.editor.v1.publication.PublicationResult as WirePublicationResult
import skirout.editor.v1.publication.PublicationState as WirePublicationState

internal class PublicationRoutes(
    private val publisher: RealmPublicationCoordinator,
    private val results: PublicationResults,
    private val contracts: EditorContracts,
    private val address: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.publishAuthoring) { call ->
                val result =
                    publisher.publish { attempt ->
                        call.communicator
                            .publishUpdate(
                                contracts.watchPublication,
                                address,
                                attempt.toReport().toWire(),
                            ).requirePublished()
                        if (attempt.state == PublicationState.Complete) {
                            call.communicator
                                .publish(
                                    contracts.compiledContentChanged,
                                    address,
                                    skirout.editor.v1.compiled_content.CompiledContentChanged(
                                        generation =
                                            skirout.editor.v1.type_catalog
                                                .CatalogGeneration(value = attempt.catalog.value),
                                    ),
                                ).requirePublished()
                        }
                    }
                PublishAuthoringResponse.ResultWrapper(result.toWire())
            }
            watch(contracts.watchPublication) {
                (publisher.currentAttempt()?.toReport() ?: results.latestReport())?.toWire() ?: WirePublicationReport.partial()
            }
        }
}

private fun PublicationAttempt.toReport() = PublicationReport(id, state, (state as? PublicationState.Blocked)?.findings.orEmpty())

private fun PublicationReport.toWire() =
    WirePublicationReport(
        id =
            skirout.editor.v1.type_catalog
                .PublicationId(value = id.value),
        state = state.toWire(),
        findings =
            findings.map {
                SkirTypeCodec.encode(it).getOrThrow()
            },
    )

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
