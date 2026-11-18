package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldNotContainAnyOf
import io.kotest.matchers.ints.shouldBeGreaterThanOrEqual
import io.kotest.matchers.ints.shouldBeLessThanOrEqual
import io.kotest.matchers.shouldBe
import skirout.harness.v1.wire.Region
import kotlin.math.abs
import kotlin.math.max

val RegionsTest by testSuite {
    test("every region lies at least the spacing from every other region and from the spawn where players join") {
        val regions = Regions(ahead = 4)
        val all = listOf(Region(x = 0, z = 0)) + (1..500).map { regions.next() }

        val closest =
            all.indices.minOf { i ->
                (i + 1 until all.size).minOfOrNull { j -> max(abs(all[i].x - all[j].x), abs(all[i].z - all[j].z)) } ?: Int.MAX_VALUE
            }

        closest shouldBeGreaterThanOrEqual REGION_SPACING
    }

    test("regions stay close to the spawn: 500 attempts fit within 12 spacings of it") {
        val regions = Regions(ahead = 4)

        val farthest = (1..500).map { regions.next() }.maxOf { max(abs(it.x), abs(it.z)) }

        farthest shouldBeLessThanOrEqual 12 * REGION_SPACING
    }

    test("the regions ahead are the ones the next claims get, in that order") {
        val regions = Regions(ahead = 4)
        val ahead = regions.ahead()

        List(4) { regions.next() } shouldBe ahead
    }

    test("each region handed out moves the lookahead on by one region nobody got yet") {
        val regions = Regions(ahead = 4)
        val before = regions.ahead()

        val got = regions.next()
        val after = regions.ahead()

        after.dropLast(1) shouldBe before.drop(1)
        listOf(after.last()) shouldNotContainAnyOf before + got
    }
}
