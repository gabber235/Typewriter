package com.typewritermc.region.flag

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World as CoreWorld
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.CombatModifierHandler
import com.typewritermc.region.entries.modifier.MobDamageModifierEntry
import com.typewritermc.region.entries.modifier.PlayerDamageModifierEntry
import com.typewritermc.region.entries.modifier.PvpModifierEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.entity.EntityType
import org.bukkit.event.entity.EntityDamageEvent
import org.bukkit.event.entity.EntityDamageByEntityEvent
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional
import kotlin.reflect.KClass

class CombatFlagHandlerSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("combat")
            startKoin { modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } }) }
        }

        afterSpec {
            stopKoin()
            MockBukkit.unmock()
        }

        class TestRegion(
            override val id: String,
            override val name: String = id,
            override val origin: Var<Position>,
            override val modifiers: List<Ref<out RegionModifierEntry>> = emptyList(),
            override val priorityOverride: Optional<Int> = Optional.empty(),
            override val offset: Var<Vector> = RegionDefaults.OFFSET,
            override val yaw: Var<Float> = RegionDefaults.YAW,
            override val pitch: Var<Float> = RegionDefaults.PITCH,
            override val roll: Var<Float> = RegionDefaults.ROLL,
            override val rotateWithOrigin: Boolean = false,
            override val color: Color = RegionDefaults.COLOR,
            override val refreshRateTicks: Int = RegionDefaults.REFRESH_RATE_TICKS,
        ) : RegionDefinitionEntry {
            override fun buildShape(): Shape = CuboidShape(5.0, 5.0, 5.0)
        }

        fun indexWith(flags: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>): RegionFlagIndex {
            val entry = TestRegion(
                id = "safe-zone",
                origin = ConstVar(Position(CoreWorld(world.uid.toString()), 0.0, 64.0, 0.0)),
            )
            val tracker = RegionTracker(null, entry)
            tracker.refresh()
            val region = FlaggedRegion(entry, 0, 0, flags, tracker, tracker.cachedAabb)
            return RegionFlagIndex(listOf(region), engine = null)
        }

        fun noPvpIndex() = indexWith(
            mapOf(PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(false)))
        )

        fun noMobDamageIndex() = indexWith(
            mapOf(MobDamageModifierEntry::class to MobDamageModifierEntry(allowed = ConstVar(false)))
        )

        fun noPlayerDamageIndex() = indexWith(
            mapOf(PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false)))
        )

        test("a player attacked inside the region is protected") {
            val handler = CombatModifierHandler(noPvpIndex())
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)
            attacker.teleport(world.getBlockAt(3, 64, 3).location)

            val event = EntityDamageByEntityEvent(
                attacker,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe true
        }

        test("an attacker outside the region cannot shoot in: the victim's location decides") {
            val handler = CombatModifierHandler(noPvpIndex())
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)
            attacker.teleport(world.getBlockAt(60, 64, 60).location)

            val event = EntityDamageByEntityEvent(
                attacker,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe true
        }

        test("a player attacked outside the region is not protected") {
            val handler = CombatModifierHandler(noPvpIndex())
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(60, 64, 60).location)
            attacker.teleport(world.getBlockAt(61, 64, 61).location)

            val event = EntityDamageByEntityEvent(
                attacker,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("a mob attacking a player is not PvP") {
            val handler = CombatModifierHandler(noPvpIndex())
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)
            val zombie = world.spawnEntity(
                world.getBlockAt(3, 64, 3).location,
                org.bukkit.entity.EntityType.ZOMBIE,
            )

            val event = EntityDamageByEntityEvent(
                zombie,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("a zombie hurting a player inside a denying region is cancelled") {
            val handler = CombatModifierHandler(noMobDamageIndex())
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)
            val zombie = world.spawnEntity(world.getBlockAt(3, 64, 3).location, EntityType.ZOMBIE)

            val event = EntityDamageByEntityEvent(
                zombie,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe true
        }

        test("a player hurting a player inside the same region is not this handler's business") {
            val handler = CombatModifierHandler(noMobDamageIndex())
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)
            attacker.teleport(world.getBlockAt(3, 64, 3).location)

            val event = EntityDamageByEntityEvent(
                attacker,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("a zombie hurting a player outside the region is not cancelled") {
            val handler = CombatModifierHandler(noMobDamageIndex())
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(60, 64, 60).location)
            val zombie = world.spawnEntity(world.getBlockAt(61, 64, 61).location, EntityType.ZOMBIE)

            val event = EntityDamageByEntityEvent(
                zombie,
                victim,
                EntityDamageEvent.DamageCause.ENTITY_ATTACK,
                4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("fall damage to a player inside a denying region is cancelled") {
            val handler = CombatModifierHandler(noPlayerDamageIndex())
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val event = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FALL, 4.0)
            handler.onDamage(event)

            event.isCancelled shouldBe true
        }

        test("fall damage to a player outside the region is not cancelled") {
            val handler = CombatModifierHandler(noPlayerDamageIndex())
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(60, 64, 60).location)

            val event = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FALL, 4.0)
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("damage to a non player entity inside the region is not this flag's business") {
            val handler = CombatModifierHandler(noPlayerDamageIndex())
            val zombie = world.spawnEntity(world.getBlockAt(2, 64, 2).location, EntityType.ZOMBIE)

            val event = EntityDamageEvent(zombie, EntityDamageEvent.DamageCause.FALL, 4.0)
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }
    }
}
