package com.typewritermc.roadnetwork.pathfinding

import com.extollit.gaming.ai.path.model.ColumnarOcclusionFieldList
import com.extollit.gaming.ai.path.model.IColumnarSpace
import com.extollit.gaming.ai.path.model.IInstanceSpace
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import org.bukkit.ChunkSnapshot

class PFColumnarSpace(
    private val world: World,
    private val snapshot: ChunkSnapshot,
    private val instance: IInstanceSpace,
) : IColumnarSpace {
    private val occlusionFieldList = ColumnarOcclusionFieldList(this)
    private var lastAccess = System.currentTimeMillis()

    override fun blockAt(x: Int, y: Int, z: Int): PFBlock {
        lastAccess = System.currentTimeMillis()
        return PFBlock(
            Position(world, x.toDouble(), y.toDouble(), z.toDouble(), 0f, 0f),
            snapshot.getBlockType(x, y, z),
            snapshot.getBlockData(x, y, z),
        )
    }

    fun refresh(): Boolean {
        return System.currentTimeMillis() - lastAccess < 1000*60
    }

    override fun metaDataAt(x: Int, y: Int, z: Int): Int = 0
    override fun occlusionFields(): ColumnarOcclusionFieldList = occlusionFieldList
    override fun instance(): IInstanceSpace = instance
}