package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.config
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

val entityShowRange by config("entity.show-range", 50.0, "The range at which entities are shown")

class SharedAudienceEntityDisplay(
    override val instanceEntryRef: Ref<out EntityInstanceEntry>,
    override val creator: EntityCreator,
    private val activityCreators: ActivityCreator,
    private val suppliers: List<Pair<PropertySupplier<*>, Int>>,
    private val spawnPosition: Position,
    private val showRange: Var<Double> = ConstVar(entityShowRange),
    ) : AudienceFilter(instanceEntryRef), TickableDisplay, AudienceEntityDisplay {
    private var activityManager: ActivityManager<SharedActivityContext>? = null
    private val entities = ConcurrentHashMap<UUID, DisplayEntity>()

    /**
     * When nobody can see the entity, but it is still active, there is no way to get the state for the entity.
     * So we just assume that the entity state stays the same.
     */
    private var lastState: EntityState = EntityState()

    override fun filter(player: Player): Boolean {
        val npcLocation = activityManager?.position ?: return false
        val distance = npcLocation.distanceSqrt(player.location) ?: return false
        val showRange = showRange.get(player)
        return distance <= showRange * showRange
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
        activityManager.addedViewer(SharedActivityContext(instanceEntryRef, players), player)
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }

        // This is not an exact solution.
        // When the state is different between players, it might look weird.
        // But there is no real solution to this.
        // So we pick the first entity's state and use to try and keep the state consistent.
        val entityState = entities.values.firstOrNull()?.state?.also { lastState = it } ?: lastState
        activityManager?.tick(SharedActivityContext(instanceEntryRef, players, entityState))
        entities.values.forEach { it.tick() }
    }

    override fun onPlayerFilterRemoved(player: Player) {
        activityManager?.removedViewer(SharedActivityContext(instanceEntryRef, players), player)
        super.onPlayerFilterRemoved(player)
        entities.remove(player.uniqueId)?.dispose()
    }

    override fun dispose() {
        super.dispose()
        entities.values.forEach { it.dispose() }
        entities.clear()
        activityManager?.dispose(SharedActivityContext(instanceEntryRef, players))
        activityManager = null
        lastState = EntityState()
    }

    override fun playerSeesEntity(playerId: UUID, entityId: Int): Boolean {
        return entities[playerId]?.contains(entityId) == true
    }

    override fun position(playerId: UUID): Position? = activityManager?.position?.toPosition()
    override fun entityState(playerId: UUID): EntityState = entities[playerId]?.state ?: lastState
    override fun <P : EntityProperty> property(playerId: UUID, type: KClass<P>): P? = entities[playerId]?.property(type)
    override fun canView(playerId: UUID): Boolean = canConsider(playerId)
    override fun isSpawnedIn(playerId: UUID): Boolean = entities[playerId] != null

    override fun entityId(playerId: UUID): Int {
        return entities[playerId]?.entityId ?: 0
    }
}
