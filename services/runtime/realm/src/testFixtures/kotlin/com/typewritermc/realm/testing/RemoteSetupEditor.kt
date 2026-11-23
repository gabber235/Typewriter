package com.typewritermc.realm.testing

import com.typewritermc.authoring.SubmissionKey
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.protocol.transport.generated.authoringStateQuery
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.edit.AuthoringPlanRejected
import com.typewritermc.realm.edit.WorkingViewEditContext
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.testkit.CatalogEncoder
import com.typewritermc.testkit.setup.EditRefused
import com.typewritermc.testkit.setup.SetupEdit
import com.typewritermc.testkit.setup.SetupEditor
import com.typewritermc.types.immutableMapCopy
import skirout.editor.v1.authoring.AuthoringState
import skirout.editor.v1.authoring.CommitPreparedEditRequest
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.type_catalog.CatalogGeneration

/** Calls the routes of a running Realm as an organization member does. */
interface RealmWire {
    /** Sends [request] to the route of [contract] and returns its reply; fails when the request gets none. */
    suspend fun <Request : Any, Response : Any> call(
        contract: RealmRouteScope.() -> UnaryContract<RealmRouteScope, Request, Response>,
        request: Request,
    ): Response
}

/**
 * Edits a running Realm the way the in process editor edits a fixture: each edit runs the Realm's own planner over the
 * authored state the Realm reports over [wire], with the catalog of [artifacts] activated as the Realm's installed
 * generation, and the prepared edit goes back through the commit route. [artifacts] are those the running Realm loads,
 * so the planner knows exactly the types the Realm checks an edit against.
 */
class RemoteSetupEditor(
    private val wire: RealmWire,
    artifacts: List<GeneratedProviderArtifact>,
) : SetupEditor,
    AutoCloseable {
    private val catalog = RealmCatalog(realm = artifacts)
    private var active: ActiveCatalog? = null

    override suspend fun <T> edit(
        name: String,
        block: suspend SetupEdit.() -> T,
    ): T {
        val state = currentState()
        val view =
            AuthoringView(
                activated(state.generation).lease,
                state.resources.associate { it.id to it.content }.immutableMapCopy(),
                ResourceValueMapper
                    .discover(state.resources.associate { it.id to it.content })
                    .associateBy { it.id }
                    .immutableMapCopy(),
                state.confirmedObservation.value,
            )
        return try {
            WorkingViewSetupEdit(WorkingViewEditContext(view, name), view).block()
        } catch (rejected: AuthoringPlanRejected) {
            throw EditRefused(rejected.problems)
        }
    }

    override suspend fun commit(
        edit: PreparedEdit,
        submission: SubmissionKey,
    ): CommitPreparedEditResponse =
        wire.call(
            RealmRouteScope::authoringEditCommit,
            CommitPreparedEditRequest(edit = edit, submission = submission.value),
        )

    /**
     * Encodes native values as the Realm's installed catalog types them, as a panel encodes what it sends: the catalog of
     * the generation the Realm reports now.
     */
    suspend fun encoder(): CatalogEncoder = activated(currentState().generation).lease.let { CatalogEncoder(it.checked, it.nativeBindings) }

    override fun close() {
        active?.close()
        active = null
    }

    /**
     * The Realm's saved authoring state under its installed catalog. A query names the generation it expects, and the
     * Realm answers a query for another one with its own, so the first query asks for none.
     */
    private suspend fun currentState(): AuthoringState {
        var generation = CatalogGeneration(value = "")
        repeat(STATE_QUERIES) {
            when (val queried = wire.call(RealmRouteScope::authoringStateQuery, QueryAuthoringStateRequest(generation = generation))) {
                is QueryAuthoringStateResponse.StateWrapper -> return queried.value
                is QueryAuthoringStateResponse.CatalogChangedErrorWrapper -> generation = queried.value.actualGeneration
                else -> error("the Realm answered its authoring state query with $queried")
            }
        }
        error("the Realm changed its catalog on each of $STATE_QUERIES authoring state queries")
    }

    /** The local catalog activated as [generation], kept while the Realm stays on it. */
    private fun activated(generation: CatalogGeneration): ActiveCatalog =
        active?.takeIf { it.lease.generation == generation }
            ?: catalog.activate(generation.value).also {
                close()
                active = it
            }
}

/** How often an edit asks for the authoring state while the Realm keeps changing its catalog. */
private const val STATE_QUERIES = 3

private fun ActiveCatalog.close() {
    owner?.close()
    lease.close()
}
