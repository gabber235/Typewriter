package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.QueryAuthoringGraphResponse

internal class AuthoringGraphRoutes(
    private val repository: AuthoringGraphRepository,
    private val contracts: EditorContracts,
    private val subjects: AuthoringPresentationProjector,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryAuthoringGraph) { call ->
                try {
                    repository.query(call.request.generation.value, call.request.toDomain()).toWire(subjects)
                } catch (invalid: IllegalArgumentException) {
                    AuthoringGraphQueryResult
                        .Invalid("invalid-request", invalid.message ?: "Invalid authoring graph query.")
                        .toWire(subjects)
                } catch (failure: IllegalStateException) {
                    QueryAuthoringGraphResponse.createInvalid(
                        diagnostics =
                            listOf(
                                AuthoringDiagnostic(
                                    code = "invalid-stored-graph",
                                    message = failure.message ?: "Stored authoring graph is inconsistent.",
                                    resource = null,
                                    path = null,
                                ),
                            ),
                    )
                }
            }
        }
}
