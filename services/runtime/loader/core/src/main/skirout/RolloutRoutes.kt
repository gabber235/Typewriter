package com.typewritermc.loader.rollout

import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ScatterContract
import com.typewritermc.services.libs.telemetry.ErrorSlug

private fun String.loaderRealmTemplate() = addressTemplate(
    render = { it: RealmRouteScope -> addressValuesOf("organization" to it.organizationId, "realm" to it.realmId) },
    parse = { RealmRouteScope(it.require("organization"), it.require("realm")) },
)

private val realmHostsProbeRequestAddress = "typewriter.organization.{organization}.realm.{realm}.hosts.probe".loaderRealmTemplate()
fun RealmRouteScope.realmHostsProbe(policy: ResponsePolicy<PresenceReply>): ScatterContract<RealmRouteScope, ProbeRealmHosts, PresenceReply> = ScatterContract(
    name = OperationName.of("realm.hosts.probe"),
    requestAddress = realmHostsProbeRequestAddress.subscribedAt(this),
    requestCodec = com.typewritermc.loader.rollout.RolloutCodecs.probeRequest,
    responseCodec = com.typewritermc.loader.rollout.RolloutCodecs.presenceReply,
    responsePolicy = policy,
    failureSlug = ErrorSlug.of("realm-host-probe-failed"),
)

private val realmRolloutCommandRequestAddress = "typewriter.organization.{organization}.realm.{realm}.hosts.command".loaderRealmTemplate()
fun RealmRouteScope.realmRolloutCommand(policy: ResponsePolicy<CommandAcceptance>): ScatterContract<RealmRouteScope, RolloutEnvelope, CommandAcceptance> = ScatterContract(
    name = OperationName.of("realm.rollout.command"),
    requestAddress = realmRolloutCommandRequestAddress.subscribedAt(this),
    requestCodec = com.typewritermc.loader.rollout.RolloutCodecs.commandRequest,
    responseCodec = com.typewritermc.loader.rollout.RolloutCodecs.commandResponse,
    responsePolicy = policy,
    failureSlug = ErrorSlug.of("realm-rollout-command-failed"),
)

private val realmHostsStatusRequestAddress = "typewriter.organization.{organization}.realm.{realm}.hosts.status".loaderRealmTemplate()
fun RealmRouteScope.realmHostsStatus(policy: ResponsePolicy<ParticipantStatusReply>): ScatterContract<RealmRouteScope, ProbeParticipantStatus, ParticipantStatusReply> = ScatterContract(
    name = OperationName.of("realm.hosts.status"),
    requestAddress = realmHostsStatusRequestAddress.subscribedAt(this),
    requestCodec = com.typewritermc.loader.rollout.RolloutCodecs.statusRequest,
    responseCodec = com.typewritermc.loader.rollout.RolloutCodecs.statusReply,
    responsePolicy = policy,
    failureSlug = ErrorSlug.of("realm-host-status-failed"),
)

private val realmRolloutStateAddress = "typewriter.organization.{organization}.realm.{realm}.hosts.state".loaderRealmTemplate()
val RealmRouteScope.realmRolloutState: EventContract<RealmRouteScope, ParticipantStateChanged>
    get() = EventContract(
        name = OperationName.of("realm.rollout.state"),
        address = realmRolloutStateAddress,
        codec = com.typewritermc.loader.rollout.RolloutCodecs.participantState,
        failureSlug = ErrorSlug.of("realm-rollout-state-failed"),
    )
