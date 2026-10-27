package com.typewritermc.realm.operation

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.PlacementAnchor
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val GraphGroupPlacementTest by testSuite {
    test("empty destinations honor the anchor and preserve group geometry") {
        val group = listOf(GraphPlacement(10, 5, 3, 2), GraphPlacement(16, 8, 2, 4))
        val placed = GraphGroupPlacement.place(group, emptyList(), PlacementAnchor(0.0, 0.0))
        placed[1].x - placed[0].x shouldBe 6
        placed[1].y - placed[0].y shouldBe 3
        placed.map { it.width to it.height } shouldBe group.map { it.width to it.height }
        placed shouldBe listOf(GraphPlacement(-4, -3, 3, 2), GraphPlacement(2, 0, 2, 4))
    }

    test("copies sharing an existing graph move as one group to free space") {
        val group = listOf(GraphPlacement(0, 0, 3, 2), GraphPlacement(5, 1, 2, 2))
        val obstacles = group + GraphPlacement(-4, -2, 3, 6)
        val placed = GraphGroupPlacement.place(group, obstacles, null)
        placed.all { copy -> obstacles.none { copy.intersectsWithGap(it) } } shouldBe true
        placed[1].x - placed[0].x shouldBe 5
        placed[1].y - placed[0].y shouldBe 1
        GraphGroupPlacement.place(group, obstacles, null) shouldBe placed
    }

    test("a group inside a huge obstacle lands just past its nearest edge, the same way every time") {
        val obstacle = GraphPlacement(-1_000_000, -1_000_000, 2_000_000, 2_000_000)
        val placed = GraphGroupPlacement.place(listOf(GraphPlacement()), listOf(obstacle), null)
        placed shouldBe listOf(GraphPlacement(1_000_001, 0, 1, 1))
        GraphGroupPlacement.place(listOf(GraphPlacement()), listOf(obstacle), null) shouldBe placed
    }

    test("placement near integer limits stays representable") {
        val obstacle = GraphPlacement(Int.MAX_VALUE - 2, 0, 2, 2)
        val placed = GraphGroupPlacement.place(listOf(obstacle), listOf(obstacle), null).single()
        placed.intersectsWithGap(obstacle) shouldBe false
    }
}
