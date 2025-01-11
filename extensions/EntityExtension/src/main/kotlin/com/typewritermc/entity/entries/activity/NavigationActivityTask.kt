package com.typewritermc.entity.entries.activity

import com.extollit.gaming.ai.path.HydrazinePathFinder
import com.extollit.gaming.ai.path.model.Gravitation
import com.extollit.gaming.ai.path.model.IPath
import com.extollit.gaming.ai.path.model.IPathingEntity
import com.extollit.gaming.ai.path.model.Passibility
import com.extollit.linalg.immutable.Vec3d
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.gps.GPS
import com.typewritermc.roadnetwork.gps.GPSEdge
import com.typewritermc.roadnetwork.gps.isInRangeOf
import com.typewritermc.roadnetwork.gps.toVector
import com.typewritermc.roadnetwork.pathfinding.PFCapabilities
import com.typewritermc.roadnetwork.pathfinding.PFInstanceSpace
import com.typewritermc.roadnetwork.pathfinding.instanceSpace
import com.typewritermc.roadnetwork.roadNetworkMaxDistance
import kotlinx.coroutines.Job
import org.bukkit.util.BoundingBox
import org.koin.java.KoinJavaComponent.get
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin


class NavigationActivity(
    private val gps: GPS,
    startLocation: PositionProperty,
) : GenericEntityActivity {
    private var path: List<GPSEdge>? = null
    private var state: NavigationActivityTaskState = NavigationActivityTaskState.Searching(gps, startLocation)

    override val currentPosition: PositionProperty
        get() = state.location()

    override fun initialize(context: ActivityContext) {}

    override fun tick(context: ActivityContext): TickResult {
        state.tick(context)
        if (state.isComplete()) {
            if (path?.isEmpty() == true) {
                return TickResult.IGNORED
            }
            path = path?.subList(1, path?.size ?: 0) ?: (state as NavigationActivityTaskState.Searching).let {
                it.path ?: return TickResult.CONSUMED
            }

            val currentEdge = path?.firstOrNull() ?: return TickResult.IGNORED

            state = when {
                currentEdge.isFastTravel -> NavigationActivityTaskState.FastTravel(currentEdge)
                context.isViewed -> NavigationActivityTaskState.Walking(gps.roadNetwork, currentEdge, currentPosition)

                else -> NavigationActivityTaskState.FakeNavigation(currentEdge)
            }
        }

        val state = state
        // The fake navigation is used to improve the performance, it however, goes through buildings
        // So, we switch to walking when the entity is viewed
        if (state is NavigationActivityTaskState.FakeNavigation && context.isViewed) {
            this.state = NavigationActivityTaskState.Walking(gps.roadNetwork, state.edge, currentPosition)
        }

        // And we switch back to fake navigation when the entity is not viewed
        if (state is NavigationActivityTaskState.Walking && !context.isViewed) {
            this.state = NavigationActivityTaskState.FakeNavigation(state.edge, currentPosition)
        }

        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {
        state.dispose()
    }
}


private sealed interface NavigationActivityTaskState {
    fun location(): PositionProperty
    fun isComplete(): Boolean = false
    fun tick(context: ActivityContext) {}
    fun dispose() {}

    class Searching(
        private val gps: GPS,
        private val location: PositionProperty,
    ) : NavigationActivityTaskState {
        internal var path: List<GPSEdge>? = null
        private val job: Job = ThreadType.DISPATCHERS_ASYNC.launch {
            val result = gps.findPath()
            path = if (result.isFailure) {
                logger.severe("Failed to find path: ${result.exceptionOrNull()}")
                emptyList()
            } else {
                result.getOrThrow()
            }
        }

        override fun location(): PositionProperty = location

        override fun isComplete(): Boolean = path != null

        override fun dispose() {
            job.cancel()
            super.dispose()
        }
    }

    class FakeNavigation(
        val edge: GPSEdge,
        val location: PositionProperty = edge.start.toProperty(),
    ) : NavigationActivityTaskState {
        private var ticks: Int = 0

        // Fixme: Magic number
        private val maxTicks = (location.distance(edge.end.toProperty()) * 20).toInt()

        override fun location(): PositionProperty = location

        override fun tick(context: ActivityContext) {
            super.tick(context)
            ticks++
        }

        override fun isComplete(): Boolean = ticks >= maxTicks
    }

    class FastTravel(
        val edge: GPSEdge,
    ) : NavigationActivityTaskState {
        override fun location(): PositionProperty = edge.end.toProperty()
        override fun isComplete(): Boolean = true
    }

    class Walking(
        roadNetwork: Ref<RoadNetworkEntry>,
        val edge: GPSEdge,
        startLocation: PositionProperty
    ) : NavigationActivityTaskState, IPathingEntity {
        private var location: PositionProperty = startLocation
        private var path: IPath?

        private var velocity = Vector.ZERO

        private var yawVelocity = Velocity(0f)
        private var pitchVelocity = Velocity(0f)

        private val navigator: HydrazinePathFinder

        init {
            val instance = startLocation.toBukkitLocation().world.instanceSpace
            navigator = HydrazinePathFinder(this, instance)

            // We want to avoid going through negative nodes
            // Since we just queried the network, it is likely that the network is already loaded.
            get<RoadNetworkManager>(RoadNetworkManager::class.java).getNetworkOrNull(roadNetwork)?.let { network ->
                val interestingNegativeNodes = network.negativeNodes.filter {
                    val distance = edge.start.distanceSqrt(it.location) ?: 0.0
                    distance > it.radius * it.radius && distance < roadNetworkMaxDistance * roadNetworkMaxDistance
                }
                val additionalRadius = navigator.subject().width().toDouble()

                navigator.withGraphNodeFilter { node ->
                    if (node.isInRangeOf(interestingNegativeNodes, additionalRadius)) {
                        return@withGraphNodeFilter Passibility.dangerous
                    }
                    node.passibility()
                }
            }


            path = navigator.computePathTo(edge.end.x, edge.end.y, edge.end.z)
        }

        override fun location(): PositionProperty = location

        override fun tick(context: ActivityContext) {
            path = navigator.updatePathFor(this)
            super.tick(context)
        }

        override fun moveTo(position: Vec3d, passibility: Passibility?, gravitation: Gravitation?) {
            val target =
                PositionProperty(location.world, position.x, position.y, position.z, location.yaw, location.pitch)

            val velocity = calculateVelocity(target, capabilities().speed().toDouble())
            val result = calculateMovement(velocity)
            location = result.newPosition
            this.velocity = result.newVelocity

            val (yaw, pitch) = calculateRotation()
            location = location.copy(yaw = yaw, pitch = pitch)
        }

        fun calculateVelocity(target: PositionProperty, speed: Double): Vector {
            var speed = speed
            val dx: Double = target.x - location.x
            val dy: Double = target.y - location.y
            val dz: Double = target.z - location.z
            val distSquared = dx * dx + dy * dy + dz * dz
            // Limit the speed to make sure not to overshoot the target
            if (speed > distSquared) {
                speed = distSquared
            }
            val radians = atan2(dz, dx)
            val speedX = cos(radians) * speed
            val speedY = dy * speed
            val speedZ = sin(radians) * speed

            val targetVelocity = Vector(speedX, speedY, speedZ)

            val gravityVelocity = if (dy < 0) {
                Vector(0.0, -0.1, 0.0)
            } else Vector.ZERO

            val newVelocity = (velocity + targetVelocity).normalize() * speed + gravityVelocity

            return newVelocity
        }

        fun calculateMovement(velocity: Vector): PhysicsResult {
            // Prevent ghosting
            return BlockCollision.handlePhysics(
                boundingBox(),
                velocity,
                location,
                BukkitBlockGetter(
                    location.toBukkitLocation().world
                        ?: throw IllegalStateException("Trying to navigate in ${location.world} which is not loaded, how did you manage to do that?")
                ),
                false,
            )
        }

        fun calculateRotation(): Pair<Float, Float> {
            val path = path ?: return Pair(location.yaw, location.pitch)
            val targetNode = path.at(min(path.cursor() + 3, path.length() - 1))
            val targetLookPoint = targetNode.coordinates().toVector().mid()
            val targetYaw = getLookYaw(targetLookPoint.x - location.x, targetLookPoint.z - location.z)
            val targetPitch = getLookPitch(
                targetLookPoint.x - location.x,
                targetLookPoint.y - location.y,
                targetLookPoint.z - location.z
            )
            val currentYaw = if (location.yaw - targetYaw > 180) {
                location.yaw - 360
            } else if (location.yaw - targetYaw < -180) {
                location.yaw + 360
            } else {
                location.yaw
            }

            val yaw = smoothDamp(currentYaw, targetYaw, yawVelocity, 0.2f)
            val pitch = smoothDamp(location.pitch, targetPitch, pitchVelocity, 0.2f)

            return yaw to pitch
        }

        override fun isComplete(): Boolean {
            if (path == null) return true
            return (location.distanceSqrt(edge.end) ?: Double.POSITIVE_INFINITY) < 1
        }

        override fun coordinates(): Vec3d = Vec3d(location.x, location.y, location.z)

        // TODO: Make width and height configurable for each entity
        override fun width(): Float = 0.6f

        // TODO: Make width and height configurable for each entity
        override fun height(): Float = 1.8f
        fun boundingBox(): BoundingBox {
            val width = width().toDouble()
            val height = height().toDouble()
            val halfWidth = width / 2
            return BoundingBox(-halfWidth, 0.0, -halfWidth, halfWidth, height, halfWidth)
        }

        override fun age(): Int = 0
        override fun bound(): Boolean = false
        override fun searchRange(): Float = 40f
        override fun capabilities(): IPathingEntity.Capabilities = PFCapabilities()

    }
}