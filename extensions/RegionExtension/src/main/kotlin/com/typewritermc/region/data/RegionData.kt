package com.typewritermc.region.data

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.ContentEditor
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.extension.annotations.WithAlpha
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.content.InlineRegionContentMode
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.SphereShape

/**
 * How a consumer entry points at a region. A [RegionReferenceData] references a named
 * [RegionDefinitionEntry]. A [RegionDefinitionData] inlines the definition in the entry
 * itself.
 *
 * Use a reference when several entries share one region. Use an inline definition for a
 * region that only one entry uses.
 */
sealed interface RegionData {
    /**
     * Resolves the underlying [RegionDefinition]. Returns `null` only for a reference that
     * points at a missing entry id.
     */
    fun resolveDefinition(): RegionDefinition?
}

@AlgebraicTypeInfo("region_inline", Colors.PURPLE, "mdi:cube-outline")
data class RegionDefinitionData(
    @Help("World position the region is anchored to. The editor captures it from where you stand.")
    @ContentEditor(InlineRegionContentMode::class)
    override val origin: Var<Position> = RegionDefaults.ORIGIN,
    @Help(RegionDefaults.OFFSET_HELP)
    override val offset: Var<Vector> = RegionDefaults.OFFSET,
    @Help(RegionDefaults.YAW_HELP)
    override val yaw: Var<Float> = RegionDefaults.YAW,
    @Help(RegionDefaults.PITCH_HELP)
    override val pitch: Var<Float> = RegionDefaults.PITCH,
    @Help(RegionDefaults.ROLL_HELP)
    override val roll: Var<Float> = RegionDefaults.ROLL,
    @Help(RegionDefaults.ROTATE_WITH_ORIGIN_HELP)
    override val rotateWithOrigin: Boolean = RegionDefaults.ROTATE_WITH_ORIGIN,
    @Help("The region's shape and its size fields.")
    @Default("""{"case":"sphere_shape","value":{"radius":1.0}}""")
    val shape: Shape = SphereShape(1.0),
    @Min(1)
    @Help(RegionDefaults.REFRESH_RATE_HELP)
    @Default("1")
    override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
    @Help(RegionDefaults.COLOR_HELP)
    @WithAlpha
    @Default(RegionDefaults.COLOR_DEFAULT)
    override val color: Color = RegionDefaults.COLOR,
) : RegionData, RegionDefinition {
    override fun buildShape(): Shape = shape
    override fun resolveDefinition(): RegionDefinition = this
}

@AlgebraicTypeInfo("region_reference", Colors.PURPLE, "mdi:link-variant")
data class RegionReferenceData(
    val definition: Ref<RegionDefinitionEntry> = emptyRef(),
) : RegionData {
    override fun resolveDefinition(): RegionDefinition? = definition.get()
}
