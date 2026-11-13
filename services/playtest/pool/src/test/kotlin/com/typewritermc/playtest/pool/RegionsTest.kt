package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message.Region
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.ints.shouldBeGreaterThanOrEqual
import io.kotest.matchers.ints.shouldBeLessThanOrEqual
import kotlin.math.abs
import kotlin.math.max

val RegionsTest by testSuite {
    test("every region lies at least the spacing from every other region and from the spawn where players join") {
        val regions = Regions()
        val all = listOf(Region(0, 0)) + (1..500).map { regions.next() }

        val closest =
            all.indices.minOf { i ->
                (i + 1 until all.size).minOfOrNull { j -> max(abs(all[i].x - all[j].x), abs(all[i].z - all[j].z)) } ?: Int.MAX_VALUE
            }

        closest shouldBeGreaterThanOrEqual Region.SPACING
    }

    test("regions stay close to the spawn: 500 attempts fit within 12 spacings of it") {
        val regions = Regions()

        val farthest = (1..500).map { regions.next() }.maxOf { max(abs(it.x), abs(it.z)) }

        farthest shouldBeLessThanOrEqual 12 * Region.SPACING
    }
}
