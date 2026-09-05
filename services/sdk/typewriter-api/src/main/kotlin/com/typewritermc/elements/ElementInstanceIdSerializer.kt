package com.typewritermc.elements

import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

object ElementInstanceIdSerializer : KSerializer<ElementInstanceId> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("ElementInstanceId", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: ElementInstanceId,
    ) {
        encoder.encodeString(value.value)
    }

    override fun deserialize(decoder: Decoder): ElementInstanceId = ElementInstanceId(decoder.decodeString())
}
