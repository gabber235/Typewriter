@file:OptIn(ExperimentalSerializationApi::class)

package com.typewritermc.types.skir

import build.skir.JsonFlavor
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
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import build.skir.Serializer as SkirSerializer

/**
 * Embeds the readable Skir JSON of a generated value inside a kotlinx serialized structure, so storage models that
 * are still kotlinx classes (authored records, data values, compiled content and stored findings) hold Skir type
 * values in the format they keep once those models are Skir values themselves. Decoding checks the value with the
 * same rules as every other entry point.
 *
 * JSON formats receive the readable JSON object; any other format receives its text.
 */
abstract class SkirJsonSerializer<T : Any>(
    private val skir: SkirSerializer<T>,
    serialName: String,
    private val validate: (T) -> Unit,
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
        runCatching { validate(value) }.getOrElse { throw SerializationException("Stored ${descriptor.serialName} is invalid.", it) }
        return value
    }
}

object TypeUseSerializer : SkirJsonSerializer<TypeUse>(TypeUse.serializer, "skir.TypeUse", { it.requireValid() })

object NamedTypeUseSerializer : SkirJsonSerializer<NamedTypeUse>(NamedTypeUse.serializer, "skir.NamedTypeUse", { it.requireValid() })

object TypeDefinitionIdSerializer :
    SkirJsonSerializer<TypeDefinitionId>(TypeDefinitionId.serializer, "skir.TypeDefinitionId", { it.requireValid() })

object TypeDefinitionSerializer :
    SkirJsonSerializer<TypeDefinition>(TypeDefinition.serializer, "skir.TypeDefinition", { it.requireValid() })

object FieldOwnerSerializer : SkirJsonSerializer<FieldOwner>(FieldOwner.serializer, "skir.FieldOwner", { it.requireValid() })

object EndpointIdSerializer : SkirJsonSerializer<EndpointId>(EndpointId.serializer, "skir.EndpointId", { it.requireValid() })

object RuleOriginSerializer : SkirJsonSerializer<RuleOrigin>(RuleOrigin.serializer, "skir.RuleOrigin", { it.requireValid() })
