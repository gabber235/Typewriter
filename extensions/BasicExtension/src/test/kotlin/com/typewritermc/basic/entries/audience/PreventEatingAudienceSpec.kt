package com.typewritermc.basic.entries.audience

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.Material
import org.bukkit.event.player.PlayerItemConsumeEvent
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemStack
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock

class PreventEatingAudienceSpec : FunSpec() {
    private lateinit var server: ServerMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            startAudienceKoin()
        }

        afterSpec {
            stopAudienceKoin()
            MockBukkit.unmock()
        }

        test("a player in the audience cannot eat") {
            val player = server.addPlayer()
            val display = PreventEatingAudienceDisplay().activeWith(player)

            val event = PlayerItemConsumeEvent(player, ItemStack(Material.BREAD), EquipmentSlot.HAND)
            display.onConsume(event)

            event.isCancelled shouldBe true
        }

        test("a player outside the audience can still eat") {
            val member = server.addPlayer()
            val outsider = server.addPlayer()
            val display = PreventEatingAudienceDisplay().activeWith(member)

            val event = PlayerItemConsumeEvent(outsider, ItemStack(Material.BREAD), EquipmentSlot.HAND)
            display.onConsume(event)

            event.isCancelled shouldBe false
        }
    }
}
