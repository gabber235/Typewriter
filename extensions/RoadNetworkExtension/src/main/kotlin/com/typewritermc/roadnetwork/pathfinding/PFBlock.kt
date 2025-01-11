package com.typewritermc.roadnetwork.pathfinding

import com.extollit.gaming.ai.path.model.IBlockDescription
import com.extollit.gaming.ai.path.model.IBlockObject
import com.extollit.linalg.immutable.AxisAlignedBBox
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.utils.toBukkitLocation
import io.papermc.paper.registry.RegistryAccess
import io.papermc.paper.registry.RegistryKey
import org.bukkit.Material
import org.bukkit.block.data.BlockData
import org.bukkit.util.VoxelShape

private val fenceLikeMaterials =
    RegistryAccess.registryAccess().getRegistry(RegistryKey.BLOCK).filter {
        it.key.key.contains("fence") || it.key.key.contains("wall")
    }.map { it.key }.toSet()

class PFBlock(
    val position: Position,
    val type: Material,
    val data: BlockData,
) : IBlockDescription, IBlockObject {
    private val collisionShape: VoxelShape by lazy(LazyThreadSafetyMode.NONE) {
        data.getCollisionShape(position.toBukkitLocation())
    }

    override fun bounds(): AxisAlignedBBox {
        return collisionShape.toAABB()
    }

    override fun isFenceLike(): Boolean {
        return fenceLikeMaterials.contains(type.key)
    }

    override fun isClimbable(): Boolean {
        return type == Material.LADDER || type.key.key.contains("vine")
    }

    override fun isDoor(): Boolean {
        return type.key.key.endsWith("door")
    }

    override fun isIntractable(): Boolean {
        // TODO: Intractability of blocks
        return false
    }

    override fun isImpeding(): Boolean {
        return type.isSolid
    }

    override fun isFullyBounded(): Boolean {
        if (collisionShape.boundingBoxes.size != 1) return false
        val boundingBox = collisionShape.boundingBoxes.first()

        return boundingBox.minX == 0.0
                && boundingBox.minY == 0.0
                && boundingBox.minZ == 0.0
                && boundingBox.widthX == 1.0
                && boundingBox.height == 1.0
                && boundingBox.widthZ == 1.0
    }

    override fun isLiquid(): Boolean {
        return type == Material.WATER || type == Material.LAVA
    }

    override fun isIncinerating(): Boolean {
        return type == Material.LAVA || type == Material.FIRE || type == Material.SOUL_FIRE || type == Material.MAGMA_BLOCK
    }
}

private fun VoxelShape.toAABB(): AxisAlignedBBox {
    val boundingBoxes = boundingBoxes

    if (boundingBoxes.isEmpty()) return AxisAlignedBBox(0.0, 0.0, 0.0, 0.0, 0.0, 0.0)

    return AxisAlignedBBox(
        boundingBoxes.minOf { it.minX },
        boundingBoxes.minOf { it.minY },
        boundingBoxes.minOf { it.minZ },
        boundingBoxes.maxOf { it.maxX },
        boundingBoxes.maxOf { it.maxY },
        boundingBoxes.maxOf { it.maxZ },
    )
}