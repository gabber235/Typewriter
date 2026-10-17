package com.typewritermc.authoring

import com.typewritermc.types.EndpointId
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

@Serializable
data class LinkOccurrenceId(
    val endpoint: EndpointId,
    val location: ValueLocation,
)

@Serializable
data class LinkOccurrence(
    val id: LinkOccurrenceId,
    val source: ResourceId,
    val target: LinkTarget,
)

@Serializable
data class LinkProjection(
    val contract: RelationId,
    val first: ResourceId,
    val second: ResourceId,
    val firstLocation: ValuePath?,
    val secondLocation: ValuePath?,
)

@Serializable
data class RelationProjectionDelta(
    val removed: List<LinkProjection>,
    val created: List<LinkProjection>,
    val metadataChanged: List<LinkProjection>,
)
