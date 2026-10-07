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
import org.bukkit.event.entity.EntityDamageByEntityEvent
import org.bukkit.event.entity.EntityDamageEvent
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional
import kotlin.reflect.KClass

class DamagePrecedenceSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("damage-precedence")
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
            val half: Double = 5.0,
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
            override fun buildShape(): Shape = CuboidShape(half, half, half)
        }

        /** A hub at the origin (priority 0) and an arena inside it (priority 10). */
        fun index(
            hubFlags: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>,
            arenaFlags: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>,
        ): RegionFlagIndex {
            val coreWorld = CoreWorld(world.uid.toString())
            val hubEntry = TestRegion(id = "hub", origin = ConstVar(Position(coreWorld, 0.0, 64.0, 0.0)), half = 30.0)
            val arenaEntry = TestRegion(id = "arena", origin = ConstVar(Position(coreWorld, 0.0, 64.0, 0.0)), half = 5.0)
            val hubTracker = RegionTracker(null, hubEntry).also { it.refresh() }
            val arenaTracker = RegionTracker(null, arenaEntry).also { it.refresh() }
            return RegionFlagIndex(
                listOf(
                    FlaggedRegion(hubEntry, 0, 0, hubFlags, hubTracker, hubTracker.cachedAabb),
                    FlaggedRegion(arenaEntry, 10, 1, arenaFlags, arenaTracker, arenaTracker.cachedAabb),
                ),
                engine = null,
            )
        }

        test("an arena that allows PvP beats a hub that denies all player damage") {
            val index = index(
                hubFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false))
                ),
                arenaFlags = mapOf(PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(true))),
            )
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val event = EntityDamageByEntityEvent(
                attacker, victim, EntityDamageEvent.DamageCause.ENTITY_ATTACK, 4.0,
            )
            CombatModifierHandler(index).onDamage(event)

            event.isCancelled shouldBe false
        }

        test("a hub that denies all player damage still stops fall damage in the arena") {
            val index = index(
                hubFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false))
                ),
                arenaFlags = mapOf(PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(true))),
            )
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val event = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FALL, 6.0)
            CombatModifierHandler(index).onDamage(event)

            event.isCancelled shouldBe true
        }

        test("an arena that denies all player damage beats a hub that allows PvP") {
            val index = index(
                hubFlags = mapOf(PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(true))),
                arenaFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false))
                ),
            )
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val event = EntityDamageByEntityEvent(
                attacker, victim, EntityDamageEvent.DamageCause.ENTITY_ATTACK, 4.0,
            )
            CombatModifierHandler(index).onDamage(event)

            event.isCancelled shouldBe true
        }

        test("one region holding both flags lets the specific one win") {
            val index = index(
                hubFlags = emptyMap(),
                arenaFlags = mapOf(
                    PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(true)),
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false)),
                ),
            )
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val pvpEvent = EntityDamageByEntityEvent(
                attacker, victim, EntityDamageEvent.DamageCause.ENTITY_ATTACK, 4.0,
            )
            CombatModifierHandler(index).onDamage(pvpEvent)
            pvpEvent.isCancelled shouldBe false

            val fallEvent = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FALL, 6.0)
            CombatModifierHandler(index).onDamage(fallEvent)
            fallEvent.isCancelled shouldBe true
        }

        test("a cause list narrows the flag to the causes it names") {
            val index = index(
                hubFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(
                        allowed = ConstVar(false),
                        causes = listOf(EntityDamageEvent.DamageCause.FALL),
                    )
                ),
                arenaFlags = emptyMap(),
            )
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val fall = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FALL, 6.0)
            CombatModifierHandler(index).onDamage(fall)
            fall.isCancelled shouldBe true

            val fire = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FIRE, 2.0)
            CombatModifierHandler(index).onDamage(fire)
            fire.isCancelled shouldBe false
        }

        test("damage a player set in motion is that player's doing, not a mob's") {
            val index = index(
                hubFlags = emptyMap(),
                arenaFlags = mapOf(
                    PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(false)),
                    MobDamageModifierEntry::class to MobDamageModifierEntry(allowed = ConstVar(true)),
                ),
            )
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            // TNT is not a projectile, so matching on Projectile alone let a player kill in a
            // region that denies PvP by priming a block of it instead of swinging.
            val tnt = world.spawn(world.getBlockAt(2, 64, 2).location, org.bukkit.entity.TNTPrimed::class.java)
            tnt.source = attacker

            val event = EntityDamageByEntityEvent(
                tnt, victim, EntityDamageEvent.DamageCause.ENTITY_EXPLOSION,
                org.bukkit.damage.DamageSource.builder(org.bukkit.damage.DamageType.EXPLOSION)
                    .withDirectEntity(tnt)
                    .withCausingEntity(attacker)
                    .build(),
                4.0,
            )
            CombatModifierHandler(index).onDamage(event)

            event.isCancelled shouldBe true
        }

        test("a narrow flag on top of a blanket one defers to it instead of switching it off") {
            // The parkour box wants fall damage back, and says nothing about anything else. It
            // must not take lava, fire and explosions out of the hub's safe zone with it.
            val index = index(
                hubFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false))
                ),
                arenaFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(
                        allowed = ConstVar(true),
                        causes = listOf(EntityDamageEvent.DamageCause.FALL),
                    )
                ),
            )
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val lava = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.LAVA, 4.0)
            CombatModifierHandler(index).onDamage(lava)
            lava.isCancelled shouldBe true

            val fall = EntityDamageEvent(victim, EntityDamageEvent.DamageCause.FALL, 6.0)
            CombatModifierHandler(index).onDamage(fall)
            fall.isCancelled shouldBe false
        }

        test("machinery nobody owns is still PvP, not a mob") {
            // Vanilla only records an owner for TNT a player lit by hand, so a cannon fired by a
            // lever arrives with none. A truce zone carrying only PvP has to cover it anyway.
            val index = index(
                hubFlags = mapOf(PvpModifierEntry::class to PvpModifierEntry(allowed = ConstVar(false))),
                arenaFlags = emptyMap(),
            )
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)
            val tnt = world.spawn(world.getBlockAt(2, 64, 2).location, org.bukkit.entity.TNTPrimed::class.java)

            val event = EntityDamageByEntityEvent(
                tnt, victim, EntityDamageEvent.DamageCause.ENTITY_EXPLOSION, 4.0,
            )
            CombatModifierHandler(index).onDamage(event)

            event.isCancelled shouldBe true
        }

        test("with nobody carrying PvP, the blunt flag still stops a fight") {
            val index = index(
                hubFlags = mapOf(
                    PlayerDamageModifierEntry::class to PlayerDamageModifierEntry(allowed = ConstVar(false))
                ),
                arenaFlags = emptyMap(),
            )
            val victim = server.addPlayer()
            val attacker = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val event = EntityDamageByEntityEvent(
                attacker, victim, EntityDamageEvent.DamageCause.ENTITY_ATTACK, 4.0,
            )
            CombatModifierHandler(index).onDamage(event)

            event.isCancelled shouldBe true
        }
    }
}
