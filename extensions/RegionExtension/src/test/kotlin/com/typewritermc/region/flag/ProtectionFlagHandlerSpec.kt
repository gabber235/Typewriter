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
import com.typewritermc.region.entries.modifier.BucketModifierEntry
import com.typewritermc.region.entries.modifier.BucketModifierHandler
import com.typewritermc.region.entries.modifier.EntityDamageModifierEntry
import com.typewritermc.region.entries.modifier.EntityDamageModifierHandler
import com.typewritermc.region.entries.modifier.IgniteModifierEntry
import com.typewritermc.region.entries.modifier.IgniteModifierHandler
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.entries.modifier.TrampleModifierEntry
import com.typewritermc.region.entries.modifier.TrampleModifierHandler
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.Material
import org.bukkit.block.BlockFace
import org.bukkit.block.data.Directional
import org.bukkit.entity.EntityType
import org.bukkit.event.block.Action
import org.bukkit.event.block.BlockDispenseEvent
import org.bukkit.event.block.BlockIgniteEvent
import org.bukkit.event.entity.EntityDamageByEntityEvent
import org.bukkit.event.entity.EntityDamageEvent
import org.bukkit.event.player.PlayerBucketEmptyEvent
import org.bukkit.event.player.PlayerBucketFillEvent
import org.bukkit.event.player.PlayerInteractEvent
import org.bukkit.inventory.EquipmentSlot
import org.bukkit.inventory.ItemStack
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional
import kotlin.reflect.KClass

class ProtectionFlagHandlerSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("protection")
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

        test("emptying a bucket inside the region is stopped") {
            val handler = BucketModifierHandler(
                indexWith(mapOf(BucketModifierEntry::class to BucketModifierEntry(allowed = ConstVar(false))))
            )
            val player = server.addPlayer()

            val event = PlayerBucketEmptyEvent(
                player,
                world.getBlockAt(2, 64, 2),
                world.getBlockAt(2, 63, 2),
                BlockFace.UP,
                Material.LAVA_BUCKET,
                ItemStack(Material.LAVA_BUCKET),
                EquipmentSlot.HAND,
            )
            handler.onEmpty(event)

            event.isCancelled shouldBe true
        }

        test("filling a bucket inside the region is stopped, and it is a different handler list") {
            val handler = BucketModifierHandler(
                indexWith(mapOf(BucketModifierEntry::class to BucketModifierEntry(allowed = ConstVar(false))))
            )
            val player = server.addPlayer()

            val event = PlayerBucketFillEvent(
                player,
                world.getBlockAt(2, 64, 2),
                world.getBlockAt(2, 63, 2),
                BlockFace.UP,
                Material.BUCKET,
                ItemStack(Material.BUCKET),
                EquipmentSlot.HAND,
            )
            handler.onFill(event)

            event.isCancelled shouldBe true
        }

        test("a bucket outside the region is left alone") {
            val handler = BucketModifierHandler(
                indexWith(mapOf(BucketModifierEntry::class to BucketModifierEntry(allowed = ConstVar(false))))
            )
            val player = server.addPlayer()

            val event = PlayerBucketEmptyEvent(
                player,
                world.getBlockAt(50, 64, 50),
                world.getBlockAt(50, 63, 50),
                BlockFace.UP,
                Material.LAVA_BUCKET,
                ItemStack(Material.LAVA_BUCKET),
                EquipmentSlot.HAND,
            )
            handler.onEmpty(event)

            event.isCancelled shouldBe false
        }

        test("a dispenser outside the region cannot pour a mob bucket into it") {
            val handler = BucketModifierHandler(
                indexWith(mapOf(BucketModifierEntry::class to BucketModifierEntry(allowed = ConstVar(false))))
            )
            val dispenser = world.getBlockAt(5, 64, 2)
            dispenser.type = Material.DISPENSER
            dispenser.blockData = (dispenser.blockData as Directional).apply { facing = BlockFace.WEST }

            val event = BlockDispenseEvent(dispenser, ItemStack(Material.AXOLOTL_BUCKET), org.bukkit.util.Vector())
            handler.onDispense(event)

            event.isCancelled shouldBe true
        }

        test("breaking an item frame inside the region is stopped") {
            val handler = EntityDamageModifierHandler(
                indexWith(
                    mapOf(EntityDamageModifierEntry::class to EntityDamageModifierEntry(allowed = ConstVar(false)))
                )
            )
            val player = server.addPlayer()
            val frame = world.spawnEntity(world.getBlockAt(2, 64, 2).location, EntityType.ITEM_FRAME)

            val event = EntityDamageByEntityEvent(
                player, frame, EntityDamageEvent.DamageCause.ENTITY_ATTACK, 1.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe true
        }

        test("hurting a player is not the entity damage flag's business") {
            val handler = EntityDamageModifierHandler(
                indexWith(
                    mapOf(EntityDamageModifierEntry::class to EntityDamageModifierEntry(allowed = ConstVar(false)))
                )
            )
            val attacker = server.addPlayer()
            val victim = server.addPlayer()
            victim.teleport(world.getBlockAt(2, 64, 2).location)

            val event = EntityDamageByEntityEvent(
                attacker, victim, EntityDamageEvent.DamageCause.ENTITY_ATTACK, 4.0,
            )
            handler.onDamage(event)

            event.isCancelled shouldBe false
        }

        test("trampling farmland inside the region is stopped") {
            val handler = TrampleModifierHandler(
                indexWith(mapOf(TrampleModifierEntry::class to TrampleModifierEntry(allowed = ConstVar(false))))
            )
            val player = server.addPlayer()
            val farmland = world.getBlockAt(2, 64, 2)
            farmland.type = Material.FARMLAND

            val event = PlayerInteractEvent(
                player, Action.PHYSICAL, ItemStack(Material.AIR), farmland, BlockFace.UP,
            )
            handler.onPhysical(event)

            event.isCancelled shouldBe true
        }

        test("a pressure plate inside the region still works") {
            val handler = TrampleModifierHandler(
                indexWith(mapOf(TrampleModifierEntry::class to TrampleModifierEntry(allowed = ConstVar(false))))
            )
            val player = server.addPlayer()
            val plate = world.getBlockAt(2, 64, 2)
            plate.type = Material.STONE_PRESSURE_PLATE

            val event = PlayerInteractEvent(
                player, Action.PHYSICAL, ItemStack(Material.AIR), plate, BlockFace.UP,
            )
            handler.onPhysical(event)

            event.isCancelled shouldBe false
        }

        test("lighting a fire inside the region is stopped") {
            val handler = IgniteModifierHandler(
                indexWith(mapOf(IgniteModifierEntry::class to IgniteModifierEntry(allowed = ConstVar(false))))
            )
            val player = server.addPlayer()

            val event = BlockIgniteEvent(
                world.getBlockAt(2, 64, 2),
                BlockIgniteEvent.IgniteCause.FLINT_AND_STEEL,
                player,
            )
            handler.onIgnite(event)

            event.isCancelled shouldBe true
        }

        test("fire spreading is not the ignite flag's business") {
            val handler = IgniteModifierHandler(
                indexWith(mapOf(IgniteModifierEntry::class to IgniteModifierEntry(allowed = ConstVar(false))))
            )

            val event = BlockIgniteEvent(
                world.getBlockAt(2, 64, 2),
                BlockIgniteEvent.IgniteCause.SPREAD,
                null as org.bukkit.entity.Entity?,
            )
            handler.onIgnite(event)

            event.isCancelled shouldBe false
        }
    }
}
