package lirand.api.extensions.math

import org.bukkit.Chunk
import org.bukkit.Location
import org.bukkit.World
import org.bukkit.block.Block
import kotlin.math.sqrt

fun Location.asPosition() = LocationPosition(x, y, z, yaw, pitch)


fun Block.asPosition() = BlockPosition(x, y, z)
fun Location.asBlockPosition() = BlockPosition(blockX, blockY, blockZ)

fun BlockPosition.asBlock(world: World) = world.getBlockAt(x, y, z)
fun BlockPosition.asLocation(world: World? = null) = Location(world, x.toDouble(), y.toDouble(), z.toDouble())

fun Chunk.asPosition() = ChunkPosition(x, z)
fun ChunkPosition.asBukkitChunk(world: World) = world.getChunkAt(x, z)

data class BlockPosition(
    var x: Int,
    var y: Int,
    var z: Int
) : Position<BlockPosition> {
    override fun axis(): DoubleArray = doubleArrayOf(x.toDouble(), y.toDouble(), z.toDouble())
    override fun factor(axis: IntArray) = BlockPosition(axis[0], axis[1], axis[2])
}

data class LocationPosition(
    var x: Double,
    var y: Double,
    var z: Double,
    val yaw: Float = 0f,
    val pitch: Float = 0f
) : Position<LocationPosition> {
    override fun axis(): DoubleArray = doubleArrayOf(x, y, z)
    override fun factor(axis: IntArray) =
        LocationPosition(axis[0].toDouble(), axis[1].toDouble(), axis[2].toDouble(), yaw, pitch)
}

data class ChunkPosition(
    var x: Int,
    var z: Int
) : Position<ChunkPosition> {
    override fun axis(): DoubleArray = doubleArrayOf(x.toDouble(), z.toDouble())
    override fun factor(axis: IntArray) = ChunkPosition(axis[0], axis[1])
}

interface Position<T : Position<T>> : Comparable<T> {
    fun axis(): DoubleArray
    fun factor(axis: IntArray): T


    override fun compareTo(other: T): Int {
        val selfAxis = axis()
        val otherAxis = other.axis()
        val pairAxis = selfAxis.mapIndexed { index, axis -> axis to otherAxis[index] }
        val (d1, d2) = calculatePythagoras(*pairAxis.toTypedArray())
        return d1.compareTo(d2)
    }

    private fun calculatePythagoras(vararg positions: Pair<Double, Double>): Pair<Double, Double> {
        val pow = positions.map { (x1, x2) -> (x1 * x1) to (x2 * x2) }

        val x1Sum = pow.sumOf { (x, _) -> x }
        val x2Sum = pow.sumOf { (_, x) -> x }

        val d1 = sqrt(x1Sum)
        val d2 = sqrt(x2Sum)

        return d1 to d2
    }
}

operator fun <T : Position<T>> T.rangeTo(other: T): PosRange<T, T> {
    return PosRange(this, other) { PosRangeIterator(this, other, ::factor) }
}
