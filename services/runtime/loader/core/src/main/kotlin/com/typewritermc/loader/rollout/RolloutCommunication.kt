package com.typewritermc.loader.rollout

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.rolloutCommand
import com.typewritermc.protocol.transport.generated.rolloutProbe
import com.typewritermc.protocol.transport.generated.rolloutStatus
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.client.ScatterPolicy
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.toList
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProbeRealmHostsRequest
import skirout.service.v1.rollout.ProbeRealmHostsResponse
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.QueryParticipantStatusResponse
import skirout.service.v1.rollout.RealmHostPresence
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * Implements rollout probes and commands through the generated rollout scatter contracts of one Realm.
 *
 * Each scatter collects on its own reply inbox and the subject names the Realm, so replies need no probe or Realm
 * identity. The coordinator supplies expected hosts and timeouts, then validates replies against its attempt and
 * projections.
 */
class CommunicatorRolloutMessenger(
    private val scope: RealmRouteScope,
    private val communicator: Communicator,
) : RolloutMessenger {
    override suspend fun discover(
        expected: Set<ServiceId>,
        timeout: Duration,
    ): List<RealmHostPresence> =
        communicator
            .scatter(
                scope.rolloutProbe,
                scope,
                ProbeRealmHostsRequest.partial(),
                ScatterPolicy(
                    timeout = timeout,
                    quietPeriod = if (expected.isEmpty()) 500.milliseconds else null,
                    completeWhen = { replies ->
                        expected.isNotEmpty() && replies.presences().map { ServiceId(it.serviceId) }.containsAll(expected)
                    },
                ),
            ).successfulValues()
            .presences()

    /** Stops collecting as soon as every listed participant replied; unlisted hosts never reply. */
    override suspend fun command(
        request: ApplyRolloutCommandRequest,
        timeout: Duration,
    ): List<ApplyRolloutCommandResponse> {
        val participants = request.command.serviceIds
        return communicator
            .scatter(
                scope.rolloutCommand,
                scope,
                request,
                ScatterPolicy(timeout) { replies -> replies.mapNotNull { it.serviceId }.containsAll(participants) },
            ).successfulValues()
    }

    override suspend fun statuses(
        request: QueryParticipantStatusRequest,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): Map<ServiceId, ParticipantStatus> =
        communicator
            .scatter(
                scope.rolloutStatus,
                scope,
                request,
                ScatterPolicy(timeout) { replies -> replies.statuses().map { ServiceId(it.serviceId) }.containsAll(expected) },
            ).successfulValues()
            .statuses()
            .associateBy { ServiceId(it.serviceId) }
}

/**
 * Registers presence, command, and status handlers for a local participant.
 *
 * The router owns subscriptions; the participant owns runtime transitions. A command that does not list this host
 * receives no reply. Session replacement requires fresh routes.
 */
class RolloutHostRoutes(
    private val presence: () -> RealmHostPresence,
    private val participant: HostRolloutParticipant,
) {
    fun register(
        builder: CommunicatorRoutesBuilder,
        scope: RealmRouteScope,
    ) {
        builder.scatterAt(scope.rolloutProbe, scope) { ProbeRealmHostsResponse.PresentWrapper(presence()) }
        builder.scatterAt(scope.rolloutCommand, scope) { call -> participant.apply(call.request) }
        builder.scatterAt(scope.rolloutStatus, scope) { call ->
            QueryParticipantStatusResponse.StatusWrapper(participant.status(call.request.attempt))
        }
    }
}

private suspend fun <Value : Any> Flow<CommunicationResult<Value>>.successfulValues(): List<Value> =
    filterIsInstance<CommunicationResult.Success<Value>>()
        .map { it.value }
        .toList()

private fun Iterable<ProbeRealmHostsResponse>.presences(): List<RealmHostPresence> =
    filterIsInstance<ProbeRealmHostsResponse.PresentWrapper>().map { it.value }

private fun Iterable<QueryParticipantStatusResponse>.statuses(): List<ParticipantStatus> =
    filterIsInstance<QueryParticipantStatusResponse.StatusWrapper>().map { it.value }
