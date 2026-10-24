package com.typewritermc.expression

import com.typewritermc.protocol.skir.fromBoundedBytes
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ByteArraySerializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import skirout.editor.v1.expression.ExpressionNode

/** Keeps generated expression syntax opaque to domain DTO serialization in JSON and CBOR. */
object ExpressionNodeSerializer : KSerializer<ExpressionNode> {
    private val bytes = ByteArraySerializer()
    override val descriptor: SerialDescriptor = bytes.descriptor

    override fun serialize(
        encoder: Encoder,
        value: ExpressionNode,
    ) {
        encoder.encodeSerializableValue(bytes, ExpressionNode.serializer.toBytes(value).toByteArray())
    }

    override fun deserialize(decoder: Decoder): ExpressionNode =
        ExpressionNode.serializer.fromBoundedBytes(decoder.decodeSerializableValue(bytes))
}
