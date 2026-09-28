package com.typewritermc.visibility.fact

import com.typewritermc.core.entries.Ref
import com.typewritermc.visibility.RecordingEffectEntry
import com.typewritermc.visibility.TestRuler
import com.typewritermc.visibility.VisibilityEngine
import com.typewritermc.visibility.entry.rule.VisibilityRuleProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import java.util.concurrent.CopyOnWriteArrayList
import java.util.logging.Logger

class VisibilityCountFactSpec : FunSpec({
    lateinit var server: ServerMock
    lateinit var engine: VisibilityEngine
    lateinit var events: CopyOnWriteArrayList<String>

    beforeTest {
        server = MockBukkit.mock()
        engine = VisibilityEngine()
        events = CopyOnWriteArrayList()
        startKoin {
            modules(module {
                single { Logger.getLogger("VisibilityCountFactSpec") }
                single { engine }
                single(named("isEnabled")) { true }
            })
        }
    }

    afterTest {
        stopKoin()
        MockBukkit.unmock()
    }

    fun effect(id: String) = RecordingEffectEntry(id, events)

    test("the targets count is how many other players the viewer sees changed") {
        val viewer = server.addPlayer("Viewer")
        val first = server.addPlayer("First")
        val second = server.addPlayer("Second")
        val ruler = TestRuler(priority = 10, entryId = "rule_a")
        ruler.apply(viewer.uniqueId, first.uniqueId, effect("a"))
        ruler.apply(viewer.uniqueId, second.uniqueId, effect("b"))
        engine.awaitLifecycles()

        VisibilityTargetsCountFact().readSinglePlayer(viewer).value shouldBe 2
        VisibilityViewersCountFact().readSinglePlayer(first).value shouldBe 1
    }

    test("a self effect counts for neither side") {
        val viewer = server.addPlayer("Viewer")
        val ruler = TestRuler(priority = 10, entryId = "rule_a")
        ruler.apply(viewer.uniqueId, viewer.uniqueId, effect("self"))
        engine.awaitLifecycles()

        VisibilityTargetsCountFact().readSinglePlayer(viewer).value shouldBe 0
        VisibilityViewersCountFact().readSinglePlayer(viewer).value shouldBe 0
    }

    test("the counts can be narrowed to one rule entry") {
        val viewer = server.addPlayer("Viewer")
        val first = server.addPlayer("First")
        val second = server.addPlayer("Second")
        TestRuler(priority = 10, entryId = "rule_a").apply(viewer.uniqueId, first.uniqueId, effect("a"))
        TestRuler(priority = 10, entryId = "rule_b").apply(viewer.uniqueId, second.uniqueId, effect("b"))
        engine.awaitLifecycles()

        val onlyA = VisibilityTargetsCountFact(ruleEntry = Ref("rule_a", VisibilityRuleProvider::class))
        onlyA.readSinglePlayer(viewer).value shouldBe 1

        VisibilityTargetsCountFact().readSinglePlayer(viewer).value shouldBe 2
    }

    test("a player with no rules reads zero") {
        val lonely = server.addPlayer("Lonely")

        VisibilityTargetsCountFact().readSinglePlayer(lonely).value shouldBe 0
        VisibilityViewersCountFact().readSinglePlayer(lonely).value shouldBe 0
    }
})
