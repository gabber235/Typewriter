package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ValuePath

/*
 * Authored references are the generated Skir LinkOccurrence, identified by a LinkOccurrenceId: an endpoint and the exact
 * value location, including collection item identity, that holds the link. The projections below describe the graph
 * edges derived from those occurrences; they stay Kotlin values while the edit expectations that hold them are.
 */

data class LinkProjection(
    val contract: RelationId,
    val first: ResourceId,
    val second: ResourceId,
    val firstLocation: ValuePath?,
    val secondLocation: ValuePath?,
)

data class RelationProjectionDelta(
    val removed: List<LinkProjection>,
    val created: List<LinkProjection>,
    val metadataChanged: List<LinkProjection>,
)
