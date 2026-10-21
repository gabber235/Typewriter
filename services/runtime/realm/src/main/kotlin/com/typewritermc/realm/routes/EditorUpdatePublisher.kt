package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringChanged
import com.typewritermc.protocol.transport.generated.authoringPublicationWatch
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.checking.toWire
import com.typewritermc.realm.compiler.RealmPublicationCoordinator
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.checking.FindingSet as SkirFindingSet

/**
 * Publishes editor updates for the current messaging connection: authoring change hints after commits and
 * finding changes, and each publication view of [publication]. Finding changes also invalidate publication.
 *
 * Refresh hints may be coalesced or lost. Clients recover by querying current state. Failed deliveries are
 * reported through telemetry and are not retried until the next signal.
 */
internal class EditorUpdatePublisher(
    private val views: AuthoringViewStore,
    private val publication: RealmPublicationCoordinator,
    findingChanges: Flow<Unit>,
    private val telemetry: ServiceTelemetry,
    scope: CoroutineScope,
) {
    private val connection = MutableStateFlow<Connection?>(null)
    private val wakeups = Channel<Unit>(Channel.CONFLATED)
    private val publicationTask =
        scope.launch {
            connection.collectLatest { current ->
                if (current == null) return@collectLatest
                publication.views.collectLatest { view ->
                    report("realm.editor.publication.publish", PUBLICATION_FAILURE) {
                        current.communicator
                            .publishUpdate(current.address.authoringPublicationWatch, current.address, view.changed())
                            .requirePublished()
                    }
                }
            }
        }
    private val hintTask =
        scope.launch {
            connection.collectLatest { current ->
                if (current == null) return@collectLatest
                for (ignored in wakeups) {
                    report("realm.editor.authoring_changed.publish", AUTHORING_CHANGED_FAILURE) {
                        val generation = views.capture().use { it.root.catalog.generation.value }
                        current.communicator
                            .publish(
                                current.address.authoringChanged,
                                current.address,
                                AuthoringChanged(generation = CatalogGeneration(value = generation)),
                            ).requirePublished()
                    }
                }
            }
        }
    private val findingTask =
        scope.launch(start = CoroutineStart.UNDISPATCHED) {
            findingChanges.collect {
                publication.invalidate()
                committed()
            }
        }

    fun configure(
        address: RealmRouteScope,
        communicator: Communicator,
    ) {
        connection.value = Connection(communicator, address)
        committed()
    }

    fun unconfigure() {
        connection.value = null
    }

    suspend fun close() {
        unconfigure()
        wakeups.close()
        findingTask.cancelAndJoin()
        hintTask.cancelAndJoin()
        publicationTask.cancelAndJoin()
    }

    fun committed() {
        wakeups.trySend(Unit)
    }

    private suspend fun report(
        name: String,
        slug: ErrorSlug,
        block: suspend () -> Unit,
    ) {
        try {
            telemetry.mainSpan(name = name, unhandledFailureSlug = slug) { block() }
        } catch (failure: Exception) {
            failure.rethrowExceptional()
        }
    }

    private data class Connection(
        val communicator: Communicator,
        val address: RealmRouteScope,
    )
}

private val PUBLICATION_FAILURE = ErrorSlug.of("realm-editor-publication-update-failed")
private val AUTHORING_CHANGED_FAILURE = ErrorSlug.of("realm-editor-authoring-changed-failed")

internal data class CapturedFindings(
    val findings: List<SkirFindingSet>,
)

internal fun captureFindings(
    root: AuthoringView,
    findings: List<FindingSet>,
): CapturedFindings =
    CapturedFindings(
        findings.map { set ->
            val current = set.ticket.catalog == root.catalog.generation && root.values.conflicts(set.expectations).isEmpty()
            set.copy(status = if (current) FindingStatus.CURRENT else FindingStatus.OUTDATED).toWire()
        },
    )
