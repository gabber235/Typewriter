package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringPreviewResult
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.library.v1.authoring.AuthoringDiagnostic
import skirout.library.v1.authoring.AuthoringInvalid
import skirout.library.v1.authoring.GetAuthoringSnapshotResponse

/**
 * Owns the messaging boundary for Realm authoring reads and writes.
 *
 * The repository is authoritative for state and batch atomicity. This class translates invalid arguments into
 * structured protocol diagnostics, publishes a committed change after the repository returns, and asks the compiler
 * owner to invalidate only after a successful batch that affects compiled content.
 */
internal class AuthoringRoutes(
    private val repository: AuthoringRepository,
    private val communicator: Communicator,
    private val contracts: LibraryContracts,
    private val address: RealmAddress,
    private val onCompilationInvalidated: () -> Unit,
) {
    /**
     * Adds the snapshot and batch operations to a router being assembled for one Realm address.
     *
     * The returned responses are produced by the same repository operation that supplies the publication payload.
     * Publication failure therefore remains a transport concern rather than changing the committed result.
     */
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
            unary(contracts.previewAuthoringBatch) { call ->
                try {
                    repository.preview(call.request.toDomain()).toWireResponse()
                } catch (invalid: IllegalArgumentException) {
                    AuthoringPreviewResult
                        .Invalid(
                            listOf(
                                com.typewritermc.realm.repository.AuthoringDiagnostic(
                                    code = "invalid-request",
                                    message = invalid.message ?: "Invalid authoring preview request.",
                                ),
                            ),
                        ).toWireResponse()
                }
            }
        }
}
