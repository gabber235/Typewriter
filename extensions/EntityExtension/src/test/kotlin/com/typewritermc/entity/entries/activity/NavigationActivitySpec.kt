package com.typewritermc.entity.entries.activity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.ActivityContext
import com.typewritermc.engine.paper.entry.entity.EntityState
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.GPS
import com.typewritermc.roadnetwork.gps.GPSEdge
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import kotlinx.coroutines.delay
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module

private const val TICK_LIMIT = 2000

private val world = World("navigation-world")

private fun positionAt(x: Double) = Position(world, x, 64.0, 0.0)

private fun propertyAt(x: Double) = PositionProperty(world, x, 64.0, 0.0, 0f, 0f)

private fun edgeBetween(startX: Double, endX: Double): GPSEdge {
    val length = endX - startX
    return GPSEdge(positionAt(startX), positionAt(endX), length, length)
}

private class RecordingGPS(private val route: List<GPSEdge>) : GPS {
    override val roadNetwork: Ref<RoadNetworkEntry> = emptyRef()
    var searches = 0
    var clearedPreviousPath = 0

    override suspend fun findPath(): Result<List<GPSEdge>> {
        searches++
        return Result.success(route)
    }

    override fun clearPreviousPath() {
        clearedPreviousPath++
    }
}

class NavigationActivitySpec : FunSpec({
    val route = listOf(edgeBetween(0.0, 20.0), edgeBetween(20.0, 40.0))

    beforeTest {
        startKoin {
            modules(module { factory<Boolean>(named("isEnabled")) { true } })
        }
    }

    afterTest { stopKoin() }

    fun context(): ActivityContext {
        val context = mockk<ActivityContext>(relaxed = true)
        every { context.isViewed } returns false
        every { context.entityState } returns EntityState()
        return context
    }

    suspend fun NavigationActivity.tickUntilTravelling(context: ActivityContext) {
        repeat(TICK_LIMIT) {
            tick(context)
            if (currentPosition.x != 0.0 || it > 20) return
            delay(1)
        }
    }

    test("activating for the first time searches for a route") {
        val gps = RecordingGPS(route)
        val activity = NavigationActivity(gps, propertyAt(0.0))

        activity.activate(context(), propertyAt(0.0))
        activity.tickUntilTravelling(context())

        gps.searches shouldBe 1
    }

    test("activating where it left off keeps travelling the same edge") {
        val gps = RecordingGPS(route)
        val context = context()
        val activity = NavigationActivity(gps, propertyAt(0.0))

        activity.activate(context, propertyAt(0.0))
        activity.tickUntilTravelling(context)

        activity.deactivate(context)
        activity.activate(context, activity.currentPosition)
        repeat(400) {
            activity.tick(context)
            delay(1)
        }

        gps.searches shouldBe 1
        gps.clearedPreviousPath shouldBe 1
        activity.currentPosition.x shouldBe route.last().end.x
    }

    test("activating more than a block away searches again") {
        val gps = RecordingGPS(route)
        val context = context()
        val activity = NavigationActivity(gps, propertyAt(0.0))

        activity.activate(context, propertyAt(0.0))
        activity.tickUntilTravelling(context)

        activity.deactivate(context)
        activity.activate(context, propertyAt(activity.currentPosition.x + 5.0))
        repeat(TICK_LIMIT) {
            activity.tick(context)
            if (gps.searches > 1) return@repeat
            delay(1)
        }

        gps.searches shouldBe 2
        gps.clearedPreviousPath shouldBe 2
    }
})
