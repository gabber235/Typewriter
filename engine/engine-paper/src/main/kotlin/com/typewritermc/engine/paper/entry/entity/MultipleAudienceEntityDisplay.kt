package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.server
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

abstract class MultipleEntityDisplayBase(
    override val instanceEntryRef: Ref<out EntityInstanceEntry>,
    override val creator: EntityCreator,
    protected val suppliers: List<Pair<PropertySupplier<*>, Int>>,
) : AudienceFilter(instanceEntryRef), TickableDisplay, AudienceEntityDisplay {

    protected val entities = ConcurrentHashMap<UUID, List<DisplayEntity>>()

    protected abstract fun count(playerId: UUID): Int
    protected abstract fun managers(playerId: UUID): List<ActivityManager<*>>
    protected abstract fun showRangeSq(player: Player): Double

    protected abstract fun onEntityAddedToPlayer(manager: ActivityManager<*>, player: Player)
    protected abstract fun onEntityRemovedFromPlayer(manager: ActivityManager<*>, player: Player)

    protected fun findClosestEntity(playerId: UUID, player: Player? = null): DisplayEntity? {
        val actualPlayer = player ?: server.getPlayer(playerId)
        ?: error("Player $playerId is not online when trying to find closest entity")

        val entityList = entities[playerId] ?: return null

        return entityList
            .mapNotNull { entity ->
                val distSq =
                    entity.activityManager.position.distanceSqrt(actualPlayer.location) ?: return@mapNotNull null
                entity to distSq
            }
            .minByOrNull { it.second }
            ?.first
    }

    protected fun findClosestPosition(playerId: UUID, player: Player? = null): Position? {
        val actualPlayer = player ?: server.getPlayer(playerId)
        ?: error("Player $playerId is not online when trying to find closest position")

        return managers(playerId)
            .mapNotNull { manager ->
                val distSq = manager.position.distanceSqrt(actualPlayer.location) ?: return@mapNotNull null
                manager.position.toPosition() to distSq
            }
            .minByOrNull { it.second }
            ?.first
    }

    override fun playerSeesEntity(playerId: UUID, entityId: Int): Boolean {
        return entities[playerId]?.any { it.contains(entityId) } == true
    }

    override fun position(playerId: UUID): Position? {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting position")
        return findClosestPosition(playerId, player)
            ?: managers(playerId).firstOrNull()?.position?.toPosition()
    }

    override fun entityState(playerId: UUID): EntityState {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting entity state")
        return findClosestEntity(playerId, player)?.state ?: EntityState()
    }

    override fun <P : EntityProperty> property(playerId: UUID, type: KClass<P>): P? {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting property")
        return findClosestEntity(playerId, player)?.property(type)
    }

    override fun canView(playerId: UUID): Boolean = canConsider(playerId)

    override fun isSpawnedIn(playerId: UUID): Boolean = entities.containsKey(playerId)

    override fun entityId(playerId: UUID): Int {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting entity ID")
        return findClosestEntity(playerId, player)?.entityId ?: 0
    }

    protected fun createDisplayEntity(
        player: Player,
        manager: ActivityManager<*>,
    ): DisplayEntity = DisplayEntity(player, creator, manager, suppliers.toCollectors())

    protected fun findEntityStateFromViewers(
        manager: ActivityManager<*>,
        viewers: List<Player>,
        states: MutableList<EntityState>,
        index: Int
    ): EntityState {
        return viewers.firstNotNullOfOrNull { viewer ->
            entities[viewer.uniqueId]?.find { it.activityManager === manager }?.state
        }?.also {
            if (index < states.size) states[index] = it
        } ?: states.getOrElse(index) { EntityState() }
    }

    protected fun performTick() {
        refreshPlayers()
        updateVisibleEntities()
        tickAllEntities()
    }

    private fun refreshPlayers() {
        consideredPlayers.forEach { it.refresh() }
    }

    private fun updateVisibleEntities() {
        val showRanges = consideredPlayers.associateWith { showRangeSq(it) }

        consideredPlayers.forEach { player ->
            val rangeSq = showRanges[player] ?: return@forEach
            syncPlayerEntities(player, rangeSq)
        }
    }

    private fun syncPlayerEntities(player: Player, rangeSq: Double) {
        val managerList = managers(player.uniqueId)
        val currentEntities = entities[player.uniqueId] ?: emptyList()

        val newEntities = managerList.mapNotNull { manager ->
            resolveEntityForManager(manager, player, currentEntities, rangeSq)
        }

        setOrClearPlayerEntities(player.uniqueId, newEntities)
    }

    private fun resolveEntityForManager(
        manager: ActivityManager<*>,
        player: Player,
        currentEntities: List<DisplayEntity>,
        rangeSq: Double
    ): DisplayEntity? {
        val distance = manager.position.distanceSqrt(player.location)
        val currentEntity = currentEntities.find { it.activityManager === manager }

        return when {
            distance == null || distance > rangeSq -> {
                currentEntity?.let {
                    onEntityRemovedFromPlayer(manager, player)
                    it.dispose()
                }
                null
            }

            currentEntity != null -> currentEntity
            else -> {
                createDisplayEntity(player, manager).also {
                    onEntityAddedToPlayer(manager, player)
                }
            }
        }
    }

    private fun setOrClearPlayerEntities(playerId: UUID, newEntities: List<DisplayEntity>) {
        if (newEntities.isNotEmpty()) {
            entities[playerId] = newEntities
        } else {
            entities.remove(playerId)
        }
    }

    private fun tickAllEntities() {
        entities.values.flatten().forEach { it.tick() }
    }

    protected fun removePlayerEntities(
        player: Player,
        additionalCleanup: (DisplayEntity) -> Unit = {}
    ) {
        entities[player.uniqueId]?.forEach { entity ->
            onEntityRemovedFromPlayer(entity.activityManager, player)
            additionalCleanup(entity)
            entity.dispose()
        }
        entities.remove(player.uniqueId)
    }
}

