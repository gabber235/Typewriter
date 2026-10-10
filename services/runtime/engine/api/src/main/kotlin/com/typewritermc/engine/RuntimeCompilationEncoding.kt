package com.typewritermc.engine

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.encodeToJsonElement
import java.security.MessageDigest

private val runtimeFactsJson = Json { encodeDefaults = true }

private fun JsonElement.canonicalJson(): JsonElement =
    when (this) {
        is JsonObject -> JsonObject(entries.sortedBy { entry -> entry.key }.associate { (key, value) -> key to value.canonicalJson() })
        is JsonArray -> JsonArray(map(JsonElement::canonicalJson))
        else -> this
    }

private inline fun <reified Value> canonicalText(value: Value): String =
    runtimeFactsJson.encodeToJsonElement(value).canonicalJson().toString()

fun RuntimeCompilationFacts.canonicalized(): RuntimeCompilationFacts {
    require(types.size == types.map { type -> type.id }.toSet().size) {
        "Runtime facts contain duplicate type declarations."
    }
    require(relations.size == relations.map { relation -> relation.relation }.toSet().size) {
        "Runtime facts contain duplicate relation declarations."
    }
    return copy(
        resources = resources.sortedBy { resource -> canonicalText(resource.key) },
        edges = edges.distinct().sortedBy(::canonicalText),
        types = types.sortedBy { type -> canonicalText(type.id) },
        relations = relations.sortedBy { relation -> relation.relation.value },
    )
}

fun RuntimeCompilationFacts.canonicalBytes(): ByteArray = canonicalText(canonicalized()).encodeToByteArray()

fun RuntimeCompilationFacts.semanticDigest(): ContentDigest =
    ContentDigest(
        MessageDigest
            .getInstance("SHA-256")
            .digest(canonicalBytes())
            .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) },
    )

fun RuntimeCompilationFacts.encodeShard(): ByteArray {
    val canonical = canonicalized()
    return canonicalText(CompiledPageShard(canonical.semanticDigest(), canonical)).encodeToByteArray()
}

fun ByteArray.decodeCompiledPageShard(): CompiledPageShard {
    val shard = runtimeFactsJson.decodeFromString<CompiledPageShard>(decodeToString())
    require(shard.digest == shard.facts.semanticDigest()) {
        "Runtime facts disagree with their semantic digest."
    }
    return shard
}
