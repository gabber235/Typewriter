package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.*
import lirand.api.extensions.server.server
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap

class GroupActivityEntityDisplay(
    override val instanceEntryRef: Ref<out EntityInstanceEntry>,
    override val creator: EntityCreator,
    private val activityCreators: ActivityCreator,
    private val suppliers: List<Pair<PropertySupplier<*>, Int>>,
    private val spawnPosition: Position,
    private val showRange: Var<Double> = ConstVar(entityShowRange),
    private val group: GroupEntry,
) : AudienceFilter(instanceEntryRef), TickableDisplay, ActivityEntityDisplay {
    private val activityManagers = ConcurrentHashMap<GroupId, ActivityManager<in SharedActivityContext>>()
    private val entities = ConcurrentHashMap<UUID, DisplayEntity>()

    /**
     * When nobody can see the entity, but it is still active, there is no way to get the state for the entity.
     * So we just assume that the entity state stays the same.
     */
    private val lastStates = ConcurrentHashMap<GroupId, EntityState>()


    private fun groupViewers(groupId: GroupId): List<Player> {
        return players.filter { group.groupId(it) == groupId }
    }

    override fun filter(player: Player): Boolean {
        val groupId = group.groupId(player) ?: GroupId(player.uniqueId)
        val npcLocation = activityManagers[groupId]?.position ?: return false
        val distance = npcLocation.distanceSqrt(player.location) ?: return false
        val showRange = showRange.get(player)
        return distance <= showRange * showRange
    }

    override fun onPlayerAdd(player: Player) {
        val groupId = group.groupId(player) ?: GroupId(player.uniqueId)
        activityManagers.computeIfAbsent(groupId) {
            val viewers = groupViewers(groupId)
            val context = SharedActivityContext(instanceEntryRef, viewers)
            val activity = activityCreators.create(context, spawnPosition.toProperty())
            val activityManager = ActivityManager(activity)
            activityManager.initialize(context)
            activityManager
        }

        super.onPlayerAdd(player)
    }

    override fun onPlayerFilterAdded(player: Player) {
        super.onPlayerFilterAdded(player)
        val groupId = group.groupId(player) ?: GroupId(player.uniqueId)
        val activityManager = activityManagers[groupId] ?: return
        entities.computeIfAbsent(player.uniqueId) {
            DisplayEntity(player, creator, activityManager, suppliers.toCollectors())
        }
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }

        activityManagers.forEach { (groupId, manager) ->
            val viewers = groupViewers(groupId)

            // This is not an exact solution.
            // When the state is different between players, it might look weird.
            // But there is no real solution to this.
            // So we pick the first entity's state and use to try and keep the state consistent.
            val viewerId = viewers.firstOrNull()?.uniqueId
            val entityStateFromPlayer =
                if (viewerId != null) entities[viewerId]?.state?.also { lastStates[groupId] = it } else null
            val entityState = entityStateFromPlayer ?: lastStates.getOrPut(groupId) { EntityState() }

            val context = SharedActivityContext(instanceEntryRef, viewers, entityState)
            manager.tick(context)
        }

        entities.values.forEach { it.tick() }
    }

    override fun onPlayerFilterRemoved(player: Player) {
        super.onPlayerFilterRemoved(player)
        entities.remove(player.uniqueId)?.dispose()
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        val groupId = group.groupId(player) ?: GroupId(player.uniqueId)
        // If no players are considered for this group, we can remove the activity manager
        if (consideredPlayers.none { groupId == group.groupId(it) }) {
            activityManagers.remove(groupId)?.dispose(SharedActivityContext(instanceEntryRef, emptyList()))
            lastStates.remove(groupId)
        }
    }

    override fun dispose() {
        super.dispose()
        entities.values.forEach { it.dispose() }
        entities.clear()
        activityManagers.forEach { (groupId, manager) ->
            manager.dispose(SharedActivityContext(instanceEntryRef, groupViewers(groupId)))
        }
        activityManagers.clear()
        lastStates.clear()
    }

    override fun playerSeesEntity(playerId: UUID, entityId: Int): Boolean {
        return entities[playerId]?.contains(entityId) == true
    }

    override fun position(playerId: UUID): Position? {
        val player = server.getPlayer(playerId) ?: return null
        val groupId = group.groupId(player) ?: GroupId(player.uniqueId)
        return activityManagers[groupId]?.position?.toPosition()
    }

    override fun entityState(playerId: UUID): EntityState {
        entities[playerId]?.state?.let { return it }
        val player = server.getPlayer(playerId) ?: return EntityState()
        val groupId = group.groupId(player) ?: GroupId(player.uniqueId)
        lastStates[groupId]?.let { return it }
        return EntityState()
    }

    override fun canView(playerId: UUID): Boolean = canConsider(playerId)
    override fun isSpawnedIn(playerId: UUID): Boolean = entities[playerId] != null

    override fun entityId(playerId: UUID): Int {
        return entities[playerId]?.entityId ?: 0
    }
}