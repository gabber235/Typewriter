package com.typewritermc.types

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlin.io.encoding.Base64

/**
 * Reflective entry point implemented by generated prototype providers.
 *
 * Discovery loads the provider from manifest metadata and checks that its returned prototype matches the
 * advertised reference.
 */
interface TypePrototypeProvider {
    /** Returns the generated prototype and its embedded structural definition. */
    fun prototype(): TypePrototype<*>
}

/**
 * Decodes the Base64 encoded CBOR graph embedded in generated Kotlin providers.
 *
 * This is a generated metadata boundary; invalid encoding or schema data throws rather than producing a partial
 * graph.
 */
@OptIn(ExperimentalSerializationApi::class)
object GeneratedTypeGraph {
    /** Decodes one generated graph from its Base64 encoded CBOR representation. */
    fun decode(encoded: String): TypeGraph = Cbor.Default.decodeFromByteArray(Base64.decode(encoded))
}
