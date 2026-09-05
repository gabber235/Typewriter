package com.typewritermc.visibility.packet

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock

class ServerSideFlagsSpec : FunSpec({
    lateinit var server: ServerMock

    beforeTest {
        server = MockBukkit.mock()
        server.addSimpleWorld("world")
    }

    afterTest {
        MockBukkit.unmock()
    }

    test("a plain player has no flags") {
        val player = server.addPlayer()

        serverSideEntityFlags(player) shouldBe 0
    }

    test("sneaking and sprinting set their bits") {
        val player = server.addPlayer()
        player.isSneaking = true
        player.isSprinting = true

        serverSideEntityFlags(player) shouldBe (EntityFlag.SNEAKING or EntityFlag.SPRINTING)
    }

    test("fire glowing and invisibility set their bits") {
        val player = server.addPlayer()
        player.fireTicks = 100
        player.isGlowing = true
        player.isInvisible = true

        serverSideEntityFlags(player) shouldBe
                (EntityFlag.ON_FIRE or EntityFlag.GLOWING or EntityFlag.INVISIBLE)
    }

    test("swimming and gliding set their bits") {
        val player = server.addPlayer()
        player.isSwimming = true
        player.isGliding = true

        serverSideEntityFlags(player) shouldBe (EntityFlag.SWIMMING or EntityFlag.GLIDING)
    }

    test("the flags byte keeps every bit a synthetic packet has to carry") {
        val player = server.addPlayer()
        player.fireTicks = 100
        player.isSneaking = true
        player.isSprinting = true
        player.isSwimming = true
        player.isInvisible = true
        player.isGlowing = true
        player.isGliding = true

        serverSideEntityFlags(player) shouldBe 0xFB
    }
})
