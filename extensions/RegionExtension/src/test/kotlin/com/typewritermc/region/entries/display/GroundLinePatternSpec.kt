package com.typewritermc.region.entries.display

import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module

/**
 * A bare [com.typewritermc.engine.paper.entry.entries.Var.get] call resolves an interaction
 * context through Koin, even for a [ConstVar] whose value never depends on it, so this spec
 * needs the same minimal Koin bootstrap [GroundLineAnimationSpec] uses.
 */
class GroundLinePatternSpec : FunSpec({
    val player = mockk<Player>(relaxed = true)

    beforeSpec {
        startKoin {
            modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } })
        }
    }

    afterSpec {
        stopKoin()
    }

    test("a solid line lights every point") {
        val solid = SolidLine()
        for (arc in 0..20) solid.emitsAt(arc.toDouble(), player) shouldBe true
    }

    test("dashes light the dash and skip the gap") {
        val dashed = DashedLine(ConstVar(4.0), ConstVar(3.0))
        dashed.emitsAt(0.0, player) shouldBe true
        dashed.emitsAt(3.9, player) shouldBe true
        dashed.emitsAt(4.0, player) shouldBe false
        dashed.emitsAt(6.9, player) shouldBe false
        dashed.emitsAt(7.0, player) shouldBe true
    }

    test("dashes light the expected share of the loop") {
        val dashed = DashedLine(ConstVar(4.0), ConstVar(3.0))
        val lit = (0 until 7000).count { dashed.emitsAt(it / 100.0, player) }
        (lit / 7000.0) shouldBe (4.0 / 7.0 plusOrMinus 0.01)
    }

    test("a negative arc wraps into the pattern instead of going dark") {
        val dashed = DashedLine(ConstVar(4.0), ConstVar(3.0))
        dashed.emitsAt(-7.0, player) shouldBe true
        dashed.emitsAt(-3.0, player) shouldBe false
    }

    test("a zero length dash never lights, and a zero gap always does") {
        DashedLine(ConstVar(0.0), ConstVar(3.0)).emitsAt(0.0, player) shouldBe false
        DashedLine(ConstVar(4.0), ConstVar(0.0)).emitsAt(99.0, player) shouldBe true
    }
})
