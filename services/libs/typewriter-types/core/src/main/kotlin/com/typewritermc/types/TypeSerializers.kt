@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.math.BigInteger

object BigIntegerAsStringSerializer : KSerializer<BigInteger> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("BigInteger", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: BigInteger,
    ) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): BigInteger = decoder.decodeString().toBigInteger()
}

object NullableBigIntegerAsStringSerializer : KSerializer<BigInteger?> {
    override val descriptor: SerialDescriptor =
        BigIntegerAsStringSerializer.nullable.descriptor

    override fun serialize(
        encoder: Encoder,
        value: BigInteger?,
    ) {
        if (value == null) {
            encoder.encodeNull()
        } else {
            encoder.encodeString(value.toString())
        }
    }

    override fun deserialize(decoder: Decoder): BigInteger? =
        if (decoder.decodeNotNullMark()) decoder.decodeString().toBigInteger() else decoder.decodeNull()
}

internal fun String.requireCanonicalDecimal(label: String) {
    require(CANONICAL_DECIMAL.matches(this)) { "$label must use canonical decimal syntax." }
}

private val CANONICAL_DECIMAL = Regex("-?(0|[1-9][0-9]*)(\\.[0-9]+)?")
