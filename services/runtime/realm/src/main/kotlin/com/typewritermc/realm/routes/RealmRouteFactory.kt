package com.typewritermc.realm.routes

import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.checking.RealmCheckRuntime
import com.typewritermc.realm.compiler.PublicationResults
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes

internal class RealmRouteFactory(
    private val authoring: AuthoringRepository,
    private val authoringSearch: AuthoringSearchRepository,
    private val snapshots: AuthoringViewStore,
    private val checks: RealmCheckRuntime,
    private val compiledContent: PublicationResults,
    private val publisher: RealmPublicationCoordinator,
    private val editorCatalog: RealmEditorCatalogSource,
    private val preparation: InitializationRuntime,
    private val presentationSearch: RealmPresentationSearchSource,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
    private val checkEvents: EditorCheckEvents? = null,
) {
    fun create(
        address: RealmAddress,
        communicator: Communicator,
    ): CommunicatorRoutes {
        val contracts = EditorContracts(address)
        checkEvents?.apply {
            bindFindings(checks::findings)
            configure(contracts, address, communicator)
        }
        val authoringRoutes =
            checkEvents?.let { AuthoringRoutes(authoring, snapshots, it, contracts = contracts) }
                ?: AuthoringRoutes(authoring, snapshots, checks::findings, contracts = contracts)
        val authoringSearchRoutes = AuthoringSearchRoutes(authoringSearch, snapshots, contracts)
        val compiledContentRoutes = EditorCompiledContentRoutes(compiledContent, contracts)
        val compiledResourceStatusRoutes = EditorCompiledResourceStatusRoutes(compiledContent, contracts)
        val publicationRoutes = PublicationRoutes(publisher, compiledContent, contracts, address)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, preparation, contracts)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, contracts, address)
        val capabilityInvocationRoutes = capabilityInvocations?.let { RealmCapabilityInvocationRoutes(it, contracts) }
        return communicatorRoutes {
            authoringRoutes.register(this)
            authoringSearchRoutes.register(this)
            compiledContentRoutes.register(this)
            compiledResourceStatusRoutes.register(this)
            publicationRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
            capabilityInvocationRoutes?.register(this)
        }
    }
}
