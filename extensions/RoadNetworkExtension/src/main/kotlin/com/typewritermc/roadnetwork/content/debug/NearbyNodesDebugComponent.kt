package com.typewritermc.roadnetwork.content.debug

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.engine.paper.content.ContentComponent
import com.typewritermc.engine.paper.content.components.IntractableItem
import com.typewritermc.engine.paper.content.components.ItemComponent
import com.typewritermc.engine.paper.content.components.ItemInteractionType
import com.typewritermc.engine.paper.content.components.onInteract
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.loreString
import com.typewritermc.engine.paper.utils.name
import com.typewritermc.engine.paper.utils.playSound
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.RoadNodeId
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

private val debugNodeVisibilityDistance by snippet(
    "content.road_network.debug.node_visibility_distance",
    25.0,
    "The maximum distance from the player to show nodes and their radius during debug mode"
)

class NearbyNodesDebugComponent(
    private val networkFetcher: () -> RoadNetwork,
    private val excludeNodeId: RoadNodeId? = null
) : ContentComponent {

    private var nodesVisible = true
    private var radiusVisible = true
    private var lastRadiusStateWhenNodesEnabled = true
    private var needsRefresh = false

    private var collisionNodeOverride: RoadNode? = null

    private var cachedRegularNodes: List<RoadNode> = emptyList()
    private var cachedNegativeNodes: List<RoadNode> = emptyList()
    private var lastPlayerPosition: Position? = null
    private var cacheUpdateCounter = 0

    override suspend fun initialize(player: Player) {
        refreshNodeCache(player)
    }

    override suspend fun tick(player: Player) {
        if (cacheUpdateCounter++ >= 20 || hasPlayerMovedSignificantly(player) || needsRefresh) {
            refreshNodeCache(player)
            cacheUpdateCounter = 0
            needsRefresh = false
        }
    }

    private fun refreshNodeCache(player: Player) {
        val playerPos = player.position
        val network = networkFetcher()
        val maxDistanceSquared = debugNodeVisibilityDistance * debugNodeVisibilityDistance

        cachedRegularNodes = network.nodes
            .filter { node ->
                node.id != excludeNodeId &&
                        node.position.world == playerPos.world &&
                        node.position.distanceSquared(playerPos)!! <= maxDistanceSquared
            }

        cachedNegativeNodes = network.negativeNodes
            .filter { node ->
                node.position.world == playerPos.world &&
                        node.position.distanceSquared(playerPos)!! <= maxDistanceSquared
            }

        lastPlayerPosition = playerPos
    }

    private fun hasPlayerMovedSignificantly(player: Player): Boolean {
        val currentPos = player.position
        val lastPos = lastPlayerPosition ?: return true
        return (currentPos.distanceSquared(lastPos) ?: 0.0) > 5.0
    }

    fun setNodeVisibility(visible: Boolean) {
        if (nodesVisible != visible) {
            if (visible) {
                nodesVisible = true
                radiusVisible = lastRadiusStateWhenNodesEnabled
            } else {
                lastRadiusStateWhenNodesEnabled = radiusVisible
                nodesVisible = false
                radiusVisible = false
            }
            needsRefresh = true
        }
    }

    fun setRadiusVisibility(visible: Boolean) {
        if (visible && !nodesVisible) {
            setNodeVisibility(true)
            radiusVisible = true
            lastRadiusStateWhenNodesEnabled = true
            needsRefresh = true
        } else if (nodesVisible && radiusVisible != visible) {
            radiusVisible = visible
            lastRadiusStateWhenNodesEnabled = visible
            needsRefresh = true
        }
    }

    fun setCollisionNodeOverride(node: RoadNode?) {
        if (collisionNodeOverride != node) {
            collisionNodeOverride = node
            needsRefresh = true
        }
    }

    fun isShowingNodes(): Boolean = nodesVisible || collisionNodeOverride != null
    fun isShowingRadius(): Boolean = radiusVisible || collisionNodeOverride != null

    private fun applyCollisionOverride(baseNodes: List<RoadNode>): List<RoadNode> {
        return if (collisionNodeOverride != null) {
            val collisionNode = collisionNodeOverride!!
            if (baseNodes.contains(collisionNode)) {
                baseNodes
            } else {
                baseNodes + collisionNode
            }
        } else {
            baseNodes
        }
    }

    fun getNearbyRegularNodes(): List<RoadNode> {
        val visibleNodes = if (nodesVisible) cachedRegularNodes else emptyList()
        return applyCollisionOverride(visibleNodes)
    }

    fun getNearbyNegativeNodes(): List<RoadNode> = if (nodesVisible) cachedNegativeNodes else emptyList()

    fun getNearbyRegularNodesForRadius(): List<RoadNode> {
        val visibleNodes = if (radiusVisible) cachedRegularNodes else emptyList()
        return applyCollisionOverride(visibleNodes)
    }

    fun getNearbyNegativeNodesForRadius(): List<RoadNode> = if (radiusVisible) cachedNegativeNodes else emptyList()

    fun getVisibilityDistance(): Double = debugNodeVisibilityDistance

    override suspend fun dispose(player: Player) {}
}