class MultipleSharedAudienceEntityDisplay(
    instanceEntryRef: Ref<out EntityInstanceEntry>,
    creator: EntityCreator,
    private val activityCreator: ActivityCreator,
    suppliers: List<Pair<PropertySupplier<*>, Int>>,
    private val spawnPosition: Position,
    private val showRange: Var<Double> = ConstVar(entityShowRange),
    private val entityCount: Int,
) : MultipleEntityDisplayBase(instanceEntryRef, creator, suppliers) {

    private var activityManagers: List<ActivityManager<in SharedActivityContext>> = emptyList()
    private val lastStates = mutableListOf<EntityState>()

    private fun viewersForManager(manager: ActivityManager<*>): List<Player> =
        entities.entries
            .filter { (_, entityList) -> entityList.any { it.activityManager === manager } }
            .mapNotNull { (playerId, _) -> server.getPlayer(playerId) }

    private fun createSharedContext(viewers: List<Player>, state: EntityState? = null): SharedActivityContext {
        return if (state != null) {
            SharedActivityContext(instanceEntryRef, viewers, state)
        } else {
            SharedActivityContext(instanceEntryRef, viewers)
        }
    }

    override fun count(playerId: UUID): Int = entityCount
    override fun managers(playerId: UUID): List<ActivityManager<*>> = activityManagers
    override fun showRangeSq(player: Player): Double = showRange.get(player).let { it * it }

    override fun onEntityAddedToPlayer(manager: ActivityManager<*>, player: Player) {
        val viewers = viewersForManager(manager)
        manager.addedViewer(createSharedContext(viewers), player)
    }

    override fun onEntityRemovedFromPlayer(manager: ActivityManager<*>, player: Player) {
        val viewers = viewersForManager(manager)
        manager.removedViewer(createSharedContext(viewers), player)
    }

    override fun initialize() {
        super.initialize()

        activityManagers = List(entityCount.coerceAtLeast(1)) {
            val context = createSharedContext(emptyList())
            val activity = activityCreator.create(context, spawnPosition.toProperty())
            ActivityManager(activity).apply { initialize(context) }
        }

        lastStates.addAll(List(activityManagers.size) { EntityState() })
    }

    override fun filter(player: Player): Boolean {
        val rangeSq = showRangeSq(player)
        return activityManagers.any { manager ->
            manager.position.distanceSqrt(player.location)?.let { it <= rangeSq } ?: false
        }
    }

    override fun onPlayerFilterAdded(player: Player) {
        super.onPlayerFilterAdded(player)
        val rangeSq = showRangeSq(player)

        val newEntities = activityManagers.mapNotNull { manager ->
            manager.position.distanceSqrt(player.location)
                ?.takeIf { it <= rangeSq }
                ?.let { createDisplayEntity(player, manager) }
        }

        if (newEntities.isEmpty()) return

        entities[player.uniqueId] = newEntities
        newEntities.forEach { entity ->
            onEntityAddedToPlayer(entity.activityManager, player)
        }
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
        tickActivityManagers()
        performTick()
    }

    private fun tickActivityManagers() {
        activityManagers.forEachIndexed { index, manager ->
            val viewers = viewersForManager(manager)
            val state = findEntityStateFromViewers(manager, viewers, lastStates, index)
            manager.tick(createSharedContext(viewers, state))
        }
    }

    override fun onPlayerFilterRemoved(player: Player) {
        super.onPlayerFilterRemoved(player)
        removePlayerEntities(player)
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        removePlayerEntities(player)
    }

    override fun dispose() {
        super.dispose()
        entities.values.flatten().forEach { it.dispose() }
        entities.clear()
        activityManagers.forEach { it.dispose(createSharedContext(emptyList())) }
        lastStates.clear()
    }

    override fun entityState(playerId: UUID): EntityState {
        val player = server.getPlayer(playerId)
            ?: return lastStates.firstOrNull() ?: EntityState()
        return findClosestEntity(playerId, player)?.state
            ?: lastStates.firstOrNull()
            ?: EntityState()
    }

    override fun position(playerId: UUID): Position? {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting position")
        return findClosestPosition(playerId, player)
            ?: activityManagers.firstOrNull()?.position?.toPosition()
    }
}

