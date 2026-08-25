package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.PageDocumentRepository
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.library.v2.authoring.WatchLibraryInvalidationsResponse

internal class LibraryInvalidationRoutes(
    private val documents: PageDocumentRepository,
    private val contracts: LibraryContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchLibraryInvalidations) {
                WatchLibraryInvalidationsResponse.createInitial(
                    revision = documents.currentCollaborationRevision(),
                )
            }
        }
}
