package com.typewritermc.loader.rollout

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.realmTemplate
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ScatterContract
import com.typewritermc.services.libs.telemetry.ErrorSlug

private val realmHostsProbeRequestAddress = "service.from.{realm}.organization.{organization}.realm.rollout.probe".realmTemplate()
fun RealmRouteScope.realmHostsProbe(policy: ResponsePolicy<PresenceReply>): ScatterContract<RealmRouteScope, ProbeRealmHosts, PresenceReply> = ScatterContract(
    name = OperationName.of("realm.hosts.probe"),
    requestAddress = realmHostsProbeRequestAddress.subscribedAt(this),
    requestCodec = com.typewritermc.loader.rollout.RolloutCodecs.probeRequest,
    responseCodec = com.typewritermc.loader.rollout.RolloutCodecs.presenceReply,
    responsePolicy = policy,
    failureSlug = ErrorSlug.of("realm-hosts-probe-failed"),
)

private val realmRolloutCommandRequestAddress = "service.from.{realm}.organization.{organization}.realm.rollout.command".realmTemplate()
fun RealmRouteScope.realmRolloutCommand(policy: ResponsePolicy<CommandAcceptance>): ScatterContract<RealmRouteScope, RolloutEnvelope, CommandAcceptance> = ScatterContract(
    name = OperationName.of("realm.rollout.command"),
    requestAddress = realmRolloutCommandRequestAddress.subscribedAt(this),
    requestCodec = com.typewritermc.loader.rollout.RolloutCodecs.commandRequest,
    responseCodec = com.typewritermc.loader.rollout.RolloutCodecs.commandResponse,
    responsePolicy = policy,
    failureSlug = ErrorSlug.of("realm-rollout-command-failed"),
)

private val realmHostsStatusRequestAddress = "service.from.{realm}.organization.{organization}.realm.rollout.status".realmTemplate()
fun RealmRouteScope.realmHostsStatus(policy: ResponsePolicy<ParticipantStatusReply>): ScatterContract<RealmRouteScope, ProbeParticipantStatus, ParticipantStatusReply> = ScatterContract(
    name = OperationName.of("realm.hosts.status"),
    requestAddress = realmHostsStatusRequestAddress.subscribedAt(this),
    requestCodec = com.typewritermc.loader.rollout.RolloutCodecs.statusRequest,
    responseCodec = com.typewritermc.loader.rollout.RolloutCodecs.statusReply,
    responsePolicy = policy,
    failureSlug = ErrorSlug.of("realm-hosts-status-failed"),
)

private val realmRolloutStateAddress = "service.to.{realm}.organization.{organization}.realm.rollout.state".realmTemplate()
val RealmRouteScope.realmRolloutState: EventContract<RealmRouteScope, ParticipantStateChanged>
    get() = EventContract(
        name = OperationName.of("realm.rollout.state"),
        address = realmRolloutStateAddress,
        codec = com.typewritermc.loader.rollout.RolloutCodecs.participantState,
        failureSlug = ErrorSlug.of("realm-rollout-state-failed"),
    )
