package com.typewritermc.realm.formula

import com.typewritermc.realm.testing.hookCatalog
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.measuredCommit
import com.typewritermc.realm.testing.median
import com.typewritermc.realm.testing.plain
import com.typewritermc.realm.testing.seededWorkload
import com.typewritermc.realm.testing.setFormula
import com.typewritermc.realm.testing.setVar
import com.typewritermc.realm.testing.startMeasuring
import com.typewritermc.realm.testing.withSetup
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.assertSoftly
import io.kotest.inspectors.forAll
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.ints.shouldBeLessThan
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes

// Prints its numbers for the pull request and asserts the layer's gates on them. The pass is what a creator waits for
// after the commit reply: from the reply until the findings are ready. Checks start during the commit, so a pass that
// finished before the reply counts near zero; the commit gate covers that time. A pass after one value edit stays under
// 200 ms; a commit with one unrelated broken formula stays under 50 ms above one with none; the findings of a reply with
// 20 broken formulas stay under 1 MB. Each time gate reads the median of several runs, so one slow run does not fail
// it. The saved state beside the findings is printed only.
val SeededRealmMeasurement by testSuite {
    // Over two thousand resources seed, bind and check for real, which outlasts the default minute.
    test(
        "a seeded realm of a thousand holders by a thousand names, with no, one and twenty broken formulas",
        testConfig = TestConfig.testScope(isEnabled = true, timeout = 30.minutes),
    ) {
        withSetup(seededWorkload(), catalog = hookCatalog()) { seeded ->
            val edited = seeded.named("n999")

            suspend fun edits(
                label: String,
                from: Int,
            ) = (from until from + RUNS).map { value -> measuredCommit(label, setVar(edited, intUse, plain(value))).also(::println) }

            println("seeded: ${startMeasuring()}")
            edits("warm up", 0)
            val none = edits("no broken formula", 100)

            println(measuredCommit("break one", setFormula(seeded.named("f0"), "missing_0 + 1")))
            val one = edits("one broken formula", 200)

            val nineteen = (1..19).map { setFormula(seeded.named("f$it"), "missing_$it + 1") }
            println(measuredCommit("break nineteen more", *nineteen.toTypedArray()))
            val twenty = edits("twenty broken formulas", 300)

            assertSoftly {
                twenty.forAll { it.findingBytes shouldBeLessThan 1_000_000 }
                (none + one).map { it.pass }.median() shouldBeLessThan 200.milliseconds
                one.map { it.commit }.median() - none.map { it.commit }.median() shouldBeLessThan 50.milliseconds
            }
        }
    }
}

/** How many value edits each stage measures; the time gates read their median. */
private const val RUNS = 5
