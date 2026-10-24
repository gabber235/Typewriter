package com.typewritermc.protocol.skir

import build.skir.Serializer
import build.skir.UnrecognizedValuesPolicy
import okio.ByteString
import okio.ByteString.Companion.encodeUtf8
import okio.ByteString.Companion.toByteString

/**
 * Binary container nesting admitted for decoded values.
 *
 * One authored value level costs four binary levels, so this admits the 512 authored levels that the authored value
 * codec supports plus room for the surrounding message envelope.
 */
private const val MAX_BINARY_NESTING_DEPTH = 2112

/** JSON container nesting admitted for decoded values, covering 512 authored levels plus the message envelope. */
private const val MAX_JSON_NESTING_DEPTH = 576

private val binaryPrefix = "skir".encodeUtf8()

/**
 * Decodes Skir binary or JSON text input with a bounded container nesting depth.
 *
 * Use this for every value received from outside the current process. Input nested beyond the supported depth fails
 * with [IllegalArgumentException] before recursive decoding starts, so hostile input cannot exhaust the thread stack.
 */
fun <Value> Serializer<Value>.fromBoundedBytes(
    bytes: ByteString,
    unrecognizedValues: UnrecognizedValuesPolicy = UnrecognizedValuesPolicy.DROP,
): Value {
    val maxNestingDepth = if (bytes.startsWith(binaryPrefix)) MAX_BINARY_NESTING_DEPTH else MAX_JSON_NESTING_DEPTH
    return fromBytes(bytes, unrecognizedValues, maxNestingDepth)
}

/** Decodes [bytes] like the [ByteString] overload of [fromBoundedBytes]. */
fun <Value> Serializer<Value>.fromBoundedBytes(
    bytes: ByteArray,
    unrecognizedValues: UnrecognizedValuesPolicy = UnrecognizedValuesPolicy.DROP,
): Value = fromBoundedBytes(bytes.toByteString(), unrecognizedValues)
