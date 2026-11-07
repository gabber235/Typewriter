package com.typewritermc.realm.formula

import com.typewritermc.realm.testing.hookCatalog
import com.typewritermc.realm.testing.intUse
import com.typewritermc.realm.testing.measuredCommit
import com.typewritermc.realm.testing.plain
import com.typewritermc.realm.testing.seededWorkload
import com.typewritermc.realm.testing.setFormula
import com.typewritermc.realm.testing.setVar
import com.typewritermc.realm.testing.startMeasuring
import com.typewritermc.realm.testing.withSetup
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import kotlin.time.Duration.Companion.minutes

// Prints its numbers for the pull request and asserts no time. Gates, read from the printed lines: a pass after one
// value edit under 200 ms; a commit with one unrelated broken formula under 50 ms above one with none; a reply with
// 20 broken formulas under 1 MB.
val SeededRealmMeasurement by testSuite {
    // Over two thousand resources seed, bind and check for real, which outlasts the default minute.
    test(
        "a seeded realm of a thousand holders by a thousand names, with no, one and twenty broken formulas",
        testConfig = TestConfig.testScope(isEnabled = true, timeout = 30.minutes),
    ) {
        withSetup(seededWorkload(), catalog = hookCatalog()) { seeded ->
            println("seeded: ${startMeasuring()}")
            val runs = listOf("warm up", "warm up", "warm up", "no broken formula", "no broken formula", "no broken formula")
            runs.forEachIndexed { value, label -> println(measuredCommit(label, setVar(seeded.named("n999"), intUse, plain(value)))) }

            println(measuredCommit("break one", setFormula(seeded.named("f0"), "missing_0 + 1")))
            repeat(3) { println(measuredCommit("one broken formula", setVar(seeded.named("n999"), intUse, plain(100 + it)))) }

            val nineteen = (1..19).map { setFormula(seeded.named("f$it"), "missing_$it + 1") }
            println(measuredCommit("break nineteen more", *nineteen.toTypedArray()))
            repeat(3) { println(measuredCommit("twenty broken formulas", setVar(seeded.named("n999"), intUse, plain(200 + it)))) }
        }
    }
}
