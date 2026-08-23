package com.typewritermc.elements

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlin.uuid.Uuid

object ElementInstanceIdSerializer : KSerializer<ElementInstanceId> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("ElementInstanceId", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: ElementInstanceId,
    ) {
        encoder.encodeString(value.value.toHexString())
    }

    override fun deserialize(decoder: Decoder): ElementInstanceId = ElementInstanceId(Uuid.parseHex(decoder.decodeString()))
}
