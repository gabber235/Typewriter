@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.loader.rollout

import com.typewritermc.loader.deployment.HostId
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.client.ScatterPolicy
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.ScatterContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.telemetry.ErrorSlug
import kotlinx.coroutines.flow.filterIsInstance
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.toList
import kotlinx.serialization.KSerializer
import kotlinx.serialization.cbor.Cbor
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

data class RealmBroadcastAddress(
    val organizationId: String,
    val realmId: RealmId,
)

private val presenceAddress = realmBroadcastAddress("probe")
private val commandAddress = realmBroadcastAddress("command")
private val participantStateAddress = realmBroadcastAddress("state")
private val participantStatusAddress = realmBroadcastAddress("status")

private val presencePolicy =
    ResponsePolicy<PresenceReply>(PresenceReply.Failed("Internal host presence failure")) { response ->
        when (response) {
            is PresenceReply.Present -> success("present")
            is PresenceReply.Failed -> internal("failed")
        }
    }

private val commandPolicy =
    ResponsePolicy(CommandAcceptance(HostId("unknown"), false, "Internal rollout command failure", true)) { response ->
        when {
            response.internalFailure -> internal("failed")
            response.accepted -> success("accepted")
            else -> domain("rejected")
        }
    }

val ProbeRealmHostsContract =
    ScatterContract(
        OperationName.of("realm.hosts.probe"),
        presenceAddress,
        cborCodec(ProbeRealmHosts.serializer()),
        cborCodec(PresenceReply.serializer()),
        presencePolicy,
        ErrorSlug.of("realm-host-probe-failed"),
    )

val RolloutCommandContract =
    ScatterContract(
        OperationName.of("realm.rollout.command"),
        commandAddress,
        cborCodec(RolloutEnvelope.serializer()),
        cborCodec(CommandAcceptance.serializer()),
        commandPolicy,
        ErrorSlug.of("realm-rollout-command-failed"),
    )

val ParticipantStateChangedContract =
    EventContract(
        OperationName.of("realm.rollout.state"),
        participantStateAddress,
        cborCodec(ParticipantStateChanged.serializer()),
        ErrorSlug.of("realm-rollout-state-failed"),
    )

val ParticipantStatusContract =
    ScatterContract(
        OperationName.of("realm.hosts.status"),
        participantStatusAddress,
        cborCodec(ProbeParticipantStatus.serializer()),
        cborCodec(ParticipantStatusReply.serializer()),
        ResponsePolicy(
            ParticipantStatusReply(
                HostId("unknown"),
                ParticipantStatus.Idle(
                    RolloutAttempt(
                        1,
                        com.typewritermc.loader.deployment
                            .DeploymentGeneration(1),
                    ),
                    HostId("unknown"),
                ),
            ),
        ) { success("status") },
        ErrorSlug.of("realm-host-status-failed"),
    )

class CommunicatorRolloutMessenger(
    private val organizationId: String,
    private val communicator: Communicator,
) : RolloutMessenger {
    override suspend fun discover(
        probe: ProbeRealmHosts,
        expected: Set<HostId>,
        timeout: Duration,
    ): List<RealmHostPresence> =
        communicator
            .scatter(
                ProbeRealmHostsContract,
                RealmBroadcastAddress(organizationId, probe.realmId),
                probe,
                ScatterPolicy(
                    timeout = timeout,
                    quietPeriod = if (expected.isEmpty()) 500.milliseconds else null,
                    completeWhen = { replies ->
                        expected.isNotEmpty() &&
                            replies
                                .filterIsInstance<PresenceReply.Present>()
                                .map { it.presence.hostId }
                                .containsAll(expected)
                    },
                ),
            ).successfulValues()
            .filterIsInstance<PresenceReply.Present>()
            .map { it.presence }

    override suspend fun command(
        envelope: RolloutEnvelope,
        timeout: Duration,
    ): List<CommandAcceptance> =
        communicator
            .scatter(
                RolloutCommandContract,
                RealmBroadcastAddress(organizationId, envelope.realmId),
                envelope,
                ScatterPolicy(timeout) { replies ->
                    replies.map(CommandAcceptance::hostId).containsAll(envelope.participants)
                },
            ).successfulValues()

    override suspend fun statuses(
        probe: ProbeParticipantStatus,
        expected: Set<HostId>,
        timeout: Duration,
    ): Map<HostId, ParticipantStatus> =
        communicator
            .scatter(
                ParticipantStatusContract,
                RealmBroadcastAddress(organizationId, probe.realmId),
                probe,
                ScatterPolicy(timeout) { replies -> replies.map(ParticipantStatusReply::hostId).containsAll(expected) },
            ).successfulValues()
            .associate { it.hostId to it.status }
}

class RolloutHostRoutes(
    private val presence: suspend (ProbeRealmHosts) -> RealmHostPresence?,
    private val participant: HostRolloutParticipant,
) {
    fun register(builder: CommunicatorRoutesBuilder) {
        builder.scatter(ProbeRealmHostsContract) { call ->
            presence(call.request)?.let(PresenceReply::Present)
        }
        builder.scatter(RolloutCommandContract) { call ->
            if (participant.accepts(call.request)) participant.handle(call.request) else null
        }
        builder.scatter(ParticipantStatusContract) { call ->
            if (call.request.realmId == participant.realmId) {
                ParticipantStatusReply(participant.hostId, participant.currentStatus(call.request.attempt))
            } else {
                null
            }
        }
    }
}

class RolloutCoordinatorRoutes(
    private val state: RolloutStateRepository,
) {
    fun register(builder: CommunicatorRoutesBuilder) {
        builder.event(ParticipantStateChangedContract) { call ->
            state.record(call.event)
        }
    }
}

class CommunicatorParticipantStatePublisher(
    private val organizationId: String,
    private val communicator: Communicator,
) : ParticipantStatePublisher {
    override suspend fun publish(event: ParticipantStateChanged) {
        val result =
            communicator.publish(
                ParticipantStateChangedContract,
                RealmBroadcastAddress(organizationId, event.realmId),
                event,
            )
        if (result is CommunicationResult.Failure) error("Participant state publication failed: ${result.error}")
    }
}

private suspend fun <Value : Any> kotlinx.coroutines.flow.Flow<CommunicationResult<Value>>.successfulValues(): List<Value> =
    filterIsInstance<CommunicationResult.Success<Value>>()
        .map { it.value }
        .toList()

private fun realmBroadcastAddress(suffix: String): AddressTemplate<RealmBroadcastAddress> =
    addressTemplate(
        "typewriter.organization.{organization}.realm.{realm}.hosts.$suffix",
        { address ->
            addressValuesOf(
                "organization" to address.organizationId,
                "realm" to address.realmId.value,
            )
        },
        { values ->
            RealmBroadcastAddress(
                values.require("organization"),
                RealmId(values.require("realm")),
            )
        },
    )

private fun <Value : Any> cborCodec(serializer: KSerializer<Value>): PayloadCodec<Value> =
    object : PayloadCodec<Value> {
        override fun encode(value: Value): Payload = Payload.copyOf(rolloutCbor.encodeToByteArray(serializer, value))

        override fun decode(payload: Payload): Value = rolloutCbor.decodeFromByteArray(serializer, payload.toByteArray())
    }

private fun success(variant: String) = ResponseClassification(ResponseOutcome.SUCCESS, ResponseVariant.of(variant))

private fun domain(variant: String) = ResponseClassification(ResponseOutcome.DOMAIN_ERROR, ResponseVariant.of(variant))

private fun internal(variant: String) = ResponseClassification(ResponseOutcome.INTERNAL_ERROR, ResponseVariant.of(variant))
