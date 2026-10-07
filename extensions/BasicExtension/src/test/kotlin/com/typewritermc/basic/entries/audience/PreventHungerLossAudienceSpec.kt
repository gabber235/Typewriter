package com.typewritermc.basic.entries.audience

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.event.entity.FoodLevelChangeEvent
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock

class PreventHungerLossAudienceSpec : FunSpec() {
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

        test("a player in the audience never loses hunger") {
            val player = server.addPlayer()
            player.foodLevel = 20
            val display = PreventHungerLossAudienceDisplay().activeWith(player)

            val event = FoodLevelChangeEvent(player, 18)
            display.onFoodLevelChange(event)

            event.isCancelled shouldBe true
        }

        test("a player in the audience can still gain hunger by eating") {
            val player = server.addPlayer()
            player.foodLevel = 12
            val display = PreventHungerLossAudienceDisplay().activeWith(player)

            val event = FoodLevelChangeEvent(player, 18)
            display.onFoodLevelChange(event)

            event.isCancelled shouldBe false
        }

        test("a player outside the audience still loses hunger") {
            val member = server.addPlayer()
            val outsider = server.addPlayer()
            outsider.foodLevel = 20
            val display = PreventHungerLossAudienceDisplay().activeWith(member)

            val event = FoodLevelChangeEvent(outsider, 18)
            display.onFoodLevelChange(event)

            event.isCancelled shouldBe false
        }
    }
}
