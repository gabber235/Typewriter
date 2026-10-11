package com.typewritermc.realm.routes

import com.typewritermc.checking.FindingStatus
import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.checking.CheckTicket
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.checking.toWire
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.services.libs.communicator.client.Communicator
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.type_catalog.CatalogGeneration

/** Refresh hints may be coalesced or lost. Clients recover by querying current state. */
internal class EditorCheckEvents(
    private val views: AuthoringViewStore,
    scope: CoroutineScope,
) {
    private val publisher = MutableStateFlow<Publisher?>(null)
    private val publication = MutableStateFlow<com.typewritermc.realm.compiler.RealmPublicationCoordinator?>(null)
    private val publicationTask = scope.launch {
        combine(publisher, publication) { connection, source -> connection to source }.collectLatest { (connection, source) ->
            if (connection == null || source == null) return@collectLatest
            source.views.collectLatest { view ->
                try {
                    connection.communicator.publishUpdate(connection.contracts.watchPublication, connection.address, view.changed()).requirePublished()
                } catch (cancelled: CancellationException) {
                    throw cancelled
                } catch (_: Exception) { }
            }
        }
    }
    private var findings: () -> List<FindingSet> = { emptyList() }
    private val wakeups = Channel<Unit>(Channel.CONFLATED)
    private val task =
        scope.launch {
            publisher.collectLatest { current ->
                if (current == null) return@collectLatest
                for (ignored in wakeups) {
                    try {
                        val generation = views.capture().use { it.root.catalog.generation.value }
                        current.communicator
                            .publish(
                                current.contracts.authoringChanged,
                                current.address,
                                AuthoringChanged(generation = CatalogGeneration(value = generation)),
                            ).requirePublished()
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (_: Exception) {
                    }
                }
            }
        }

    fun bindPublication(source: com.typewritermc.realm.compiler.RealmPublicationCoordinator) {
        publication.value = source
    }

    fun bindFindings(provider: () -> List<FindingSet>) {
        findings = provider
    }

    fun configure(
        contracts: EditorContracts,
        address: RealmRouteScope,
        communicator: Communicator,
    ) {
        publisher.value = Publisher(communicator, contracts, address)
        committed()
    }

    suspend fun unconfigure() {
        publisher.value = null
    }

    suspend fun close() {
        unconfigure()
        wakeups.close()
        task.cancelAndJoin()
        publicationTask.cancelAndJoin()
        publication.value = null
    }

    suspend fun capture(root: AuthoringView): CapturedFindings = captureFindings(root, findings())

    fun committed() {
        wakeups.trySend(Unit)
    }

    suspend fun publishChanged(ticket: CheckTicket) {
        publication.value?.invalidate()
        committed()
    }

    private data class Publisher(
        val communicator: Communicator,
        val contracts: EditorContracts,
        val address: RealmRouteScope,
    )
}

internal data class CapturedFindings(
    val findings: List<skirout.editor.v1.checking.FindingSet>,
)

internal fun captureFindings(
    root: AuthoringView,
    findings: List<FindingSet>,
): CapturedFindings =
    CapturedFindings(
        findings.map { set ->
            val current = set.ticket.catalog == root.catalog.generation && root.values.conflicts(set.expectations).isEmpty()
            set.copy(status = if (current) FindingStatus.Current else FindingStatus.Outdated).toWire()
        },
    )
