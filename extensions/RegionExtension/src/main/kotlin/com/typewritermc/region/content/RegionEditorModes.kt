package com.typewritermc.region.content

import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.definition.*
import com.typewritermc.region.shape.*
import org.bukkit.entity.Player

/** The content context the shape editors expect: the definition entry and its origin field. */
fun regionEditorContext(definition: RegionDefinitionEntry): ContentContext =
    ContentContext(mapOf("entryId" to definition.id, "fieldPath" to "origin"))

/**
 * The content context for editing an inline definition living in [field] on [entryId].
 * The path carries the `value` hop the panel serializes algebraic types with, byte equal
 * to the path the panel's own content editor button sends.
 */
fun inlineRegionEditorContext(entryId: String, field: String): ContentContext =
    ContentContext(mapOf("entryId" to entryId, "fieldPath" to "$field.value.origin"))

/**
 * The shape specific editor for [definition], or `null` for a definition type without an
 * in game editor. Shared by the edit command and the workspace mode.
 */
fun regionEditorMode(
    definition: RegionDefinitionEntry,
    context: ContentContext,
    player: Player,
): RegionContentMode? = when (definition) {
    is CuboidRegionDefinitionEntry -> CuboidRegionContentMode(context, player)
    is SphereRegionDefinitionEntry -> SphereRegionContentMode(context, player)
    is EllipsoidRegionDefinitionEntry -> EllipsoidRegionContentMode(context, player)
    is CapsuleRegionDefinitionEntry -> CapsuleRegionContentMode(context, player)
    is ConeRegionDefinitionEntry -> ConeRegionContentMode(context, player)
    is PolygonRegionDefinitionEntry -> PolygonRegionContentMode(context, player)
    else -> null
}

/**
 * The editor for an inline definition, whose shape lives in its data instead of its type.
 * A definition entry picks its editor from the entry type it was written as; an inline one
 * can only be picked from the shape the user selected, so it is resolved at edit time.
 */
fun regionEditorMode(
    shape: Shape,
    context: ContentContext,
    player: Player,
): RegionContentMode? = when (shape) {
    is CuboidShape -> CuboidRegionContentMode(context, player)
    is SphereShape -> SphereRegionContentMode(context, player)
    is EllipsoidShape -> EllipsoidRegionContentMode(context, player)
    is CapsuleShape -> CapsuleRegionContentMode(context, player)
    is ConeShape -> ConeRegionContentMode(context, player)
    is PolygonShape -> PolygonRegionContentMode(context, player)
    else -> null
}
