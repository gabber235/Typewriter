package com.typewritermc.types

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlin.io.encoding.Base64

interface TypePrototypeProvider {
    fun prototype(): ConcreteTypePrototype<*>
}

@OptIn(ExperimentalSerializationApi::class)
object GeneratedTypeGraph {
    fun decode(encoded: String): TypeGraph = Cbor.Default.decodeFromByteArray(Base64.decode(encoded))
}
