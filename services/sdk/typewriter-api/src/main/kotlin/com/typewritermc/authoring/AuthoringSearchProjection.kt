package com.typewritermc.authoring

import com.typewritermc.types.ResourceId

@JvmInline
value class SearchSelectorId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Search selector ids must not be blank." }
    }
}

data class AuthoringSearchDocument(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val text: String,
    val selectors: Map<SearchSelectorId, Set<String>> = emptyMap(),
    val ownerPath: List<ResourceId> = emptyList(),
) {
    init {
        require(text.isNotBlank()) { "Search documents must contain searchable text." }
    }
}

fun interface AuthoringSearchProjection {
    fun project(subject: AuthoringPresentationSubject): AuthoringSearchDocument
}
