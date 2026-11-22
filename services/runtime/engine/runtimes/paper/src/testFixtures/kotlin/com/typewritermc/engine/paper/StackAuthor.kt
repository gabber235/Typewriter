package com.typewritermc.engine.paper

import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.protocol.transport.RealmActorRouteScope
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.protocol.transport.generated.authoringPublicationQuery
import com.typewritermc.protocol.transport.generated.authoringPublish
import com.typewritermc.realm.testing.RealmWire
import com.typewritermc.realm.testing.RemoteSetupEditor
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.setup.Setup
import com.typewritermc.testkit.setup.SetupApplier
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.compiled_content.QueryPublishedContentRequest
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import skirout.editor.v1.publication.PublicationStatus
import skirout.editor.v1.publication.PublicationView
import skirout.editor.v1.publication.PublicationViewId
import skirout.editor.v1.publication.PublishAuthoringRequest
import skirout.editor.v1.publication.QueryPublicationViewRequest
import skirout.editor.v1.publication.QueryPublicationViewResponse
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeUse
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.TimeSource

/**
 * Writes content into the stack's Realm and publishes it, as the stack owner does from the panel, with the author
 * credentials `cargo xtask e2e game` hands the test JVM: `STACK_AUTHOR_CREDS`, `STACK_AUTHOR_INBOX` (the prefix its
 * replies arrive below), `STACK_AUTHOR_USER` (the owner's subject token), `STACK_ORGANIZATION` and `STACK_REALM`. It
 * also opens panel tabs of the owner, which emit events as the panel does ([panelTab]). Setups are planned in this JVM by the Realm's own
 * planner over the state the Realm reports, with the artifacts the Realm loads (see [stackRealmArtifacts]), so [SetupApplier] works against the running stack:
 * `SetupApplier(author.editor).apply(setup(...) { ... })`.
 */
