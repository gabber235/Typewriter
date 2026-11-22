package com.typewritermc.imprint

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray

/**
 * Intermediate KSP output of one source part naming the entry types its handlers run. The manifest task folds each
 * part's file into that part's [ExtensionSourcePart.handledEntries]; the JAR never carries it.
 */
const val IMPRINT_HANDLED_ENTRIES_PATH = "META-INF/typewriter/handled-entries.cbor"

/** Code generation result for one source part, consumed by the Imprint manifest task. */
@Serializable
data class HandledEntriesMetadata(
    val entries: List<EntryTypeId>,
)

@OptIn(ExperimentalSerializationApi::class)
object HandledEntriesMetadataCodec {
    private val cbor = Cbor { encodeDefaults = true }

    fun encode(metadata: HandledEntriesMetadata): ByteArray = cbor.encodeToByteArray(metadata)

    fun decode(bytes: ByteArray): HandledEntriesMetadata = cbor.decodeFromByteArray(bytes)
}
