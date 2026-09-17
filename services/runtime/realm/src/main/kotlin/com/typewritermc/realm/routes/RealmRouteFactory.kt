package com.typewritermc.realm.routes

import com.typewritermc.realm.compiler.CompiledContentRepository
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.search.AuthoringSearchRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes

/**
 * Builds a fresh application route set for one Realm messaging session.
 *
 * Repositories and catalog sources survive router replacement. The route set binds authoring, compiled content,
 * catalog, presentation search, and optional capability invocation operations. Creating routes also retargets
 * compiled event publication to the supplied communicator; the caller owns starting and stopping the resulting
 * router.
 */
internal class RealmRouteFactory(
    private val authoring: AuthoringRepository,
    private val authoringSearch: AuthoringSearchRepository,
    private val compiledContent: CompiledContentRepository,
    private val editorCatalog: RealmEditorCatalogSource,
    private val presentationSearch: RealmPresentationSearchSource,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
    private val compiledContentEvents: CompiledContentEvents? = null,
    private val onCompilationInvalidated: () -> Unit = {},
) {
    /**
     * Creates an unstarted route set for one logical Realm session.
     *
     * The communicator and address become the destination for replies and events. Callers must start and stop the
     * router returned by this method, and must not reuse it after stopping.
     */
    fun create(
        address: RealmAddress,
        communicator: Communicator,
    ): CommunicatorRoutes {
        val contracts = LibraryContracts(address)
        compiledContentEvents?.configure(contracts, address, communicator)
        val authoringRoutes = AuthoringRoutes(authoring, communicator, contracts, address, onCompilationInvalidated)
        val authoringSearchRoutes = AuthoringSearchRoutes(authoringSearch, contracts)
        val compiledContentRoutes = CompiledContentRoutes(compiledContent, contracts)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, contracts, address)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, contracts, address)
        val capabilityInvocationRoutes = capabilityInvocations?.let { RealmCapabilityInvocationRoutes(it, contracts) }
        return communicatorRoutes {
            authoringRoutes.register(this)
            authoringSearchRoutes.register(this)
            compiledContentRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
            capabilityInvocationRoutes?.register(this)
        }
    }
}
