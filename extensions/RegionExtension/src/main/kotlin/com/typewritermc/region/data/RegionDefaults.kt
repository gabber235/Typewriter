package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color

/**
 * Default values for [RegionDefinition] placement fields. Concrete shape entries reference
 * these as constructor defaults so changing a single default propagates everywhere.
 */
object RegionDefaults {
    val ORIGIN: Var<Position> = ConstVar(Position.ORIGIN)
    val OFFSET: Var<Vector> = ConstVar(Vector.ZERO)
    val YAW: Var<Float> = ConstVar(0f)
    val PITCH: Var<Float> = ConstVar(0f)
    val ROLL: Var<Float> = ConstVar(0f)
    const val ROTATE_WITH_ORIGIN: Boolean = false
    const val REFRESH_RATE_TICKS: Int = 1

    /** Fully transparent, meaning automatic: a palette color picked from the entry id. */
    val COLOR: Color = Color(0)

    const val COLOR_HELP: String =
        "Color used for editor outlines, previews and debug visuals of this region. " +
                "Leave fully transparent to pick a stable color automatically."

    const val OFFSET_HELP: String = "Translation from the resolved origin, in the yaw-rotated local frame."

    const val YAW_HELP: String = "Rotation around the vertical axis. Turns the region and the offset with it."

    const val PITCH_HELP: String = "Rotation around the horizontal axis. Turns the region only, not the offset."

    const val ROLL_HELP: String = "Rotation around the facing axis. Lets the region tilt in any vertical plane."

    const val ROTATE_WITH_ORIGIN_HELP: String =
        "Add the origin position's own yaw and pitch to the region's rotation."

    const val REFRESH_RATE_HELP: String =
        "How often a region that follows a variable re-checks where it is. " +
                "Higher values cost less and lag further behind."

    /**
     * The panel picks the first case of an algebraic field unless the field declares a
     * default, and the cases are ordered by name, so every field pointing at a region has to
     * name the reference case or a new entry opens on an inline region of size zero.
     */
    const val REGION_REFERENCE: String = """{"case":"region_reference","value":{"definition":null}}"""

    /** Transparent, which [com.typewritermc.region.data.displayColor] reads as automatic. */
    const val COLOR_DEFAULT: String = "0"
}
