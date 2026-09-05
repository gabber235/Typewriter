package com.typewritermc.visibility

import com.typewritermc.core.entries.emptyRef
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import java.util.logging.Logger

class VisibilityEngineSpec : FunSpec({
    lateinit var engine: VisibilityEngine
    lateinit var events: CopyOnWriteArrayList<String>

    beforeTest {
        engine = VisibilityEngine()
        events = CopyOnWriteArrayList()
        startKoin {
            modules(module {
                single { Logger.getLogger("VisibilityEngineSpec") }
                single { engine }
                single(named("isEnabled")) { true }
            })
        }
    }

    afterTest {
        stopKoin()
    }

    fun effect(id: String, failOnInitialize: Boolean = false) =
        RecordingEffectEntry(id, events, failOnInitialize)

    val viewer = UUID.randomUUID()
    val target = UUID.randomUUID()

    test("a shutdown while the plugin is already disabled still disposes every effect") {
        val ruler = TestRuler(priority = 10)
        // The disposal is slow on purpose. One scheduled onto the engine's own pool would still be
        // running when shutdown returns, and on a disabled plugin nothing would finish it.
        val ghost = RecordingEffectEntry("ghost", events, disposeDelayMs = 50)
        // Registered, so shutdown disposes it the way it does on a live server. Disposing a ruler
        // retracts its rules, which is what empties the engine's indexes.
        engine.registerRuler(ruler)
        ruler.apply(viewer, target, ghost)
        engine.awaitLifecycles()
        events.clear()

        // Bukkit clears the enabled flag before calling onDisable, so this is the state the engine is
        // in for every server stop and every plugin manager disable.
        stopKoin()
        startKoin {
            modules(module {
                single { Logger.getLogger("VisibilityEngineSpec") }
                single { engine }
                single(named("isEnabled")) { false }
            })
        }

        engine.shutdown()

        events shouldContainExactly listOf("ghost:dispose")
    }

    test("the first rule for a pair activates its effector") {
        val ruler = TestRuler(priority = 10)
        ruler.apply(viewer, target, effect("hide"))
        engine.awaitLifecycles()

        events shouldContainExactly listOf("hide:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe ruler.entryId
        engine.viewerRuleCount(viewer) shouldBe 1
        engine.targetRuleCount(target) shouldBe 1
    }

    test("a lower priority rule is shadowed by the active effect") {
        val high = TestRuler(priority = 20)
        val low = TestRuler(priority = 10)
        high.apply(viewer, target, effect("high"))
        low.apply(viewer, target, effect("low"))
        engine.awaitLifecycles()

        events shouldContainExactly listOf("high:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe high.entryId
    }

    test("a higher priority rule replaces the active effect, disposing before initializing") {
        val low = TestRuler(priority = 10)
        val high = TestRuler(priority = 20)
        low.apply(viewer, target, effect("low"))
        high.apply(viewer, target, effect("high"))
        engine.awaitLifecycles()

        events shouldContainExactly listOf("low:initialize", "low:dispose", "high:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe high.entryId
    }

    test("on equal priority the last added rule wins") {
        val first = TestRuler(priority = 10, entryId = "first")
        val second = TestRuler(priority = 10, entryId = "second")
        first.apply(viewer, target, effect("first"))
        second.apply(viewer, target, effect("second"))
        engine.awaitLifecycles()

        events shouldContainExactly listOf("first:initialize", "first:dispose", "second:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe "second"
    }

    test("re adding the active rule does not restart the effector") {
        val ruler = TestRuler(priority = 10)
        val hide = effect("hide")
        ruler.apply(viewer, target, hide)
        ruler.apply(viewer, target, hide)
        engine.awaitLifecycles()

        events shouldContainExactly listOf("hide:initialize")
    }

    test("removal by a ruler that does not own the active effect is ignored") {
        val owner = TestRuler(priority = 20)
        val other = TestRuler(priority = 10)
        val high = effect("high")
        val low = effect("low")
        owner.apply(viewer, target, high)
        other.apply(viewer, target, low)
        other.retract(viewer, target)
        engine.awaitLifecycles()

        events shouldContainExactly listOf("high:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe owner.entryId
    }

    test("removing the active rule promotes the highest priority shadowed rule") {
        val high = TestRuler(priority = 30, entryId = "high")
        val mid = TestRuler(priority = 20, entryId = "mid")
        val low = TestRuler(priority = 10, entryId = "low")
        listOf(high, mid, low).forEach(engine::registerRuler)

        val highEffect = effect("high")
        high.apply(viewer, target, highEffect)
        mid.apply(viewer, target, effect("mid"))
        low.apply(viewer, target, effect("low"))
        high.retract(viewer, target)
        engine.awaitLifecycles()

        events shouldContainExactly listOf("high:initialize", "high:dispose", "mid:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe "mid"
    }

    test("removing the last rule clears the pair") {
        val ruler = TestRuler(priority = 10)
        engine.registerRuler(ruler)
        val hide = effect("hide")
        ruler.apply(viewer, target, hide)
        ruler.retract(viewer, target)
        engine.awaitLifecycles()

        events shouldContainExactly listOf("hide:initialize", "hide:dispose")
        engine.activeRuleFor(viewer, target).shouldBeNull()
        engine.viewerRuleCount(viewer) shouldBe 0
        engine.targetRuleCount(target) shouldBe 0
    }

    test("an effector that fails to initialize is disposed and retracted") {
        val ruler = TestRuler(priority = 10)
        ruler.apply(viewer, target, effect("broken", failOnInitialize = true))
        engine.awaitLifecycles()

        events shouldContainExactly listOf("broken:initialize-failed", "broken:dispose")
        engine.activeRuleFor(viewer, target).shouldBeNull()
        engine.viewerRuleCount(viewer) shouldBe 0
    }

    test("a shadowed rule takes over when the winning effect fails to initialize") {
        val high = TestRuler(priority = 20, entryId = "high")
        val low = TestRuler(priority = 10, entryId = "low")
        listOf(high, low).forEach(engine::registerRuler)

        low.apply(viewer, target, effect("low"))
        high.apply(viewer, target, effect("broken", failOnInitialize = true))
        engine.awaitLifecycles()

        events shouldContainExactly listOf(
            "low:initialize",
            "low:dispose",
            "broken:initialize-failed",
            "broken:dispose",
            "low:initialize",
        )
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe "low"
    }

    test("two rules that both fail to initialize give up instead of electing each other forever") {
        val high = TestRuler(priority = 20, entryId = "high")
        val low = TestRuler(priority = 10, entryId = "low")
        listOf(high, low).forEach(engine::registerRuler)

        low.apply(viewer, target, effect("low", failOnInitialize = true))
        engine.awaitLifecycles()
        high.apply(viewer, target, effect("high", failOnInitialize = true))
        engine.awaitLifecycles()

        events shouldContainExactly listOf(
            "low:initialize-failed",
            "low:dispose",
            "high:initialize-failed",
            "high:dispose",
            "low:initialize-failed",
            "low:dispose",
        )
        engine.activeRuleFor(viewer, target).shouldBeNull()
    }

    test("a winning rule with a broken effect reference falls back to the rule it shadows") {
        val high = TestRuler(priority = 20, entryId = "high")
        val low = TestRuler(priority = 10, entryId = "low")
        listOf(high, low).forEach(engine::registerRuler)

        low.apply(viewer, target, effect("low"))
        high.applyBrokenEffect(viewer, target, emptyRef<VisibilityEffectEntry>())
        engine.awaitLifecycles()

        events shouldContainExactly listOf("low:initialize", "low:dispose", "low:initialize")
        engine.activeRuleFor(viewer, target).shouldNotBeNull().entryId shouldBe "low"
    }

    test("a rule with a missing effect entry and nothing to fall back on clears the pair") {
        val only = TestRuler(priority = 10)
        engine.registerRuler(only)

        only.applyBrokenEffect(viewer, target, emptyRef<VisibilityEffectEntry>())
        engine.awaitLifecycles()

        events shouldContainExactly emptyList()
        engine.activeRuleFor(viewer, target).shouldBeNull()
    }

    test("a self rule is not counted as a player the viewer sees or as a viewer that sees them") {
        val ruler = TestRuler(priority = 10)
        ruler.apply(viewer, viewer, effect("self"))
        ruler.apply(viewer, target, effect("other"))
        engine.awaitLifecycles()

        engine.activeRuleFor(viewer, viewer).shouldNotBeNull()
        engine.viewerRuleCount(viewer) shouldBe 1
        engine.targetRuleCount(viewer) shouldBe 0
        engine.targetRuleCount(target) shouldBe 1
    }

    test("rule counts can be filtered by entry id") {
        val ruleA = TestRuler(priority = 10, entryId = "rule_a")
        val ruleB = TestRuler(priority = 10, entryId = "rule_b")
        val otherTarget = UUID.randomUUID()
        ruleA.apply(viewer, target, effect("a"))
        ruleB.apply(viewer, otherTarget, effect("b"))
        engine.awaitLifecycles()

        engine.viewerRuleCount(viewer) shouldBe 2
        engine.viewerRuleCount(viewer, "rule_a") shouldBe 1
        engine.viewerRuleCount(viewer, "rule_b") shouldBe 1
        engine.targetRuleCount(target, "rule_a") shouldBe 1
        engine.targetRuleCount(target, "rule_b") shouldBe 0
    }

    test("rapid retract and re add keeps the lifecycle ordered") {
        val ruler = TestRuler(priority = 10)
        engine.registerRuler(ruler)
        val hide = effect("hide")
        val glow = effect("glow")
        ruler.apply(viewer, target, hide)
        ruler.retract(viewer, target)
        ruler.apply(viewer, target, glow)
        engine.awaitLifecycles()

        events shouldContainExactly listOf("hide:initialize", "hide:dispose", "glow:initialize")
    }

    test("shutdown disposes all active effects and rulers") {
        val ruler = TestRuler(priority = 10)
        engine.registerRuler(ruler)
        val otherTarget = UUID.randomUUID()
        ruler.apply(viewer, target, effect("a"))
        ruler.apply(viewer, otherTarget, effect("b"))
        engine.awaitLifecycles()

        engine.shutdown()

        events.count { it.endsWith(":dispose") } shouldBe 2
        engine.viewerRuleCount(viewer) shouldBe 0
        engine.activeRuleFor(viewer, target).shouldBeNull()
    }
})
