package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.realm.publication.PublicationResults
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse

/** Answers with the immutable descriptor of the currently selected complete publication. */
internal class EditorCompiledContentRoutes(
    private val content: PublicationResults,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.authoringCompiledQuery) {
                val selected = content.selected()
                if (selected == null) {
                    QueryPublishedContentResponse.createAbsent()
                } else {
                    QueryPublishedContentResponse.ContentWrapper(selected)
                }
            }
        }
}
