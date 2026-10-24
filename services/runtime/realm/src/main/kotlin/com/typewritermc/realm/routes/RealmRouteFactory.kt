package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.edit.AuthoringRepository
import com.typewritermc.realm.operation.ResourceOperationRuntime
import com.typewritermc.realm.publication.CompiledRootStatuses
import com.typewritermc.realm.publication.PublicationResults
import com.typewritermc.realm.publication.RealmPublicationCoordinator
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes

/** Rebinds long lived Realm services to one messaging session without transferring service lifecycle ownership. */
internal class RealmRouteFactory(
    private val authoring: AuthoringRepository,
    private val authoringSearch: AuthoringSearchRepository,
    private val views: AuthoringViewStore,
    private val checks: RealmCheckRuntime,
    private val compiledContent: PublicationResults,
    private val compiledRootStatuses: CompiledRootStatuses,
    private val publisher: RealmPublicationCoordinator,
    private val editorCatalog: RealmEditorCatalogSource,
    private val preparation: InitializationRuntime,
    private val presentationSearch: RealmPresentationSearchSource,
    private val capabilityInvocations: RealmCapabilityInvocationSource,
    private val editorUpdates: EditorUpdatePublisher,
) {
    fun create(
        address: RealmRouteScope,
        communicator: Communicator,
    ): CommunicatorRoutes {
        editorUpdates.configure(address, communicator)
        val authoringRoutes = AuthoringRoutes(authoring, views, checks::findings, address = address)
        val authoringSearchRoutes = AuthoringSearchRoutes(authoringSearch, views, address)
        val compiledContentRoutes = EditorCompiledContentRoutes(compiledContent, address)
        val compiledResourceStatusRoutes = EditorCompiledResourceStatusRoutes(views, compiledRootStatuses, address)
        val publicationRoutes = PublicationRoutes(publisher, address)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, preparation, address)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, address)
        val capabilityInvocationRoutes = RealmCapabilityInvocationRoutes(capabilityInvocations, address)
        val resourceOperationRoutes =
            ResourceOperationRoutes(
                ResourceOperationRuntime(views),
                address,
            )
        return communicatorRoutes {
            authoringRoutes.register(this)
            authoringSearchRoutes.register(this)
            compiledContentRoutes.register(this)
            compiledResourceStatusRoutes.register(this)
            publicationRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
            capabilityInvocationRoutes.register(this)
            resourceOperationRoutes.register(this)
        }
    }
}
