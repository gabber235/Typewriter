package com.typewritermc.realm.routes

import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.RealmAuthoringPolicyCatalog
import com.typewritermc.realm.compiler.RegisteredCompiledContentRepository
import com.typewritermc.realm.repository.AuthoringGraphRepository
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.search.AuthoringSearchMetadata
import com.typewritermc.realm.search.AuthoringSearchRepository
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.TypePrototypeRegistry

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
    private val authoringGraph: AuthoringGraphRepository,
    private val authoringSearch: AuthoringSearchRepository = AuthoringSearchRepository { _, _, _, _, _, _ -> emptyList() },
    private val compiledContent: RegisteredCompiledContentRepository,
    private val editorCatalog: RealmEditorCatalogSource,
    private val presentationSearch: RealmPresentationSearchSource,
    private val capabilityInvocations: RealmCapabilityInvocationSource? = null,
    private val compiledContentEvents: EditorCompiledContentEvents? = null,
    private val onCompilationInvalidated: (List<CompilationRoot>) -> Unit = {},
    private val prototypes: TypePrototypeRegistry = TypePrototypeRegistry(emptyList()),
    private val catalogGeneration: () -> String = { "test" },
    private val authoringPolicies: RealmAuthoringPolicyCatalog,
    private val authoringSearchMetadata: AuthoringSearchMetadata =
        AuthoringSearchMetadata(authoringPolicies.searchSelectors, authoringPolicies.searchFacets),
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
        val contracts = EditorContracts(address)
        val compiledContracts = contracts
        compiledContentEvents?.configure(compiledContracts, address, communicator)
        val authoringRoutes = AuthoringRoutes(authoring, communicator, contracts, address, prototypes, onCompilationInvalidated)
        val subjectProjector =
            AuthoringPresentationProjector(
                prototypes,
                authoringPolicies.presentations,
            )
        val authoringGraphRoutes = AuthoringGraphRoutes(authoringGraph, contracts, subjectProjector)
        val authoringGraphSearchRoutes =
            AuthoringGraphSearchRoutes(
                authoringGraph,
                authoringSearch,
                contracts,
                subjectProjector,
                authoringSearchMetadata,
            )
        val compiledContentRoutes = EditorCompiledContentRoutes(compiledContent, compiledContracts)
        val compiledResourceStatusRoutes = EditorCompiledResourceStatusRoutes(compiledContent, compiledContracts)
        val editorCatalogRoutes = EditorCatalogRoutes(editorCatalog, contracts, address)
        val presentationSearchRoutes = RealmPresentationSearchRoutes(presentationSearch, contracts, address)
        val capabilityInvocationRoutes = capabilityInvocations?.let { RealmCapabilityInvocationRoutes(it, contracts) }
        return communicatorRoutes {
            authoringRoutes.register(this)
            authoringGraphRoutes.register(this)
            authoringGraphSearchRoutes.register(this)
            compiledContentRoutes.register(this)
            compiledResourceStatusRoutes.register(this)
            editorCatalogRoutes.register(this)
            presentationSearchRoutes.register(this)
            capabilityInvocationRoutes?.register(this)
        }
    }
}