class StackAuthor private constructor(
    private val stack: StackConnection,
    private val scope: RealmRouteScope,
    private val user: String,
    artifacts: List<GeneratedProviderArtifact>,
) : AutoCloseable,
    RealmWire {
    /** Edits the stack's Realm over its authoring routes. */
    val editor = RemoteSetupEditor(this, artifacts)

    /** Edits run one at a time: the editor keeps one activated catalog, which a change of generation replaces. */
    private val editing = Mutex()

    /** Saves [setup] in the stack's Realm as one author edit, and publishes it. */
    suspend fun write(setup: Setup<*>) = published { SetupApplier(editor).apply(setup) }

    /** Deletes what [setup] created from the stack's Realm as one author edit, without publishing. */
    suspend fun discard(setup: Setup<*>) = editing.withLock { SetupApplier(editor).remove(setup) }

    /** Deletes what [setup] created from the stack's Realm as one author edit, and publishes the removal. */
    suspend fun remove(setup: Setup<*>) = published { SetupApplier(editor).remove(setup) }

    /** Changes what [from] created into [to] as one author edit, and publishes the change. */
    suspend fun change(
        from: Setup<*>,
        to: Setup<*>,
    ) = published { SetupApplier(editor).change(from, to) }

    /** Encodes [value] as the Realm's installed catalog types it as [type], as a panel encodes what it sends. */
    suspend fun encode(
        type: TypeUse,
        value: Any?,
    ): DataValue = editing.withLock { editor.encoder().encode(type, value) }

    /** Runs [block] with a panel tab of the owner open on the stack's Realm; the tab leaves when [block] ends. */
    suspend fun <T> panelTab(block: suspend StackPanelTab.() -> T): T =
        coroutineScope {
            val tab = StackPanelTab(stack, RealmActorRouteScope(scope.organizationId, scope.realmId, user))
            val beating = tab.beat(this)
            try {
                tab.block()
            } finally {
                beating.cancel()
                withContext(NonCancellable) { tab.leave() }
            }
        }

    /**
     * Runs [edit], then publishes until the Realm's selected publication carries every saved change: the review reads
     * current, on a publication other than the one selected before the edit. Several authors share the Realm's one
     * publication gate, so another author's publication may carry this edit first: the Realm's review decides, never
     * this author's publish reply.
     */
    private suspend fun published(edit: suspend () -> Unit) {
        val before = selectedPublication()
        editing.withLock { edit() }
        publishUntil("is still $before or does not carry the edit") { status ->
            status is PublicationStatus.CurrentWrapper && status.value.selected.value != before
        }
    }

    /**
     * The id of the Realm's selected publication, or null before its first.
     *
     * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
     */
    suspend fun selectedPublication(): String? = publishedContent()?.publication?.value

    private suspend fun publishedContent(): PublishedContent? =
        when (val content = call(RealmRouteScope::authoringCompiledQuery, QueryPublishedContentRequest.partial())) {
            is QueryPublishedContentResponse.ContentWrapper -> content.value
            is QueryPublishedContentResponse.AbsentWrapper -> null
            else -> error("the Realm answered its published content query with $content")
        }

    /**
     * Releases the Realm's ready candidate whenever there is one, until [done] holds for the review; fails with the Realm's
     * reason when its review is blocked or unavailable, and after [PUBLISH_LIMIT] naming what the selected publication
     * [still] does and the last review it read. A review that is still moving counts as not settled yet: it asks again
     * after [POLL].
     */
    private suspend fun publishUntil(
        still: String,
        done: (PublicationStatus) -> Boolean,
    ) {
        val started = TimeSource.Monotonic.markNow()
        var last: PublicationView? = null
        while (started.elapsedNow() < PUBLISH_LIMIT) {
            // TODO(node 9): while the Realm re-checks after an edit, its publication review gets a new id on every query,
            // so the author follows a moving review and waits for it here. Remove this retry once the Realm can say its
            // review is settled, or once the test author waits on the engine's reported active publication, whichever
            // comes first.
            val view = view()
            if (view == null) {
                delay(POLL)
                continue
            }
            last = view
            if (done(view.status)) return
            when (val status = view.status) {
                is PublicationStatus.ReadyWrapper -> {
                    call(RealmRouteScope::authoringPublish, PublishAuthoringRequest(candidate = status.value.candidate))
                }

                is PublicationStatus.BlockedWrapper -> {
                    error("the Realm blocks the publication: ${status.value.blockers}")
                }

                is PublicationStatus.UnavailableWrapper -> {
                    error("the Realm cannot publish: ${status.value.failure}")
                }

                else -> {
                    delay(POLL)
                }
            }
        }
        error("after $PUBLISH_LIMIT the selected publication $still; the review reads ${last?.status}")
    }

    /**
     * The Realm's current publication review, or null while it moves: a query names the view it expects, the Realm answers
     * another with its id, and a review that changed on each of [VIEW_QUERIES] queries is still moving.
     */
    private suspend fun view(): PublicationView? {
        var expected = PublicationViewId(value = "")
        repeat(VIEW_QUERIES) {
            when (val queried = call(RealmRouteScope::authoringPublicationQuery, QueryPublicationViewRequest(expected = expected))) {
                is QueryPublicationViewResponse.ViewWrapper -> return queried.value
                is QueryPublicationViewResponse.ViewChangedErrorWrapper -> expected = queried.value.current
                else -> error("the Realm answered its publication view query with $queried")
            }
        }
        return null
    }

    override suspend fun <Request : Any, Response : Any> call(
        contract: RealmRouteScope.() -> UnaryContract<RealmRouteScope, Request, Response>,
        request: Request,
    ): Response =
        when (val result = stack.communicator.request(scope.contract(), scope, request)) {
            is CommunicationResult.Success -> result.value
            is CommunicationResult.Failure -> error("the author's request to the stack Realm failed: ${result.error}")
        }

    override fun close() {
        editor.close()
        stack.close()
    }

    companion object {
        private val opening = Mutex()

        @Volatile
        private var shared: StackAuthor? = null

        /** The test JVM's one author, connected on first use and kept until the JVM ends. */
        suspend fun shared(): StackAuthor = shared ?: opening.withLock { shared ?: fromEnvironment().also { shared = it } }

        /** Connects to the stack the environment names. */
        suspend fun fromEnvironment(): StackAuthor =
            StackAuthor(
                StackConnection.open("author", "STACK_AUTHOR_CREDS", "STACK_AUTHOR_INBOX"),
                RealmRouteScope(organizationId = stackValue("STACK_ORGANIZATION"), realmId = stackValue("STACK_REALM")),
                stackValue("STACK_AUTHOR_USER"),
                stackRealmArtifacts(),
            )

        /** How long publishing may take before it fails, the Realm checking and compiling meanwhile. */
        private val PUBLISH_LIMIT: Duration = 2.minutes

        /** How long publishing waits before it reads the review again. */
        private val POLL: Duration = 250.milliseconds

        /** How often a view query follows the review while it keeps changing. */
        private const val VIEW_QUERIES = 3
    }
}
