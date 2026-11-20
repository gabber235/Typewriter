package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.shape.Shape

/**
 * The geometric description of a region. It holds the four placement variables and builds
 * the local frame shape via [buildShape]. The runtime resolves the placement per viewer
 * into a [ResolvedTransform] and tests membership by inverse transforming player positions.
 *
 * Every placement field is a [Var]. Static regions use `ConstVar` and dynamic regions use
 * any `VariableEntry`. The shape itself is plain data and is constructed once per tracker.
 * [buildShape] is a function rather than a property because entries may not hold state, so
 * concrete entries build the shape from their primitive constructor fields.
 *
 * When [rotateWithOrigin] is set, the origin position's own yaw and pitch are added to the
 * [yaw] and [pitch] fields. A region anchored to an entity's position variable then turns
 * with the entity's facing, which is how a vision cone follows a guard.
 *
 * [refreshRateTicks] is not a [Var] because changing it at runtime would break the
 * scheduler's ordering. To slow a region down conditionally, gate the handlers with a
 * `Var<Boolean>` instead.
 */
interface RegionDefinition {
    val origin: Var<Position>
    val offset: Var<Vector>
    val yaw: Var<Float>
    val pitch: Var<Float>
    val roll: Var<Float>
    val rotateWithOrigin: Boolean
    val refreshRateTicks: Int
    val color: Color
    fun buildShape(): Shape
}

/**
 * The color this region is drawn with in editor outlines, previews and debug visuals.
 * A fully transparent [RegionDefinition.color] means the user left it on automatic, and a
 * stable palette color is picked from [seed] (the entry id), so every region keeps its own
 * recognizable hue without any configuration.
 */
fun RegionDefinition.displayColor(seed: String): Color {
    if (color.alpha != 0) return color
    val index = ((seed.hashCode() % DISPLAY_PALETTE.size) + DISPLAY_PALETTE.size) % DISPLAY_PALETTE.size
    return DISPLAY_PALETTE[index]
}

private val DISPLAY_PALETTE = listOf(
    Color(0xFFE74C3C.toInt()),
    Color(0xFFE67E22.toInt()),
    Color(0xFFF1C40F.toInt()),
    Color(0xFF2ECC71.toInt()),
    Color(0xFF1ABC9C.toInt()),
    Color(0xFF3498DB.toInt()),
    Color(0xFF9B59B6.toInt()),
    Color(0xFFE91E63.toInt()),
    Color(0xFFA3E635.toInt()),
    Color(0xFF22D3EE.toInt()),
    Color(0xFFF97316.toInt()),
    Color(0xFF818CF8.toInt()),
)

/**
 * The shape this definition describes, or `null` when its fields do not describe a valid
 * one.
 *
 * Shapes validate their own dimensions and throw, and the panel's `@Min` and `@Max` are
 * hints that the stored json does not have to respect. Building a shape straight out of an
 * `Initializable` therefore let one out of range number abort the whole load loop, which
 * took every region flag and every region event on the server down with it. Callers that
 * build from stored data ask here and skip the definition instead.
 */
fun RegionDefinition.buildShapeOrNull(): Shape? = runCatching { buildShape() }.getOrNull()

/**
 * Names this definition at the start of a console line.
 *
 * An inline definition belongs to no entry of its own, so it is named by where it stands. A
 * builder reading the console can walk there; an entry id could not be found anywhere in game.
 */
fun RegionDefinition.describeInLog(): String {
    if (this is RegionDefinitionEntry) return "Region '$name'"
    val origin = origin.get(null) ?: return "An inline region"
    return "The inline region at ${origin.blockX}, ${origin.blockY}, ${origin.blockZ}"
}

/**
 * `true` when every placement variable is a `ConstVar`, meaning the region resolves to the
 * same world placement for every player and can be tracked once, shared by all subscribers.
 */
val RegionDefinition.hasConstPlacement: Boolean
    get() = origin is ConstVar && offset is ConstVar && yaw is ConstVar && pitch is ConstVar && roll is ConstVar