class MultipleIndividualAudienceEntityDisplay(
    instanceEntryRef: Ref<out EntityInstanceEntry>,
    creator: EntityCreator,
    private val activityCreator: ActivityCreator,
    suppliers: List<Pair<PropertySupplier<*>, Int>>,
    private val spawnPosition: Var<Position>,
    private val showRange: Var<Double> = ConstVar(entityShowRange),
    private val entityCount: Var<Int>,
) : MultipleEntityDisplayBase(instanceEntryRef, creator, suppliers) {

    private val activityManagers = ConcurrentHashMap<UUID, List<ActivityManager<in IndividualActivityContext>>>()
    private val lastStates = ConcurrentHashMap<UUID, MutableList<EntityState>>()

    private fun createIndividualContext(
        player: Player,
        isViewing: Boolean = false,
        state: EntityState = EntityState()
    ): IndividualActivityContext {
        return IndividualActivityContext(instanceEntryRef, player, isViewing, state)
    }

    override fun count(playerId: UUID): Int =
        server.getPlayer(playerId)?.let { entityCount.get(it).coerceAtLeast(1) } ?: 1

    override fun managers(playerId: UUID): List<ActivityManager<*>> =
        activityManagers[playerId] ?: emptyList()

    override fun showRangeSq(player: Player): Double = showRange.get(player).let { it * it }

    // Individual entities don't need viewer tracking
    override fun onEntityAddedToPlayer(manager: ActivityManager<*>, player: Player) {}
    override fun onEntityRemovedFromPlayer(manager: ActivityManager<*>, player: Player) {}

    override fun filter(player: Player): Boolean {
        val count = count(player.uniqueId)
        if (count <= 0) return false

        val showRangeSq = showRangeSq(player)
        return managers(player.uniqueId).any { manager ->
            manager.position.distanceSqrt(player.location)?.let { it <= showRangeSq } ?: false
        }
    }

    override fun onPlayerAdd(player: Player) {
        val count = count(player.uniqueId)
        val spawnPos = spawnPosition.get(player)

        val newManagers = List(count) {
            createActivityManager(player, spawnPos)
        }

        activityManagers[player.uniqueId] = newManagers
        lastStates[player.uniqueId] = MutableList(count) { EntityState() }

        super.onPlayerAdd(player)
    }

    private fun createActivityManager(
        player: Player,
        spawnPos: Position
    ): ActivityManager<in IndividualActivityContext> {
        val context = createIndividualContext(player)
        val activity = activityCreator.create(context, spawnPos.toProperty())
        return ActivityManager(activity).apply { initialize(context) }
    }

    override fun onPlayerFilterAdded(player: Player) {
        super.onPlayerFilterAdded(player)
        val showRangeSq = showRangeSq(player)
        val managerList = managers(player.uniqueId)

        val newEntities = managerList.mapNotNull { manager ->
            manager.position.distanceSqrt(player.location)?.takeIf { it <= showRangeSq }?.let {
                createDisplayEntity(player, manager)
            }
        }

        if (newEntities.isNotEmpty()) {
            entities[player.uniqueId] = newEntities
        }
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
        adjustManagerCounts()
        tickActivityManagers()
        performTick()
    }

    private fun adjustManagerCounts() {
        consideredPlayers.forEach { player ->
            adjustManagerCountForPlayer(player)
        }
    }

    private fun adjustManagerCountForPlayer(player: Player) {
        val currentCount = count(player.uniqueId)
        val currentManagers = activityManagers[player.uniqueId] ?: emptyList()

        if (currentCount == currentManagers.size) return

        val newManagers = if (currentCount > currentManagers.size) {
            addManagers(player, currentManagers, currentCount)
        } else {
            removeManagers(player, currentManagers, currentCount)
        }

        activityManagers[player.uniqueId] = newManagers
        adjustStatesForCount(player.uniqueId, currentCount)
        adjustEntitiesForCount(player, currentCount)
    }

    private fun addManagers(
        player: Player,
        currentManagers: List<ActivityManager<in IndividualActivityContext>>,
        targetCount: Int
    ): List<ActivityManager<in IndividualActivityContext>> {
        val spawnPos = spawnPosition.get(player)
        val additionalManagers = List(targetCount - currentManagers.size) {
            createActivityManager(player, spawnPos)
        }
        return currentManagers + additionalManagers
    }

    private fun removeManagers(
        player: Player,
        currentManagers: List<ActivityManager<in IndividualActivityContext>>,
        targetCount: Int
    ): List<ActivityManager<in IndividualActivityContext>> {
        currentManagers.drop(targetCount).forEach { manager ->
            manager.dispose(createIndividualContext(player))
        }
        return currentManagers.take(targetCount)
    }

    private fun adjustStatesForCount(playerId: UUID, targetCount: Int) {
        val states = lastStates[playerId] ?: mutableListOf()
        when {
            targetCount > states.size -> {
                states.addAll(List(targetCount - states.size) { EntityState() })
            }

            targetCount < states.size -> {
                while (states.size > targetCount) states.removeAt(states.lastIndex)
            }
        }
        lastStates[playerId] = states
    }

    private fun adjustEntitiesForCount(player: Player, targetCount: Int) {
        val currentEntities = entities[player.uniqueId] ?: emptyList()
        if (targetCount >= currentEntities.size) return

        currentEntities.drop(targetCount).forEach { it.dispose() }
        entities[player.uniqueId] = currentEntities.take(targetCount)
    }

    private fun tickActivityManagers() {
        activityManagers.forEach { (playerId, managerList) ->
            val player = server.getPlayer(playerId) ?: return@forEach
            tickManagersForPlayer(player, managerList)
        }
    }

    private fun tickManagersForPlayer(
        player: Player,
        managerList: List<ActivityManager<in IndividualActivityContext>>
    ) {
        val entityList = entities[player.uniqueId] ?: emptyList()
        val states = lastStates[player.uniqueId] ?: return

        managerList.forEachIndexed { index, manager ->
            val entity = entityList.find { it.activityManager === manager }
            val isViewing = entity != null
            val entityState = entity?.state?.also {
                if (index < states.size) states[index] = it
            } ?: states.getOrElse(index) { EntityState() }

            manager.tick(createIndividualContext(player, isViewing, entityState))
        }
    }

    override fun onPlayerFilterRemoved(player: Player) {
        super.onPlayerFilterRemoved(player)
        entities[player.uniqueId]?.forEach { it.dispose() }
        entities.remove(player.uniqueId)
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)

        entities[player.uniqueId]?.forEach { it.dispose() }
        entities.remove(player.uniqueId)

        activityManagers.remove(player.uniqueId)?.forEach { manager ->
            manager.dispose(createIndividualContext(player))
        }
        lastStates.remove(player.uniqueId)
    }

    override fun dispose() {
        super.dispose()
        entities.values.forEach { entityList ->
            entityList.forEach { it.dispose() }
        }
        entities.clear()

        activityManagers.entries.forEach { (playerId, managerList) ->
            server.getPlayer(playerId)?.let { player ->
                managerList.forEach { manager ->
                    manager.dispose(createIndividualContext(player))
                }
            }
        }
        activityManagers.clear()
        lastStates.clear()
    }

    override fun entityState(playerId: UUID): EntityState {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting entity state")
        return findClosestEntity(playerId, player)?.state
            ?: lastStates[playerId]?.firstOrNull()
            ?: EntityState()
    }
}

