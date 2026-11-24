package com.typewritermc.realm.formula

import com.typewritermc.realm.testing.SeededSize
import com.typewritermc.realm.testing.measureSeeded
import com.typewritermc.realm.testing.medianReplyBytes
import com.typewritermc.realm.testing.medianWork
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.assertSoftly
import io.kotest.assertions.withClue
import io.kotest.inspectors.forAll
import io.kotest.matchers.ints.shouldBeLessThan
import io.kotest.matchers.ints.shouldBeLessThanOrEqual
import io.kotest.matchers.longs.shouldBeLessThanOrEqual
import kotlin.time.Duration.Companion.minutes

// Prints its numbers for the pull request and asserts the layer's gates on them, all of them graph work or bytes, never
// wall clock time, which varies with the machine. A commit costs what it touched, not what the realm holds: in a realm
// twice the size, the graph work of a commit and the check pass it starts is no larger for a value edit, for an element
// added to the shared page, renamed or removed, and the commit reply is no larger. The graph work an unrelated broken
// formula adds does not grow with the realm: a realm twice the size adds no more for one broken formula, and twenty add
// at most twenty times what one adds, or nothing when one adds nothing; a broken formula checks less, so what it adds
// can be below zero. The findings of a reply with 20 broken formulas stay under 1 MB. Commit and pass times are printed
// only.
val SeededRealmMeasurement by testSuite {
    // Thousands of resources seed, bind and check for real, twice, which outlasts the default minute.
    test(
        "in a seeded realm twice the size a value edit and an added, renamed or removed element cost no more graph work " +
            "or reply bytes, one unrelated broken formula adds no more, twenty add at most twenty times one, and " +
            "findings stay under 1 MB",
        testConfig = TestConfig.testScope(isEnabled = true, timeout = 30.minutes),
    ) {
        val small = measureSeeded(SeededSize(names = 500, holders = 500, contentHolders = 100))
        val large = measureSeeded(SeededSize(names = 1000, holders = 1000, contentHolders = 200))

        assertSoftly {
            withClue("value edit graph work") { large.valueEdits.medianWork() shouldBeLessThanOrEqual small.valueEdits.medianWork() }
            withClue("added element graph work") { large.added.medianWork() shouldBeLessThanOrEqual small.added.medianWork() }
            withClue("renamed element graph work") { large.renamed.medianWork() shouldBeLessThanOrEqual small.renamed.medianWork() }
            withClue("removed element graph work") { large.removed.medianWork() shouldBeLessThanOrEqual small.removed.medianWork() }
            withClue("value edit reply bytes") {
                large.valueEdits.medianReplyBytes() shouldBeLessThanOrEqual small.valueEdits.medianReplyBytes()
            }
            withClue("added element reply bytes") { large.added.medianReplyBytes() shouldBeLessThanOrEqual small.added.medianReplyBytes() }
            large.twentyBroken.forAll { it.findingBytes shouldBeLessThan 1_000_000 }
            large.extraForOne shouldBeLessThanOrEqual small.extraForOne
            large.extraForTwenty shouldBeLessThanOrEqual 20 * large.extraForOne.coerceAtLeast(0)
        }
    }
}
