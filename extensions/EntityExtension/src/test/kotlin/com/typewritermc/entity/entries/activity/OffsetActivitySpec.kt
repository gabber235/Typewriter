package com.typewritermc.entity.entries.activity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.entity.Player

private class StubActivityContext : ActivityContext {
    override val instanceRef: Ref<out EntityInstanceEntry> = emptyRef()
    override val isViewed: Boolean = false
    override val viewers: List<Player> = emptyList()
    override val entityState: EntityState = EntityState()
}

class OffsetActivitySpec : FunSpec({
    val world = World("decorator-world")

    fun positionAt(x: Double, y: Double, z: Double) = PositionProperty(world, x, y, z, 0f, 0f)

    test("re-activating with the position it last reported does not compound the offset") {
        val context = StubActivityContext()
        val base = positionAt(0.0, 64.0, 0.0)
        val offsetActivity = OffsetActivity(
            offset = ConstVar(Vector(0.0, 2.0, 0.0)),
            childActivity = IdleActivity(base)
        )

        offsetActivity.activate(context, base)
        val decorated = offsetActivity.currentPosition
        decorated shouldBe base.add(0.0, 2.0, 0.0)

        offsetActivity.activate(context, decorated)

        offsetActivity.currentPosition shouldBe decorated
    }
})
