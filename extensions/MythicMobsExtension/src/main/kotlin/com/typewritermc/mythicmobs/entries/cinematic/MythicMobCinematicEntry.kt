package com.typewritermc.mythicmobs.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.utils.toBukkitLocation
import io.lumine.mythic.api.mobs.GenericCaster
import io.lumine.mythic.bukkit.BukkitAdapter
import io.lumine.mythic.bukkit.MythicBukkit
import io.lumine.mythic.core.mobs.ActiveMob
import io.lumine.mythic.core.skills.SkillMetadataImpl
import io.lumine.mythic.core.skills.SkillTriggers
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player

@Entry("mythicmob_cinematic", "Spawn a MythicMob during a cinematic", Colors.PURPLE, "fa6-solid:dragon")
/**
 * The `Spawn MythicMob Cinematic` cinematic entry spawns a MythicMob during a cinematic.
 *
 * ## How could this be used?
 *
 * This can be used to animate a MythicMob spawning during a cinematic.
 */
class MythicMobCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(Colors.PURPLE, "fa6-solid:dragon")
    val segments: List<MythicMobSegment> = emptyList(),
) : CinematicEntry {
    override fun create(player: Player): CinematicAction {
        return MobCinematicAction(player, this)
    }
}

data class MythicMobSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    @Placeholder
    val mobName: Var<String> = ConstVar(""),
    @WithRotation
    val location: Var<Position> = ConstVar(Position.ORIGIN),
) : Segment

class MobCinematicAction(
    private val player: Player,
    entry: MythicMobCinematicEntry,
) : SimpleCinematicAction<MythicMobSegment>() {
    override val segments: List<MythicMobSegment> = entry.segments

    private var mob: ActiveMob? = null

    override suspend fun startSegment(segment: MythicMobSegment) {
        super.startSegment(segment)

        Dispatchers.Sync.switchContext {
            val mob =
                MythicBukkit.inst().mobManager.spawnMob(
                    segment.mobName.get(player).parsePlaceholders(player),
                    segment.location.get(player).toBukkitLocation()
                )
            this@MobCinematicAction.mob = mob
            val hideMechanic = MythicBukkit.inst().skillManager.getMechanic("hide")

            val targets =
                server.onlinePlayers.filter { it.uniqueId != player.uniqueId }.map { BukkitAdapter.adapt(it) }.toSet()

            val skillMeta = SkillMetadataImpl(
                SkillTriggers.API,
                GenericCaster(mob.entity),
                mob.entity,
                mob.location,
                targets,
                null,
                1f
            )

            hideMechanic.execute(skillMeta)
        }
    }

    override suspend fun stopSegment(segment: MythicMobSegment) {
        super.stopSegment(segment)

        mob?.let {
            it.despawn()
            mob = null
        }
    }
}