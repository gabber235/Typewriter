@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import java.math.BigInteger
import kotlin.uuid.Uuid

/**
 * Serializes arbitrary precision integers as decimal strings to avoid numeric width loss.
 *
 * Malformed decimal input fails during conversion to BigInteger.
 */
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

/**
 * Uses the compact hexadecimal UUID form for persistent type identities.
 *
 * Invalid input becomes a serialization exception retaining the parsing cause.
 */
object DeclaredTypeIdSerializer : KSerializer<DeclaredTypeId> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("DeclaredTypeId", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: DeclaredTypeId,
    ) {
        encoder.encodeString(value.value.toHexString())
    }

    override fun deserialize(decoder: Decoder): DeclaredTypeId =
        DeclaredTypeId(
            runCatching { Uuid.parseHex(decoder.decodeString()) }
                .getOrElse { throw SerializationException("Declared type id must be a 32 character hexadecimal UUID.", it) },
        )
}

/**
 * Preserves absent numeric constraints as null and present values as arbitrary precision decimal strings.
 *
 * Used by structural integer bounds so serialization never narrows them to a machine integer.
 */
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
