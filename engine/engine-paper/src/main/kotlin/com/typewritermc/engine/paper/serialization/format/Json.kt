package com.typewritermc.engine.paper.serialization.format

import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.plus

fun createJsonFormat(modules: List<SerializersModule>) = Json {
    modules.fold(serializersModule) { acc, module -> acc + module }
    ignoreUnknownKeys = false
    encodeDefaults = true
    prettyPrint = false

    // Maybe change
    explicitNulls = true
    isLenient = true
    classDiscriminator = "data_type"

    coerceInputValues = true
    allowStructuredMapKeys = false
    allowSpecialFloatingPointValues = false
    useArrayPolymorphism = false
}