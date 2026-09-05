package com.typewritermc.basic.entries.audience

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.Material
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.block.BlockPlaceEvent
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemStack
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock

class PreventBlockEditingAudienceSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("blocks")
            startAudienceKoin()
        }

        afterSpec {
            stopAudienceKoin()
            MockBukkit.unmock()
        }

        test("a player in the audience cannot break a block") {
            val player = server.addPlayer()
            val display = PreventBlockBreakAudienceDisplay().activeWith(player)

            val event = BlockBreakEvent(world.getBlockAt(0, 64, 0), player)
            display.onBreak(event)

            event.isCancelled shouldBe true
        }

        test("a player outside the audience can still break a block") {
            val member = server.addPlayer()
            val outsider = server.addPlayer()
            val display = PreventBlockBreakAudienceDisplay().activeWith(member)

            val event = BlockBreakEvent(world.getBlockAt(0, 64, 0), outsider)
            display.onBreak(event)

            event.isCancelled shouldBe false
        }

        test("a player in the audience cannot place a block") {
            val player = server.addPlayer()
            val display = PreventBlockPlaceAudienceDisplay().activeWith(player)

            val placed = world.getBlockAt(0, 64, 0)
            val against = world.getBlockAt(0, 63, 0)
            val event = BlockPlaceEvent(
                placed,
                placed.state,
                against,
                ItemStack(Material.STONE),
                player,
                true,
                EquipmentSlot.HAND,
            )
            display.onPlace(event)

            event.isCancelled shouldBe true
        }

        test("a player outside the audience can still place a block") {
            val member = server.addPlayer()
            val outsider = server.addPlayer()
            val display = PreventBlockPlaceAudienceDisplay().activeWith(member)

            val placed = world.getBlockAt(0, 64, 0)
            val against = world.getBlockAt(0, 63, 0)
            val event = BlockPlaceEvent(
                placed,
                placed.state,
                against,
                ItemStack(Material.STONE),
                outsider,
                true,
                EquipmentSlot.HAND,
            )
            display.onPlace(event)

            event.isCancelled shouldBe false
        }
    }
}
