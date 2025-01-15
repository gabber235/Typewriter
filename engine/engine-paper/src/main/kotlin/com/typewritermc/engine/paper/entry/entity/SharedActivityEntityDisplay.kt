package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.entries.PropertySupplier
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.utils.config
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap

val entityShowRange by config("entity.show-range", 50.0, "The range at which entities are shown")

class SharedActivityEntityDisplay(
    override val instanceEntryRef: Ref<out EntityInstanceEntry>,
    override val creator: EntityCreator,
    private val activityCreators: ActivityCreator,
    private val suppliers: List<Pair<PropertySupplier<*>, Int>>,
    private val spawnPosition: Position,
) : AudienceFilter(instanceEntryRef), TickableDisplay, ActivityEntityDisplay {
    private var activityManager: ActivityManager<SharedActivityContext>? = null
    private val entities = ConcurrentHashMap<UUID, DisplayEntity>()

    override fun filter(player: Player): Boolean {
        val npcLocation = activityManager?.position ?: return false
        val distance = npcLocation.distanceSqrt(player.location) ?: return false
        return distance <= entityShowRange * entityShowRange
    }

    override fun initialize() {
        super.initialize()
        val context = SharedActivityContext(instanceEntryRef, players)
        activityManager =
            ActivityManager(activityCreators.create(context, spawnPosition.toProperty()))
        activityManager?.initialize(context)
    }

    override fun onPlayerFilterAdded(player: Player) {
        super.onPlayerFilterAdded(player)
        val activityManager = activityManager ?: return
        entities.computeIfAbsent(player.uniqueId) {
            DisplayEntity(player, creator, activityManager, suppliers.toCollectors())
        }
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }

        // This is not an exact solution.
        // When the state is different between players, it might look weird.
        // But there is no real solution to this.
        // So we pick the first entity's state and use to try and keep the state consistent.
        val entityState = entities.values.firstOrNull()?.state ?: EntityState()
        activityManager?.tick(SharedActivityContext(instanceEntryRef, players, entityState))
        entities.values.forEach { it.tick() }
    }

    override fun onPlayerFilterRemoved(player: Player) {
        super.onPlayerFilterRemoved(player)
        entities.remove(player.uniqueId)?.dispose()
    }

    override fun dispose() {
        super.dispose()
        entities.values.forEach { it.dispose() }
        entities.clear()
        activityManager?.dispose(SharedActivityContext(instanceEntryRef, players))
        activityManager = null
    }

    override fun playerSeesEntity(playerId: UUID, entityId: Int): Boolean {
        return entities[playerId]?.contains(entityId) == true
    }

    override fun position(playerId: UUID): Position? = activityManager?.position?.toPosition()
    override fun entityState(playerId: UUID): EntityState = entities[playerId]?.state ?: EntityState()
    override fun canView(playerId: UUID): Boolean = canConsider(playerId)

    override fun entityId(playerId: UUID): Int {
        return entities[playerId]?.entityId ?: 0
    }
}
