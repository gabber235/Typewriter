package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.EventHarness
import com.typewritermc.engine.events.testing.Knock
import com.typewritermc.engine.events.testing.TestSource
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.events.testing.verdict
import com.typewritermc.engine.formula.testing.FormulaPublication
import com.typewritermc.engine.formula.testing.Said
import com.typewritermc.engine.formula.testing.book
import com.typewritermc.engine.formula.testing.formula
import com.typewritermc.engine.formula.testing.saidEntry
import com.typewritermc.engine.formula.testing.sequencePage
import com.typewritermc.events.Candidate
import com.typewritermc.events.Param
import com.typewritermc.events.TriggeredEvent
import com.typewritermc.events.pass
import com.typewritermc.formula.Var
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Identity
import com.typewritermc.library.BookContext
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

/** BOOK-U: content of a book whose condition is false for a protagonist acts as if it does not exist for it. */
val BookConditionTest by testSuite {
    val samOnly = Var.Computed<Boolean, BookContext>(formula("protagonist.principal.id == \"sam\""))

    listOf(
        Triple("an entry runs as a candidate only for the protagonists its book applies to", samOnly, listOf(protagonist("sam"))),
        Triple("an entry of a book whose condition fails to evaluate runs for nobody", Var.Computed(formula("missing")), emptyList()),
    ).forEach { (name, condition, expected) ->
        test(name) {
            val said = TestSource(Said::class)
            val ran = mutableListOf<Identity?>()
            val events =
                EventHarness(
                    said,
                    verdict(Said::class, Param.Candidate(EventEntry::class, ofEvent = true)) { _, values ->
                        ran += (values.single() as Candidate<*>).subject
                        pass()
                    },
                )
            events.publish(
                FormulaPublication(book("quests", condition), sequencePage("sequence", book = "quests"), saidEntry("greeting")).entries(),
            )

            said.fire(Said(protagonist("alex"), "hello"))
            said.fire(Said(protagonist("sam"), "hello"))

            ran shouldContainExactly expected
        }
    }

    test("a link into an entry whose book does not apply to the subject is skipped") {
        val said = TestSource(Said::class)
        val reached = mutableListOf<Pair<String, Identity>>()
        val events =
            EventHarness(
                said,
                Event_startHandler(),
                after(TriggeredEvent::class, Param.Triggered(EventEntry::class)) { triggered, _ ->
                    reached +=
                        triggered.entry.name to triggered.subject
                },
            )
        events.publish(
            FormulaPublication(
                book("open", Var.Value(true)),
                sequencePage("open page", book = "open"),
                saidEntry("start", page = "open page", next = listOf("gated step")),
                book("gated", samOnly),
                sequencePage("gated page", book = "gated"),
                saidEntry("gated step", condition = Var.Value(false), page = "gated page"),
            ).entries(),
        )

        said.fire(Said(protagonist("alex"), "hello"))
        said.fire(Said(protagonist("sam"), "hello"))
        events.tick()

        reached shouldContainExactly listOf("gated step" to protagonist("sam"))
    }

    test("a subject that is no protagonist always gets the entries of a book") {
        val knocks = TestSource(Knock::class)
        val ran = mutableListOf<Identity?>()
        val events =
            EventHarness(
                knocks,
                verdict(Knock::class, Param.Candidate(EventEntry::class)) { _, values ->
                    ran += (values.single() as Candidate<*>).subject
                    pass()
                },
            )
        events.publish(
            FormulaPublication(
                book("closed", Var.Value(false)),
                sequencePage("sequence", book = "closed"),
                saidEntry("greeting"),
            ).entries(),
        )

        knocks.fire(Knock())

        ran shouldContainExactly listOf(Knock().session)
    }

    test("a book's condition can read the engine asking") {
        val readsEngine = Var.Computed<Boolean, BookContext>(formula("engine == engine"))
        val publication = FormulaPublication(book("engine", readsEngine), sequencePage("sequence", book = "engine"), saidEntry("greeting"))

        publication
            .entries(engine = Engine(EngineId("lobby")))
            .entries(EventEntry::class)
            .single()
            .appliesTo(protagonist()) shouldBe true
    }
}