class MultipleGroupAudienceEntityDisplay(
    instanceEntryRef: Ref<out EntityInstanceEntry>,
    creator: EntityCreator,
    private val activityCreator: ActivityCreator,
    suppliers: List<Pair<PropertySupplier<*>, Int>>,
    private val spawnPosition: Position,
    private val showRange: Var<Double> = ConstVar(entityShowRange),
    private val group: GroupEntry,
    private val entityCount: Int,
) : MultipleEntityDisplayBase(instanceEntryRef, creator, suppliers) {

    private val activityManagers = ConcurrentHashMap<GroupId, List<ActivityManager<in SharedActivityContext>>>()
    private val lastStates = ConcurrentHashMap<GroupId, MutableList<EntityState>>()

    private fun groupViewers(groupId: GroupId): List<Player> {
        return players.filter { group.groupId(it) == groupId }
    }

    private fun getGroupId(player: Player): GroupId {
        return group.groupId(player) ?: GroupId(player.uniqueId)
    }

    private fun createSharedContext(groupId: GroupId, state: EntityState? = null): SharedActivityContext {
        val viewers = groupViewers(groupId)
        return if (state != null) {
            SharedActivityContext(instanceEntryRef, viewers, state)
        } else {
            SharedActivityContext(instanceEntryRef, viewers)
        }
    }

    override fun count(playerId: UUID): Int = entityCount

    override fun managers(playerId: UUID): List<ActivityManager<*>> {
        val player = server.getPlayer(playerId) ?: return emptyList()
        val groupId = getGroupId(player)
        return activityManagers[groupId] ?: emptyList()
    }

    override fun showRangeSq(player: Player): Double = showRange.get(player).let { it * it }

    override fun onEntityAddedToPlayer(manager: ActivityManager<*>, player: Player) {
        val groupId = getGroupId(player)
        manager.addedViewer(createSharedContext(groupId), player)
    }

    override fun onEntityRemovedFromPlayer(manager: ActivityManager<*>, player: Player) {
        val groupId = getGroupId(player)
        manager.removedViewer(createSharedContext(groupId), player)
    }

    override fun filter(player: Player): Boolean {
        val groupId = getGroupId(player)
        val managerList = activityManagers[groupId] ?: return false
        val showRangeSq = showRangeSq(player)

        return managerList.any { manager ->
            manager.position.distanceSqrt(player.location)?.let { it <= showRangeSq } ?: false
        }
    }

    override fun onPlayerAdd(player: Player) {
        val groupId = getGroupId(player)

        activityManagers.computeIfAbsent(groupId) {
            createManagersForGroup(groupId)
        }

        lastStates.computeIfAbsent(groupId) {
            MutableList(entityCount.coerceAtLeast(1)) { EntityState() }
        }

        super.onPlayerAdd(player)
    }

    private fun createManagersForGroup(groupId: GroupId): List<ActivityManager<in SharedActivityContext>> {
        val context = createSharedContext(groupId)

        return List(entityCount.coerceAtLeast(1)) {
            val activity = activityCreator.create(context, spawnPosition.toProperty())
            ActivityManager(activity).apply { initialize(context) }
        }
    }

    override fun onPlayerFilterAdded(player: Player) {
        super.onPlayerFilterAdded(player)
        val groupId = getGroupId(player)
        val managerList = activityManagers[groupId] ?: return
        val showRangeSq = showRangeSq(player)

        val newEntities = managerList.mapNotNull { manager ->
            manager.position.distanceSqrt(player.location)?.takeIf { it <= showRangeSq }?.let {
                createDisplayEntity(player, manager).also {
                    onEntityAddedToPlayer(manager, player)
                }
            }
        }

        if (newEntities.isNotEmpty()) {
            entities[player.uniqueId] = newEntities
        }
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
        tickActivityManagers()
        performTick()
    }

    private fun tickActivityManagers() {
        activityManagers.forEach { (groupId, managerList) ->
            tickManagersForGroup(groupId, managerList)
        }
    }

    private fun tickManagersForGroup(groupId: GroupId, managerList: List<ActivityManager<in SharedActivityContext>>) {
        val viewers = groupViewers(groupId)
        val states = lastStates[groupId] ?: return

        managerList.forEachIndexed { index, manager ->
            val entityState = findEntityStateFromViewers(manager, viewers, states, index)
            manager.tick(createSharedContext(groupId, entityState))
        }
    }

    override fun onPlayerFilterRemoved(player: Player) {
        val groupId = getGroupId(player)
        activityManagers[groupId]?.forEach { manager ->
            onEntityRemovedFromPlayer(manager, player)
        }

        super.onPlayerFilterRemoved(player)
        entities.remove(player.uniqueId)?.forEach { it.dispose() }
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        val groupId = getGroupId(player)

        entities.remove(player.uniqueId)?.forEach { it.dispose() }

        // When there is nobody that can view an entity, we no longer need to track its activity
        if (consideredPlayers.none { getGroupId(it) == groupId }) {
            activityManagers.remove(groupId)?.forEach { manager ->
                manager.dispose(createSharedContext(groupId))
            }
            lastStates.remove(groupId)
        }
    }

    override fun dispose() {
        super.dispose()
        entities.values.forEach { entityList ->
            entityList.forEach { it.dispose() }
        }
        entities.clear()

        activityManagers.forEach { (groupId, managerList) ->
            managerList.forEach { manager ->
                manager.dispose(createSharedContext(groupId))
            }
        }
        activityManagers.clear()
        lastStates.clear()
    }

    override fun position(playerId: UUID): Position? {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting position")
        return findClosestPosition(playerId, player)
            ?: managers(playerId).firstOrNull()?.position?.toPosition()
    }

    override fun entityState(playerId: UUID): EntityState {
        val player = server.getPlayer(playerId)
            ?: error("Player $playerId is not online when requesting entity state")

        findClosestEntity(playerId, player)?.state?.let { return it }

        val groupId = getGroupId(player)
        lastStates[groupId]?.firstOrNull()?.let { return it }

        return EntityState()
    }
}
