package com.typewritermc.library

import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.TypewriterString
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json

interface PageKind

@JvmInline
@Serializable
value class PageKindId(
    val value: DeclaredTypeId,
)

@Serializable
data class PageKindRef(
    val id: PageKindId,
    val revision: Int,
) {
    init {
        require(revision > 0) { "Page kind revisions must be positive." }
    }
}

@JvmInline
@Serializable
value class PageId(
    val key: RecordIdKey,
) {
    constructor(value: String) : this(RecordIdKey.String(value))
}

@Serializable(with = PageRefSerializer::class)
@TypewriterString
data class PageRef<K : PageKind>(
    val id: PageId,
)

object PageRefSerializer : KSerializer<PageRef<*>> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("PageRef", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: PageRef<*>,
    ) {
        encoder.encodeString(value.id.key.referenceString())
    }

    override fun deserialize(decoder: Decoder): PageRef<*> = PageRef<PageKind>(PageId(decoder.decodeString().recordIdKey()))
}

private fun RecordIdKey.referenceString(): String =
    when (this) {
        is RecordIdKey.String -> if (value.startsWith(COMPOSITE_PREFIX)) "$COMPOSITE_PREFIX$value" else value
        else -> COMPOSITE_PREFIX + Json.encodeToString(RecordIdKey.serializer(), this)
    }

private fun String.recordIdKey(): RecordIdKey =
    when {
        startsWith(ESCAPED_COMPOSITE_PREFIX) -> {
            RecordIdKey.String(removePrefix(COMPOSITE_PREFIX))
        }

        startsWith(COMPOSITE_PREFIX) -> {
            Json.decodeFromString(RecordIdKey.serializer(), removePrefix(COMPOSITE_PREFIX))
        }

        else -> {
            RecordIdKey.String(this)
        }
    }

private const val COMPOSITE_PREFIX = "~"
private const val ESCAPED_COMPOSITE_PREFIX = "~~"
