package com.typewritermc.engine.events

import com.typewritermc.engine.events.testing.Beat
import com.typewritermc.engine.events.testing.BeatEntry
import com.typewritermc.engine.events.testing.Downbeat
import com.typewritermc.engine.events.testing.EventHarness
import com.typewritermc.engine.events.testing.EveryBeat
import com.typewritermc.engine.events.testing.GuardEntry
import com.typewritermc.engine.events.testing.LivePlayers
import com.typewritermc.engine.events.testing.after
import com.typewritermc.engine.events.testing.beats
import com.typewritermc.engine.events.testing.protagonist
import com.typewritermc.engine.events.testing.published
import com.typewritermc.events.Candidate
import com.typewritermc.events.HandlerConfig
import com.typewritermc.events.HasChat
import com.typewritermc.events.Param
import com.typewritermc.identity.Protagonist
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

/** DEMAND-U: which configurations a configured source is opened with, and which handlers an occurrence reaches. */
val DemandTest by testSuite {
    test("a configured source receives only the configurations whose handler can run") {
        val beats = beats()
        EventHarness(
            beats,
            after(Beat::class, config = HandlerConfig.Object(EveryBeat)) { _, _ -> },
            after(Beat::class, Param.Candidate(GuardEntry::class), config = HandlerConfig.Object(Downbeat)) { _, _ -> },
        )
        beats.demand shouldBe setOf(EveryBeat)
    }

    test("publishing adds and removes entry configurations, and the source closes once none is left") {
        val beats = beats()
        val events = EventHarness(beats, after(Beat::class, config = HandlerConfig.Entries(BeatEntry::class)) { _, _ -> })
        val slow = BeatEntry("slow", every = 20)
        val fast = BeatEntry("fast", every = 2)
        beats.demand shouldBe null

        events.publish(published(slow), published(fast))
        beats.demand shouldBe setOf(slow, fast)

        events.publish(published(fast))
        beats.demand shouldBe setOf(fast)
        beats.opens shouldBe 1

        events.publish()
        beats.demand shouldBe null
    }

    test("an object configuration is present while its handler is loaded, whatever is published") {
        val beats = beats()
        val events = EventHarness(beats, after(Beat::class, config = HandlerConfig.Object(EveryBeat)) { _, _ -> })
        beats.demand shouldBe setOf(EveryBeat)

        events.publish(published(BeatEntry("unrelated")))
        events.publish()
        beats.demand shouldBe setOf(EveryBeat)
        beats.opens shouldBe 1
    }

    test("an occurrence runs only the handlers of its configuration, which receive it and its own entry") {
        val beats = beats()
        val seen = mutableListOf<String>()
        val slow = BeatEntry("slow", every = 20)
        val fast = BeatEntry("fast", every = 2)
        val events =
            EventHarness(
                beats,
                after(Beat::class, config = HandlerConfig.Object(EveryBeat)) { _, _ -> seen += "every beat" },
                after(
                    Beat::class,
                    Param.Config(BeatEntry::class),
                    Param.Candidate(BeatEntry::class, ofConfig = true),
                    config = HandlerConfig.Entries(BeatEntry::class),
                ) { _, values ->
                    val entry = values[1] as Candidate<*>
                    seen += "${(values[0] as BeatEntry).name} as ${entry.entry.name}"
                },
            )
        events.publish(published(slow), published(fast))

        beats.fire(fast)
        events.tick()
        seen shouldContainExactly listOf("fast as fast")
    }

    test("an event without a subject runs a handler once per live protagonist it asks for") {
        val beats = beats()
        val players = LivePlayers(protagonist("sam"), protagonist("kim"))
        val events =
            EventHarness(
                beats,
                players,
                after(
                    Beat::class,
                    Param.Identity(Protagonist::class),
                    Param.Trait(HasChat::class),
                    config = HandlerConfig.Object(EveryBeat),
                ) {
                    _,
                    values,
                    ->
                    (values[1] as HasChat).send("beat for ${(values[0] as Protagonist).principal.id}")
                },
            )

        beats.fire(EveryBeat)
        events.tick()
        players.seen(protagonist("sam")) shouldContainExactly listOf("beat for sam")
        players.seen(protagonist("kim")) shouldContainExactly listOf("beat for kim")
    }

    test("an occurrence without a subject is work of every live protagonist until its chain ends, and a wipe releases only that one") {
        val beats = beats()
        val ran = mutableListOf<String>()
        val events =
            EventHarness(
                beats,
                LivePlayers(protagonist("sam"), protagonist("kim")),
                after(Beat::class, config = HandlerConfig.Object(EveryBeat)) { _, _ -> ran += "beat" },
            )

        beats.fire(EveryBeat)
        events.work.busy(protagonist("sam")) shouldBe 1
        events.work.busy(protagonist("kim")) shouldBe 1

        events.wipe(protagonist("sam"))
        events.work.busy(protagonist("sam")) shouldBe 0
        events.work.busy(protagonist("kim")) shouldBe 1

        events.tick()
        ran shouldContainExactly listOf("beat")
        events.work.busy(protagonist("kim")) shouldBe 0
    }
}
