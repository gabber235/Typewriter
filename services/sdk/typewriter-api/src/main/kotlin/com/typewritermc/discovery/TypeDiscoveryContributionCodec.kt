package com.typewritermc.discovery

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

/**
 * Encodes the type discovery payload embedded in an Imprint manifest as CBOR with defaults included.
 *
 * Decoding reconstructs [TypeDiscoveryContribution] and enforces its schema invariants. Malformed or unsupported
 * input throws; manifest readers add origin context.
 */
@OptIn(ExperimentalSerializationApi::class)
object TypeDiscoveryContributionCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(contribution: TypeDiscoveryContribution): ByteArray = cbor.encodeToByteArray(contribution)

    fun decode(payload: ByteArray): TypeDiscoveryContribution = cbor.decodeFromByteArray(payload)
}
