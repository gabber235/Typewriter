package com.typewritermc.authoring

import kotlinx.serialization.Serializable

@JvmInline @Serializable
value class BatchId(
    val value: String,
)

@JvmInline @Serializable
value class InitializationRequestId(
    val value: String,
)

@JvmInline @Serializable
value class NativeBindingId(
    val value: String,
)

@JvmInline @Serializable
value class CheckExecutionId(
    val value: String,
)

@JvmInline @Serializable
value class DiagnosticId(
    val value: String,
)

@JvmInline @Serializable
value class SelectionId(
    val value: String,
)

@JvmInline @Serializable
value class PublicationId(
    val value: String,
)

@JvmInline @Serializable
value class CanonicalValueHash(
    val value: String,
)
