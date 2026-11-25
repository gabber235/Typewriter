package com.typewritermc.realm.formula

import com.typewritermc.realm.testing.SeededSize
import com.typewritermc.realm.testing.measureBrokenFormulas
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.assertSoftly
import io.kotest.inspectors.forAll
import io.kotest.matchers.ints.shouldBeLessThan
import io.kotest.matchers.longs.shouldBeLessThanOrEqual
import kotlin.time.Duration.Companion.minutes

// Prints its numbers for the pull request and asserts the layer's gates on them, all of them graph work or bytes, never
// wall clock time, which varies with the machine. The graph work an unrelated broken formula adds to a commit and the
// pass it starts does not grow with the realm: a realm twice the size adds no more for one broken formula, and twenty
// add at most twenty times what one adds, or nothing when one adds nothing; a broken formula checks less, so what it
// adds can be below zero. The findings of a reply with 20 broken formulas stay under 1 MB. Commit and pass times, the
// pass timed from the commit reply until the findings are ready, and the saved state beside the findings are printed
// only.
val SeededRealmMeasurement by testSuite {
    // Thousands of resources seed, bind and check for real, twice, which outlasts the default minute.
    test(
        "in a seeded realm twice the size one unrelated broken formula adds no more graph work, twenty add at most " +
            "twenty times one, and findings stay under 1 MB",
        testConfig = TestConfig.testScope(isEnabled = true, timeout = 30.minutes),
    ) {
        val small = measureBrokenFormulas(SeededSize(names = 500, holders = 500, contentHolders = 100))
        val large = measureBrokenFormulas(SeededSize(names = 1000, holders = 1000, contentHolders = 200))

        assertSoftly {
            large.twenty.forAll { it.findingBytes shouldBeLessThan 1_000_000 }
            large.extraForOne shouldBeLessThanOrEqual small.extraForOne
            large.extraForTwenty shouldBeLessThanOrEqual 20 * large.extraForOne.coerceAtLeast(0)
        }
    }
}