class NearbyNodesDebugControlComponent(
    private val nearbyNodes: NearbyNodesDebugComponent,
    private val startSlot: Int = 4
) : ContentComponent, ItemComponent {

    override fun item(player: Player): Pair<Int, IntractableItem> {
        val showingNodes = nearbyNodes.isShowingNodes()
        val showingRadius = nearbyNodes.isShowingRadius()
        val distance = nearbyNodes.getVisibilityDistance().toInt()

        val item = ItemStack(
            when {
                showingNodes && showingRadius -> Material.BEACON
                showingNodes -> Material.DIAMOND_BLOCK
                else -> Material.BARRIER
            }
        ).apply {
            editMeta { meta ->
                meta.name = "<dark_aqua><b>Context Visualization"

                val nodeStatus = if (showingNodes) "<green>ON" else "<red>OFF"
                val radiusStatus = if (showingRadius) "<green>ON" else "<red>OFF"

                meta.loreString = """
                    |<line> <gray>Shows nearby nodes and their radius
                    |<line> <gray>within $distance blocks for context
                    |<line>
                    |<line> <blue>Nodes: $nodeStatus
                    |<line> <blue>Radius: $radiusStatus
                    |<line>
                    |<line> <green><b>Left Click:</b> <white>Toggle nodes
                    |<line> <green><b>Right Click:</b> <white>Toggle radius
                    |<line> <green><b>Shift + Click:</b> <white>Toggle both
                """.trimMargin()
            }
        } onInteract { interaction ->
            when (interaction.type) {
                ItemInteractionType.LEFT_CLICK -> {
                    val newState = !nearbyNodes.isShowingNodes()
                    nearbyNodes.setNodeVisibility(newState)
                    player.playSound("ui.button.click")
                }

                ItemInteractionType.RIGHT_CLICK -> {
                    val newState = !nearbyNodes.isShowingRadius()
                    nearbyNodes.setRadiusVisibility(newState)
                    player.playSound("ui.button.click")
                }

                ItemInteractionType.SHIFT_LEFT_CLICK, ItemInteractionType.SHIFT_RIGHT_CLICK -> {
                    val bothEnabled = nearbyNodes.isShowingNodes() && nearbyNodes.isShowingRadius()
                    if (bothEnabled) {
                        nearbyNodes.setNodeVisibility(false)
                    } else {
                        nearbyNodes.setNodeVisibility(true)
                        nearbyNodes.setRadiusVisibility(true)
                    }
                    player.playSound("ui.button.click")
                }

                else -> return@onInteract
            }
        }

        return startSlot to item
    }

    override suspend fun initialize(player: Player) {}
    override suspend fun tick(player: Player) {}
    override suspend fun dispose(player: Player) {}
}