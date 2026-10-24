package com.typewritermc.engine

import build.skir.JsonFlavor
import build.skir.UnrecognizedValuesPolicy
import com.typewritermc.types.MAX_VALUE_DEPTH
import com.typewritermc.types.canonicalText
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import skirout.editor.v1.compiled_content.CompiledEdge
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.ResourceGraphShard
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.DataValue
import java.security.MessageDigest

/**
 * JSON container nesting admitted for a shard: readable Skir JSON spends four levels on each authored value level, so
 * this admits every portable value plus the shard envelope.
 */
private const val MAX_SHARD_JSON_DEPTH = 4 * MAX_VALUE_DEPTH + 64

/** The compact readable Skir JSON of a shard part, which shard payloads and semantic digests are built from. */
private fun <Value> build.skir.Serializer<Value>.canonicalText(value: Value): String = toJson(value, JsonFlavor.READABLE).toString()

/**
 * Normalizes the order of graph facts before semantic hashing and shard encoding.
 *
 * Type and relation declarations must be unique. Edges are deduplicated, while duplicate resource keys
 * remain for runtime admission to reject.
 */
fun RuntimeCompilationFacts.canonicalized(): RuntimeCompilationFacts {
    require(types.size == types.map { type -> type.id }.toSet().size) {
        "Runtime facts contain duplicate type declarations."
    }
    require(relations.size == relations.map { relation -> relation.relation }.toSet().size) {
        "Runtime facts contain duplicate relation declarations."
    }
    return copy(
        resources = resources.sortedBy { resource -> CompiledResourceKey.serializer.canonicalText(resource.key) },
        edges = edges.distinct().sortedBy(CompiledEdge.serializer::canonicalText),
        types = types.sortedBy { type -> type.id.canonicalText },
        relations = relations.sortedBy { relation -> relation.relation.value },
    )
}

fun RuntimeCompilationFacts.canonicalBytes(): ByteArray =
    RuntimeCompilationFacts.serializer.canonicalText(canonicalized()).encodeToByteArray()

fun RuntimeCompilationFacts.semanticDigest(): ContentDigest =
    ContentDigest(
        MessageDigest
            .getInstance("SHA-256")
            .digest(canonicalBytes())
            .toHexString(),
    )

fun RuntimeCompilationFacts.encodeShard(): ByteArray {
    val canonical = canonicalized()
    val shard = ResourceGraphShard(digest = canonical.semanticDigest().value, facts = canonical)
    return ResourceGraphShard.serializer.canonicalText(shard).encodeToByteArray()
}

/** Decodes a shard and checks its facts and semantic digest; execution catalog admission happens in the engine consumer. */
fun ByteArray.decodeResourceGraphShard(): ResourceGraphShard {
    val decoded = ResourceGraphShard.serializer.fromJsonCode(decodeToString(), UnrecognizedValuesPolicy.DROP, MAX_SHARD_JSON_DEPTH)
    val shard = decoded.copy(facts = decoded.facts.requireValid())
    require(shard.semanticDigest == shard.facts.semanticDigest()) {
        "Runtime facts disagree with their semantic digest."
    }
    return shard
}

/**
 * Checks the identities, types, paths and values of facts read from a shard and returns their canonical form: values
 * in canonical notation, which the semantic digest is computed from.
 */
fun RuntimeCompilationFacts.requireValid(): RuntimeCompilationFacts {
    root.requireValid()
    edges.forEach { edge -> edge.requireValid() }
    types.forEach { type -> type.requireValid() }
    relations.forEach { relation -> relation.relation.requireValid() }
    return copy(resources = resources.map { resource -> resource.requireValid() })
}

private fun CompiledResourceKey.requireValid() {
    source.requireValid()
}

private fun CompiledEdge.requireValid() {
    source.requireValid()
    target.requireValid()
    when (val origin = origin) {
        is CompiledEdgeOrigin.RelationWrapper -> {
            origin.value.relation.requireValid()
            origin.value.firstLocation?.requireValid()
            origin.value.secondLocation?.requireValid()
        }

        else -> {
            throw IllegalArgumentException("Unknown compiled edge origin.")
        }
    }
}

private fun CompiledResource.requireValid(): CompiledResource {
    key.requireValid()
    actualType.requireValid()
    val checked = dataValue.requirePortable() as DataValue.NamedWrapper
    return copy(value = checked.value)
}
