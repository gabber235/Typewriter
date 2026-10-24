@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.loader.rollout

import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.transport.Payload
import kotlinx.serialization.KSerializer

/** Binds canonical rollout routes to the serialization model shared with rollout persistence. */
internal object RolloutCodecs {
    val probeRequest = ProbeRealmHosts.serializer().rolloutCodec()
    val presenceReply = PresenceReply.serializer().rolloutCodec()
    val commandRequest = RolloutEnvelope.serializer().rolloutCodec()
    val commandResponse = CommandAcceptance.serializer().rolloutCodec()
    val statusRequest = ProbeParticipantStatus.serializer().rolloutCodec()
    val statusReply = ParticipantStatusReply.serializer().rolloutCodec()
    val participantState = ParticipantStateChanged.serializer().rolloutCodec()
}

private fun <Value : Any> KSerializer<Value>.rolloutCodec(): PayloadCodec<Value> =
    object : PayloadCodec<Value> {
        override fun encode(value: Value): Payload = Payload.copyOf(rolloutCbor.encodeToByteArray(this@rolloutCodec, value))

        override fun decode(payload: Payload): Value = rolloutCbor.decodeFromByteArray(this@rolloutCodec, payload.toByteArray())
    }
