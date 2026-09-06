package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.CompiledContentRepository
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes

/**
 * Builds a fresh application route set for one Realm messaging session.
 *
 * Repositories and catalog sources survive router replacement. Creating routes also retargets compiled event
 * publication to the supplied communicator; the caller owns starting and stopping the resulting router.
 */
class RealmRouteFactory(
    private val authoring: AuthoringRepository,
    private val compiledContent: CompiledContentRepository,
    private val editorCatalog: RealmEditorCatalogSource,
    private val presentationSearch: RealmPresentationSearchSource,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
    private val compiledContentEvents: CompiledContentEvents? = null,
    private val onCompilationInvalidated: () -> Unit = {},
) {
    fun create(
        address: RealmAddress,
        communicator: Communicator,
    ): CommunicatorRoutes {
        val contracts = LibraryContracts(address)
        compiledContentEvents?.configure(contracts, address, communicator)
        val authoringRoutes = AuthoringRoutes(authoring, communicator, contracts, address, onCompilationInvalidated)
        val compiledContentRoutes = CompiledContentRoutes(compiledContent, contracts)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, contracts, address)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, contracts, address)
        val capabilityInvocationRoutes = capabilityInvocations?.let { RealmCapabilityInvocationRoutes(it, contracts) }
        return communicatorRoutes {
            authoringRoutes.register(this)
            compiledContentRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
            capabilityInvocationRoutes?.register(this)
        }
    }
}
