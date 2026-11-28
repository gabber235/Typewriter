package com.typewritermc.playtest.typewriter

import com.typewritermc.loader.api.work.WorkSubject
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import java.util.UUID

/** Work Typewriter runs for its subjects is the work of the Paper players among them. */
val WorkPlayersTest by testSuite {
    val player = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val partner = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("work for Minecraft players is the work of those players") {
        WorkPlayers
            .of(setOf(WorkSubject("minecraft", player.toString()), WorkSubject("minecraft", partner.toString())))
            .shouldNotBeNull() shouldContainExactlyInAnyOrder listOf(player, partner)
    }

    test("work for no subject is the work of no player in particular") {
        WorkPlayers.of(null).shouldBeNull()
    }

    test("work only for subjects that are not Minecraft players is the work of no Paper player") {
        WorkPlayers.of(setOf(WorkSubject("panel", "user-1"))).shouldNotBeNull().shouldBeEmpty()
    }

    test("work for a Minecraft player and a panel user is the work of the player") {
        WorkPlayers
            .of(setOf(WorkSubject("minecraft", player.toString()), WorkSubject("panel", "user-1")))
            .shouldNotBeNull() shouldContainExactlyInAnyOrder listOf(player)
    }
}
