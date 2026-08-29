package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.PageDocumentRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.library.v2.authoring.GetPageDocumentResponse
import skirout.library.v2.authoring.WatchPageDocumentsResponse

internal class PageDocumentRoutes(
    private val documents: PageDocumentRepository,
    private val contracts: LibraryContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchPageDocuments) { WatchPageDocumentsResponse.INITIAL }
            unary(contracts.getPageDocument) { call ->
                val pageId = call.request.pageId
                pageId.invalidRecordId("page")?.let {
                    return@unary GetPageDocumentResponse.createInvalidRequest(
                        diagnostics = listOf("Expected a page record id."),
                    )
                }
                val document =
                    childSpan("db.page.document.get") { documents.getPageDocument(pageId.toPageId()) }
                        ?: return@unary GetPageDocumentResponse.createPageNotFound(pageId = pageId)
                GetPageDocumentResponse.SuccessWrapper(document.toWire())
            }
        }
}
