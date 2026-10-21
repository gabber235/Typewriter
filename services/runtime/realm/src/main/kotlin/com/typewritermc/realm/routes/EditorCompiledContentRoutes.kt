package com.typewritermc.realm.routes

import com.typewritermc.engine.PublishedContentCodec
import com.typewritermc.realm.compiler.PublicationResults
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse

/** Answers with the immutable descriptor of the currently selected complete publication. */
internal class EditorCompiledContentRoutes(
    private val content: PublicationResults,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.queryPublishedContent) {
                val selected = content.selected()
                if (selected == null) {
                    QueryPublishedContentResponse.createAbsent()
                } else {
                    QueryPublishedContentResponse.ContentWrapper(PublishedContentCodec.encode(selected))
                }
            }
        }
}
