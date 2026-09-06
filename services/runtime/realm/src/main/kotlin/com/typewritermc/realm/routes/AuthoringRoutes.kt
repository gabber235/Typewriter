package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.library.v1.authoring.AuthoringDiagnostic
import skirout.library.v1.authoring.AuthoringInvalid
import skirout.library.v1.authoring.GetAuthoringSnapshotResponse

/**
 * Maps snapshot and batch requests to transactional authoring and publishes accepted changes afterward.
 *
 * Invalid arguments become protocol diagnostics. Publication and compiler invalidation occur after repository
 * commit, so reply delivery is not an atomic part of the edit; clients recover through batch replay and snapshots.
 */
internal class AuthoringRoutes(
    private val repository: AuthoringRepository,
    private val communicator: Communicator,
    private val contracts: LibraryContracts,
    private val address: RealmAddress,
    private val onCompilationInvalidated: () -> Unit,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.getAuthoringSnapshot) { call ->
                try {
                    repository.snapshot(call.request.scopes.toDomain()).toWireResponse()
                } catch (invalid: IllegalArgumentException) {
                    GetAuthoringSnapshotResponse.InvalidWrapper(
                        AuthoringInvalid(
                            diagnostics =
                                listOf(
                                    AuthoringDiagnostic(
                                        code = "invalid-request",
                                        message = invalid.message ?: "Invalid authoring snapshot request.",
                                        resource = null,
                                        path = null,
                                    ),
                                ),
                        ),
                    )
                }
            }
            unary(contracts.applyAuthoringBatch) { call ->
                val result =
                    try {
                        repository.apply(call.request.toDomain())
                    } catch (invalid: IllegalArgumentException) {
                        AuthoringBatchResult.Invalid(
                            listOf(
                                com.typewritermc.realm.repository.AuthoringDiagnostic(
                                    code = "invalid-request",
                                    message = invalid.message ?: "Invalid authoring batch request.",
                                ),
                            ),
                        )
                    }
                if (result is AuthoringBatchResult.Applied) {
                    communicator.publish(contracts.authoringChanged, address, result.change.toWire())
                    if (result.affectsCompilation) onCompilationInvalidated()
                }
                result.toWireResponse()
            }
        }
}
