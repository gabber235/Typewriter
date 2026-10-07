package com.typewritermc.basic.entries.audience

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.entity.EntityType
import org.bukkit.event.entity.EntityDamageEvent
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock

class PreventDamageAudienceSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("damage")
            startAudienceKoin()
        }

        afterSpec {
            stopAudienceKoin()
            MockBukkit.unmock()
        }

        test("a player in the audience takes no damage") {
            val player = server.addPlayer()
            val display = PreventDamageAudienceDisplay().activeWith(player)

            val event = EntityDamageEvent(player, EntityDamageEvent.DamageCause.FALL, 6.0)
            display.onDamage(event)

            event.isCancelled shouldBe true
        }

        test("a player outside the audience still takes damage") {
            val member = server.addPlayer()
            val outsider = server.addPlayer()
            val display = PreventDamageAudienceDisplay().activeWith(member)

            val event = EntityDamageEvent(outsider, EntityDamageEvent.DamageCause.FALL, 6.0)
            display.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("a mob standing next to a protected player still takes damage") {
            val player = server.addPlayer()
            val display = PreventDamageAudienceDisplay().activeWith(player)
            val zombie = world.spawnEntity(world.spawnLocation, EntityType.ZOMBIE)

            val event = EntityDamageEvent(zombie, EntityDamageEvent.DamageCause.FALL, 6.0)
            display.onDamage(event)

            event.isCancelled shouldBe false
        }
    }
}
