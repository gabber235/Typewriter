package com.typewritermc.visibility.effector

import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.visibility.RecordingEffectEntry
import com.typewritermc.visibility.TestRuler
import com.typewritermc.visibility.entry.effect.MultipleVisibilityEffectEntry
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.rule.VisibilityRule
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import java.util.logging.Logger

private class TickRecordingEffectEntry(
    override val id: String,
    private val ticks: java.util.concurrent.atomic.AtomicInteger,
    override val name: String = id,
) : VisibilityEffectEntry {
    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        TickRecordingEffector(ticks)
}

private class TickRecordingEffector(
    private val ticks: java.util.concurrent.atomic.AtomicInteger,
) : TickableVisibilityEffector {
    override suspend fun initialize() {}
    override suspend fun dispose() {}
    override suspend fun tick() { ticks.incrementAndGet() }
}

class MultipleVisibilityEffectorSpec : FunSpec({
    lateinit var events: CopyOnWriteArrayList<String>

    beforeTest {
        events = CopyOnWriteArrayList()
        startKoin {
            modules(module {
                single { Logger.getLogger("MultipleVisibilityEffectorSpec") }
            })
        }
    }

    afterTest {
        stopKoin()
    }

    fun rule() = VisibilityRule(
        viewer = UUID.randomUUID(),
        target = UUID.randomUUID(),
        priority = 10,
        effect = emptyRef<VisibilityEffectEntry>(),
        ruler = TestRuler(priority = 10),
        entryId = "multiple_effect_test",
    )

    fun effect(
        id: String,
        failOnInitialize: Boolean = false,
        rerender: Boolean = false,
    ): VisibilityEffectEntry = RecordingEffectEntry(id, events, failOnInitialize, rerender = rerender)

    test("a bundle asks for a re render when any one of its sub effects needs one") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("a").ref(), effect("skin", rerender = true).ref(), effect("c").ref()),
        )

        effector.initialize()

        effector.needsPairRerender shouldBe true
    }

    test("a bundle of effects that all apply through packets asks for none") {
        val effector = MultipleVisibilityEffector(rule(), listOf(effect("a").ref(), effect("b").ref()))

        effector.initialize()

        effector.needsPairRerender shouldBe false
    }

    test("a bundle still asks for a re render after it let its sub effects go") {
        val effector = MultipleVisibilityEffector(rule(), listOf(effect("skin", rerender = true).ref()))

        effector.initialize()
        effector.dispose()

        // The engine reads this again after disposing, to send the target under their real profile.
        // A bundle that cleared it during disposal would leave the disguise on the client.
        effector.needsPairRerender shouldBe true
    }

    test("a sub effect that took hold and then failed still leaves a re render to do") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("broken", failOnInitialize = true, rerender = true).ref()),
        )

        shouldThrow<IllegalStateException> { effector.initialize() }

        effector.needsPairRerender shouldBe true
    }

    test("initializes sub effects in order and disposes them in reverse order") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("a").ref(), effect("b").ref(), effect("c").ref()),
        )

        effector.initialize()
        effector.dispose()

        events shouldContainExactly listOf(
            "a:initialize", "b:initialize", "c:initialize",
            "c:dispose", "b:dispose", "a:dispose",
        )
    }

    test("rolls back every sub effect it reached when one fails, including the one that threw") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("a").ref(), effect("b").ref(), effect("broken", failOnInitialize = true).ref()),
        )

        shouldThrow<IllegalStateException> { effector.initialize() }

        events shouldContainExactly listOf(
            "a:initialize", "b:initialize", "broken:initialize-failed",
            "broken:dispose", "b:dispose", "a:dispose",
        )
    }

    test("a sub effect that fails after the first one is still disposed itself") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("a").ref(), effect("broken", failOnInitialize = true).ref(), effect("c").ref()),
        )

        shouldThrow<IllegalStateException> { effector.initialize() }

        events shouldContainExactly listOf(
            "a:initialize", "broken:initialize-failed", "broken:dispose", "a:dispose",
        )
    }

    test("the engine's compensating dispose after a failed initialization does not dispose twice") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("a").ref(), effect("broken", failOnInitialize = true).ref()),
        )

        shouldThrow<IllegalStateException> { effector.initialize() }
        events.clear()
        effector.dispose()

        events shouldContainExactly emptyList()
    }

    test("an empty effect list fails fast") {
        val effector = MultipleVisibilityEffector(rule(), emptyList())
        shouldThrow<IllegalArgumentException> { effector.initialize() }
    }

    test("forwards ticks to tickable sub effectors") {
        val ticks = java.util.concurrent.atomic.AtomicInteger(0)
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(effect("a").ref(), TickRecordingEffectEntry("ticker", ticks).ref()),
        )

        effector.initialize()
        (effector as TickableVisibilityEffector).tick()
        (effector as TickableVisibilityEffector).tick()
        effector.dispose()

        ticks.get() shouldBe 2
    }

    test("ticking a multi with no tickable children changes nothing") {
        val effector = MultipleVisibilityEffector(rule(), listOf(effect("a").ref()))

        effector.initialize()
        (effector as TickableVisibilityEffector).tick()

        events shouldContainExactly listOf("a:initialize")

        effector.dispose()
        events shouldContainExactly listOf("a:initialize", "a:dispose")
    }

    test("a tick after disposal reaches no sub effector") {
        val ticks = java.util.concurrent.atomic.AtomicInteger(0)
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(TickRecordingEffectEntry("ticker", ticks).ref()),
        )

        effector.initialize()
        (effector as TickableVisibilityEffector).tick()
        effector.dispose()
        (effector as TickableVisibilityEffector).tick()

        ticks.get() shouldBe 1
    }

    test("a bundle that contains itself is refused instead of recursing") {
        val outer = MultipleVisibilityEffectEntry("outer")
        val cyclic = MultipleVisibilityEffectEntry("outer", effects = listOf(outer.ref()))

        shouldThrow<IllegalStateException> { cyclic.createEffector(rule()) }
    }

    test("a bundle that contains itself through another bundle is refused too") {
        val outer = MultipleVisibilityEffectEntry("outer")
        val inner = MultipleVisibilityEffectEntry("inner", effects = listOf(outer.ref()))
        val cyclic = MultipleVisibilityEffectEntry("outer", effects = listOf(inner.ref()))

        shouldThrow<IllegalStateException> { cyclic.createEffector(rule()) }
    }

    test("a bundle nesting another bundle is accepted") {
        val inner = MultipleVisibilityEffectEntry("inner", effects = listOf(effect("a").ref()))
        val outer = MultipleVisibilityEffectEntry("outer", effects = listOf(inner.ref()))

        outer.createEffector(rule()).initialize()

        events shouldContainExactly listOf("a:initialize")
    }

    test("a nested bundle reports the self support of its deepest effect") {
        val selfEffect = RecordingEffectEntry("self_effect", events, self = true)
        val inner = MultipleVisibilityEffectEntry("inner", effects = listOf(selfEffect.ref()))
        val outer = MultipleVisibilityEffectEntry("outer", effects = listOf(inner.ref()))

        outer.supportsSelf shouldBe true
    }

    test("a missing sub effect entry fails fast without initializing anything") {
        val effector = MultipleVisibilityEffector(
            rule(),
            listOf(emptyRef<VisibilityEffectEntry>()),
        )

        shouldThrow<IllegalStateException> { effector.initialize() }
        events shouldContainExactly emptyList()
    }

    test("a bundle on the self pair leaves out the sub effects that turned self off") {
        val player = mockk<Player>()
        val noSelf = RecordingEffectEntry("no_self", events)
        val withSelf = RecordingEffectEntry("with_self", events, self = true, selfActive = true)

        val applicable = selfApplicableRefs(listOf(noSelf.ref(), withSelf.ref()), player)

        applicable.map { it.id } shouldContainExactly listOf("with_self")
    }

    test("a sub effect whose self toggle is off right now is left out too") {
        val player = mockk<Player>()
        val toggled = RecordingEffectEntry("toggled", events, self = true, selfActive = true)

        selfApplicableRefs(listOf(toggled.ref()), player).map { it.id } shouldContainExactly listOf("toggled")

        toggled.selfActive = false
        selfApplicableRefs(listOf(toggled.ref()), player) shouldContainExactly emptyList()
    }

    test("a sub effect ref that resolves to nothing is kept so creating it can report it") {
        val player = mockk<Player>()
        val missing = emptyRef<VisibilityEffectEntry>()

        selfApplicableRefs(listOf(missing), player) shouldContainExactly listOf(missing)
    }

    test("multiple reports self support when any sub effect supports self") {
        val player = mockk<Player>()
        val noSelf = RecordingEffectEntry("a", events)
        val withSelf = RecordingEffectEntry("b", events, self = true, selfActive = true)
        val multiple = MultipleVisibilityEffectEntry(
            id = "m",
            effects = listOf(noSelf.ref(), withSelf.ref()),
        )

        multiple.supportsSelf shouldBe true
        multiple.appliesToSelf(player) shouldBe true

        val onlyNoSelf = MultipleVisibilityEffectEntry(id = "m2", effects = listOf(noSelf.ref()))
        onlyNoSelf.supportsSelf shouldBe false
        onlyNoSelf.appliesToSelf(player) shouldBe false
    }
})
