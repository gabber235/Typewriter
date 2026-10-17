package com.typewritermc.loader.rollout

import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.client.ScatterPolicy
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.toList
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

internal val presenceResponsePolicy =
    ResponsePolicy<PresenceReply>(PresenceReply.Failed("Internal host presence failure")) { response ->
        when (response) {
            is PresenceReply.Present -> success("present")
            is PresenceReply.Failed -> internal("failed")
        }
    }

internal val commandResponsePolicy =
    ResponsePolicy(CommandAcceptance(ServiceId("unknown"), false, "Internal rollout command failure", true)) { response ->
        when {
            response.internalFailure -> internal("failed")
            response.accepted -> success("accepted")
            else -> domain("rejected")
        }
    }

internal val participantStatusResponsePolicy =
    ResponsePolicy<ParticipantStatusReply>(
        ParticipantStatusReply.InternalFailure(
            ServiceId("unknown"),
            "Internal participant status failure",
        ),
    ) { response ->
        when (response) {
            is ParticipantStatusReply.Status -> success("status")
            is ParticipantStatusReply.InternalFailure -> internal("failed")
        }
    }

/**
 * Implements rollout probes and commands through typed messaging contracts.
 *
 * The coordinator supplies expected hosts and timeouts, then validates replies against its attempt and
 * projections.
 */
class CommunicatorRolloutMessenger(
    private val organizationId: String,
    private val communicator: Communicator,
) : RolloutMessenger {
    override suspend fun discover(
        probe: ProbeRealmHosts,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): List<RealmHostPresence> {
        val scope = routeScope(probe.realmId)
        return communicator
            .scatter(
                scope.realmHostsProbe(presenceResponsePolicy),
                scope,
                probe,
                ScatterPolicy(
                    timeout = timeout,
                    quietPeriod = if (expected.isEmpty()) 500.milliseconds else null,
                    completeWhen = { replies ->
                        expected.isNotEmpty() &&
                            replies
                                .filterIsInstance<PresenceReply.Present>()
                                .map { it.presence.serviceId }
                                .containsAll(expected)
                    },
                ),
            ).successfulValues()
            .filterIsInstance<PresenceReply.Present>()
            .map { it.presence }
    }

    override suspend fun command(
        envelope: RolloutEnvelope,
        timeout: Duration,
    ): List<CommandAcceptance> {
        val scope = routeScope(envelope.realmId)
        return communicator
            .scatter(
                scope.realmRolloutCommand(commandResponsePolicy),
                scope,
                envelope,
                ScatterPolicy(timeout) { replies ->
                    replies.map(CommandAcceptance::serviceId).containsAll(envelope.participants)
                },
            ).successfulValues()
    }

    override suspend fun statuses(
        probe: ProbeParticipantStatus,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): Map<ServiceId, ParticipantStatus> {
        val scope = routeScope(probe.realmId)
        return communicator
            .scatter(
                scope.realmHostsStatus(participantStatusResponsePolicy),
                scope,
                probe,
                ScatterPolicy(timeout) { replies -> replies.map(ParticipantStatusReply::serviceId).containsAll(expected) },
            ).successfulValues()
            .associate { it.serviceId to it.requireStatus() }
    }

    private fun routeScope(realmId: RealmId) =
        RealmRouteScope(
            organizationId = organizationId,
            realmId = realmId.value,
        )
}

/**
 * Registers presence, command, and status handlers for a local participant.
 *
 * The router owns subscriptions; the participant owns runtime transitions. Session replacement requires fresh
 * routes.
 */
class RolloutHostRoutes(
    private val presence: suspend (ProbeRealmHosts) -> RealmHostPresence?,
    private val participant: HostRolloutParticipant,
) {
    fun register(
        builder: CommunicatorRoutesBuilder,
        scope: RealmRouteScope,
    ) {
        builder.scatterAt(scope.realmHostsProbe(presenceResponsePolicy), scope) { call ->
            presence(call.request)?.let(PresenceReply::Present)
        }
        builder.scatterAt(scope.realmRolloutCommand(commandResponsePolicy), scope) { call ->
            if (participant.accepts(call.request)) participant.handle(call.request) else null
        }
        builder.scatterAt(scope.realmHostsStatus(participantStatusResponsePolicy), scope) { call ->
            if (call.request.realmId == participant.realmId) {
                ParticipantStatusReply.Status(participant.serviceId, participant.currentStatus(call.request.attempt))
            } else {
                null
            }
        }
    }
}

/**
 * Registers participant event ingestion into coordinator persistence.
 *
 * Events supplement status probes and do not independently commit a deployment.
 */
class RolloutCoordinatorRoutes(
    private val state: RolloutStateRepository,
) {
    fun register(
        builder: CommunicatorRoutesBuilder,
        scope: RealmRouteScope,
    ) {
        builder.eventAt(scope.realmRolloutState, scope) { call ->
            state.record(call.event)
        }
    }
}

/**
 * Publishes participant state through the rollout event contract.
 *
 * Communication failure propagates; publication is not transactional with local runtime transitions.
 */
class CommunicatorParticipantStatePublisher(
    private val organizationId: String,
    private val communicator: Communicator,
) : ParticipantStatePublisher {
    override suspend fun publish(event: ParticipantStateChanged) {
        val scope =
            RealmRouteScope(
                organizationId = organizationId,
                realmId = event.realmId.value,
            )
        val result =
            communicator.publish(
                scope.realmRolloutState,
                scope,
                event,
            )
        if (result is CommunicationResult.Failure) error("Participant state publication failed: ${result.error}")
    }
}

private suspend fun <Value : Any> kotlinx.coroutines.flow.Flow<CommunicationResult<Value>>.successfulValues(): List<Value> =
    filterIsInstance<CommunicationResult.Success<Value>>()
        .map { it.value }
        .toList()

private fun ParticipantStatusReply.requireStatus(): ParticipantStatus =
    when (this) {
        is ParticipantStatusReply.Status -> status
        is ParticipantStatusReply.InternalFailure -> error("Internal failure reached successful participant statuses: $reason")
    }

private fun success(variant: String) = ResponseClassification(ResponseOutcome.SUCCESS, ResponseVariant.of(variant))

private fun domain(variant: String) = ResponseClassification(ResponseOutcome.DOMAIN_ERROR, ResponseVariant.of(variant))

private fun internal(variant: String) = ResponseClassification(ResponseOutcome.INTERNAL_ERROR, ResponseVariant.of(variant))
