package com.typewritermc.discovery

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

@OptIn(ExperimentalSerializationApi::class)
object TypeDiscoveryContributionCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(contribution: TypeDiscoveryContribution): ByteArray = cbor.encodeToByteArray(contribution)

    fun decode(payload: ByteArray): TypeDiscoveryContribution = cbor.decodeFromByteArray(payload)
}
