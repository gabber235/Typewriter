package com.typewritermc.engine.runtime

fun interface EngineContentGateway {
    suspend fun apply(revision: ContentRevision)
}

data class ContentRevision(
    val revision: Long,
    val payload: ByteArray,
) {
    init {
        require(revision >= 1) { "Content revision must be positive." }
    }

    override fun equals(other: Any?): Boolean =
        other is ContentRevision && revision == other.revision && payload.contentEquals(other.payload)

    override fun hashCode(): Int = 31 * revision.hashCode() + payload.contentHashCode()
}

sealed interface ContentApplicationResult {
    data class Applied(
        val revision: Long,
    ) : ContentApplicationResult

    data class Ignored(
        val currentRevision: Long,
    ) : ContentApplicationResult

    data object Unsupported : ContentApplicationResult
}
