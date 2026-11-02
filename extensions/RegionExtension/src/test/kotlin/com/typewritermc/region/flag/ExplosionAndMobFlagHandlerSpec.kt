package com.typewritermc.region.flag

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World as CoreWorld
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.entries.modifier.ExplosionModifierEntry
import com.typewritermc.region.entries.modifier.ExplosionModifierHandler
import com.typewritermc.region.entries.modifier.MobGriefModifierEntry
import com.typewritermc.region.entries.modifier.MobGriefModifierHandler
import com.typewritermc.region.entries.modifier.MobSpawnModifierEntry
import com.typewritermc.region.entries.modifier.MobSpawnModifierHandler
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.shape.CuboidShape
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import org.bukkit.ExplosionResult
import org.bukkit.Material
import org.bukkit.block.Block
import org.bukkit.entity.EntityType
import org.bukkit.entity.LivingEntity
import org.bukkit.event.entity.CreatureSpawnEvent
import org.bukkit.event.entity.EntityChangeBlockEvent
import org.bukkit.event.entity.EntityExplodeEvent
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.Optional
import kotlin.reflect.KClass

class ExplosionAndMobFlagHandlerSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    init {
        beforeSpec {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("explosions")
        }

        afterSpec { MockBukkit.unmock() }

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
                id = "town",
                origin = ConstVar(Position(CoreWorld(world.uid.toString()), 0.0, 64.0, 0.0)),
            )
            val tracker = RegionTracker(null, entry)
            tracker.refresh()
            val region = FlaggedRegion(entry, 0, 0, flags, tracker, tracker.cachedAabb)
            return RegionFlagIndex(listOf(region), engine = null)
        }

        test("an explosion spares the blocks inside the region and keeps the rest") {
            val index = indexWith(mapOf(ExplosionModifierEntry::class to ExplosionModifierEntry(allowed = false)))
            val handler = ExplosionModifierHandler(index)

            val inside = world.getBlockAt(2, 64, 2)
            val outside = world.getBlockAt(40, 64, 40)
            val creeper = world.spawnEntity(world.getBlockAt(20, 64, 20).location, EntityType.CREEPER)
            val event = EntityExplodeEvent(
                creeper,
                creeper.location,
                mutableListOf<Block>(inside, outside),
                1.0f,
                ExplosionResult.DESTROY,
            )
            handler.onEntityExplode(event)

            event.isCancelled shouldBe false
            event.blockList() shouldContainExactly listOf(outside)
        }

        test("an explosion that touches nothing protected is left alone") {
            val index = indexWith(mapOf(ExplosionModifierEntry::class to ExplosionModifierEntry(allowed = false)))
            val handler = ExplosionModifierHandler(index)

            val outside = world.getBlockAt(40, 64, 40)
            val creeper = world.spawnEntity(world.getBlockAt(41, 64, 41).location, EntityType.CREEPER)
            val event = EntityExplodeEvent(
                creeper,
                creeper.location,
                mutableListOf<Block>(outside),
                1.0f,
                ExplosionResult.DESTROY,
            )
            handler.onEntityExplode(event)

            event.blockList() shouldContainExactly listOf(outside)
        }

        test("a mob spawning inside the region is cancelled") {
            val index = indexWith(mapOf(MobSpawnModifierEntry::class to MobSpawnModifierEntry(allowed = false)))
            val handler = MobSpawnModifierHandler(index)

            val zombie = world.spawnEntity(world.getBlockAt(2, 64, 2).location, EntityType.ZOMBIE) as LivingEntity
            val event = CreatureSpawnEvent(zombie, CreatureSpawnEvent.SpawnReason.NATURAL)
            handler.onSpawn(event)

            event.isCancelled shouldBe true
        }

        test("a mob spawning outside the region is allowed") {
            val index = indexWith(mapOf(MobSpawnModifierEntry::class to MobSpawnModifierEntry(allowed = false)))
            val handler = MobSpawnModifierHandler(index)

            val zombie = world.spawnEntity(world.getBlockAt(50, 64, 50).location, EntityType.ZOMBIE) as LivingEntity
            val event = CreatureSpawnEvent(zombie, CreatureSpawnEvent.SpawnReason.NATURAL)
            handler.onSpawn(event)

            event.isCancelled shouldBe false
        }

        test("an enderman changing a block inside a denying region is cancelled") {
            val index = indexWith(mapOf(MobGriefModifierEntry::class to MobGriefModifierEntry(allowed = false)))
            val handler = MobGriefModifierHandler(index)

            val block = world.getBlockAt(2, 64, 2)
            val enderman = world.spawnEntity(world.getBlockAt(2, 65, 2).location, EntityType.ENDERMAN)
            val event = EntityChangeBlockEvent(enderman, block, Material.AIR.createBlockData())
            handler.onChangeBlock(event)

            event.isCancelled shouldBe true
        }

        test("sand settling inside the region is the build flag's business, not this one's") {
            val index = indexWith(mapOf(MobGriefModifierEntry::class to MobGriefModifierEntry(allowed = false)))
            val handler = MobGriefModifierHandler(index)

            val block = world.getBlockAt(2, 64, 2)
            val sand = world.spawnFallingBlock(world.getBlockAt(2, 70, 2).location, Material.SAND.createBlockData())
            val event = EntityChangeBlockEvent(sand, block, Material.SAND.createBlockData())
            handler.onChangeBlock(event)

            event.isCancelled shouldBe false
        }

        test("a player changing a block inside the same region is not this flag's business") {
            val index = indexWith(mapOf(MobGriefModifierEntry::class to MobGriefModifierEntry(allowed = false)))
            val handler = MobGriefModifierHandler(index)

            val block = world.getBlockAt(2, 64, 2)
            val player = server.addPlayer()
            val event = EntityChangeBlockEvent(player, block, Material.AIR.createBlockData())
            handler.onChangeBlock(event)

            event.isCancelled shouldBe false
        }
    }
}
