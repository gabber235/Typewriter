package com.typewritermc.roadnetwork.pathfinding

import com.extollit.gaming.ai.path.model.Gravitation
import com.extollit.gaming.ai.path.model.IPathingEntity
import com.extollit.gaming.ai.path.model.Passibility
import com.extollit.linalg.immutable.Vec3d
import com.typewritermc.core.utils.point.Point

class PFEmptyEntity(
    private val position: Point<*>,
    private val width: Float = 0.6f,
    private val height: Float = 1.8f,
    val searchRange: Float,
    private val capabilities: PFCapabilities = PFCapabilities(),
) : IPathingEntity {
    override fun coordinates(): Vec3d = Vec3d(position.x, position.y, position.z)
    override fun width(): Float = width
    override fun height(): Float = height
    override fun age(): Int = 0
    override fun bound(): Boolean = true
    override fun searchRange(): Float = searchRange
    override fun capabilities(): IPathingEntity.Capabilities = capabilities

    override fun moveTo(position: Vec3d?, passibility: Passibility?, gravitation: Gravitation?) {
    }
}

class PFCapabilities(
    val speed: Float = 0.2085f,
    val fireResistant: Boolean = false,
    val cautious: Boolean = true,
    val climber: Boolean = true,
    val swimmer: Boolean = false,
    val aquatic: Boolean = false,
    val avian: Boolean = false,
    val aquaphobic: Boolean = false,
    val avoidsDoorways: Boolean = false,
    val opensDoors: Boolean = false,
): IPathingEntity.Capabilities {
    override fun speed(): Float = speed
    override fun fireResistant(): Boolean = fireResistant
    override fun cautious(): Boolean = cautious
    override fun climber(): Boolean = climber
    override fun swimmer(): Boolean = swimmer
    override fun aquatic(): Boolean = aquatic
    override fun avian(): Boolean = avian
    override fun aquaphobic(): Boolean = aquaphobic
    override fun avoidsDoorways(): Boolean = avoidsDoorways
    override fun opensDoors(): Boolean = opensDoors
}