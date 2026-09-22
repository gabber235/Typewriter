package com.typewritermc.authoring

import com.typewritermc.types.ResourceId

/** Stable open identifier for an indexed search selector. */
@JvmInline
value class SearchSelectorId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Search selector ids must not be blank." }
    }
}

/** One indexed search document produced by a Realm policy. */
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

/** Projects one resource and its declared graph dependencies into indexed search state. */
interface AuthoringSearchProjection {
    val resourceDefinition: ResourceDefinitionId
    val graphRequirement: GraphReadRequirement

    fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringWorkingGraph,
    ): AuthoringSearchDocument

    fun affectedResources(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId> = change.changedResources
}
