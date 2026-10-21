@file:OptIn(ExperimentalSerializationApi::class)

package com.typewritermc.types.skir

import build.skir.JsonFlavor
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.ValuePath
import build.skir.Serializer as SkirSerializer

/**
 * Embeds the readable Skir JSON of a generated value inside a kotlinx serialized structure, so the kotlinx models that
 * remain (the facts of compiled resource graph shards and author facing references) hold Skir type, data and path
 * values in their readable Skir form. Decoding checks the value with the same rules as every other entry point and
 * keeps the checked form it returns.
 *
 * JSON formats receive the readable JSON object; any other format receives its text.
 */
abstract class SkirJsonSerializer<T : Any>(
    private val skir: SkirSerializer<T>,
    serialName: String,
    private val validate: (T) -> T,
) : KSerializer<T> {
    override val descriptor: SerialDescriptor = SerialDescriptor(serialName, JsonElement.serializer().descriptor)

    override fun serialize(
        encoder: Encoder,
        value: T,
    ) {
        val json = skir.toJson(value, JsonFlavor.READABLE)
        if (encoder is JsonEncoder) encoder.encodeJsonElement(json) else encoder.encodeString(json.toString())
    }

    override fun deserialize(decoder: Decoder): T {
        val json = if (decoder is JsonDecoder) decoder.decodeJsonElement() else Json.parseToJsonElement(decoder.decodeString())
        val value =
            runCatching { skir.fromJson(json) }
                .getOrElse { throw SerializationException("Stored ${descriptor.serialName} is not valid Skir JSON.", it) }
        return runCatching { validate(value) }.getOrElse { throw SerializationException("Stored ${descriptor.serialName} is invalid.", it) }
    }
}

object NamedTypeUseSerializer : SkirJsonSerializer<NamedTypeUse>(NamedTypeUse.serializer, "skir.NamedTypeUse", { it.requireValid() })

object TypeDefinitionSerializer :
    SkirJsonSerializer<TypeDefinition>(TypeDefinition.serializer, "skir.TypeDefinition", { it.requireValid() })

object DataValueSerializer : SkirJsonSerializer<DataValue>(DataValue.serializer, "skir.DataValue", { it.requirePortable() })

object RelationIdSerializer : SkirJsonSerializer<RelationId>(RelationId.serializer, "skir.RelationId", { it.requireValid() })

object NativeBindingIdSerializer : SkirJsonSerializer<NativeBindingId>(NativeBindingId.serializer, "skir.NativeBindingId", { it })

object ValuePathSerializer : SkirJsonSerializer<ValuePath>(ValuePath.serializer, "skir.ValuePath", { it.requireValid() })

/** Stores a named data value, the form compiled resources keep, as the readable Skir JSON of its data value. */
object NamedDataValueSerializer : KSerializer<DataValue.NamedWrapper> {
    override val descriptor: SerialDescriptor = SerialDescriptor("skir.DataValue.named", DataValueSerializer.descriptor)

    override fun serialize(
        encoder: Encoder,
        value: DataValue.NamedWrapper,
    ) = DataValueSerializer.serialize(encoder, value)

    override fun deserialize(decoder: Decoder): DataValue.NamedWrapper =
        DataValueSerializer.deserialize(decoder) as? DataValue.NamedWrapper
            ?: throw SerializationException("Stored skir.DataValue.named is not a named value.")
}
