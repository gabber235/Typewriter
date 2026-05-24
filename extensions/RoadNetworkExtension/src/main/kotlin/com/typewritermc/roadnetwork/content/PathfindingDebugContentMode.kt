package com.typewritermc.roadnetwork.content

import com.github.retrooper.packetevents.util.Vector3f
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.*
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.content.ContentComponent
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.components.*
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.loreString
import com.typewritermc.engine.paper.utils.name
import com.typewritermc.engine.paper.utils.particleSphere
import com.typewritermc.engine.paper.utils.playSound
import com.typewritermc.roadnetwork.*
import com.typewritermc.roadnetwork.content.debug.*
import kotlinx.coroutines.Dispatchers
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import net.kyori.adventure.bossbar.BossBar
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.Color
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerItemHeldEvent
import org.bukkit.inventory.ItemStack
import java.time.Duration
import java.time.Instant
import java.util.*
import kotlin.math.max
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.toKotlinDuration

class PathfindingDebugContentMode(
    context: ContentContext,
    player: Player,
    private val ref: Ref<RoadNetworkEntry>,
    private val startNodeId: RoadNodeId,
    private val session: PathfindingDebugSession
) : ContentMode(context, player), Listener {

    private lateinit var networkEditor: RoadNetworkEditorComponent
    private lateinit var visualizer: PathfindingDebugDisplayManager
    private lateinit var nearbyNodes: NearbyNodesDebugComponent

    private val network get() = networkEditor.network

    private var timelinePosition: Double = 0.0
        set(value) {
            val maxPosition = max(0.0, (visibleSteps.size - 1).toDouble())
            field = value.coerceIn(0.0, maxPosition)
            Dispatchers.UntickedAsync.launch { updateVisualization() }
        }

    private val currentStepIndex: Int get() = timelinePosition.toInt()

    private var playbackSpeed = 0.0
    private var scrollingPlayerId: UUID? = null
    private val scrollVelocity = ScrollVelocity()

    private var verboseMode = false
        set(value) {
            if (field != value) {
                val currentStepIndex = timelinePosition.toInt()
                val currentStep =
                    if (visibleSteps.isNotEmpty() && currentStepIndex >= 0 && currentStepIndex < visibleSteps.size) {
                        visibleSteps[currentStepIndex]
                    } else null

                val targetStepIndex = currentStep?.stepIndex
                field = value

                timelinePosition = if (targetStepIndex != null && visibleSteps.isNotEmpty()) {
                    val exactMatch = visibleSteps.indexOfFirst { it.stepIndex == targetStepIndex }
                    if (exactMatch >= 0) {
                        exactMatch.toDouble()
                    } else {
                        val closestMatch = visibleSteps.indexOfLast { it.stepIndex <= targetStepIndex }
                        if (closestMatch >= 0) closestMatch.toDouble() else 0.0
                    }
                } else {
                    0.0
                }

                Dispatchers.UntickedAsync.launch { updateVisualization() }
            }
        }

    private var cycle = 0

    private val visibleSteps: List<PathfindingDebugStep>
        get() = if (verboseMode) session.getAllSteps() else session.getImportantSteps()

    override suspend fun setup(): Result<Unit> {
        networkEditor = +RoadNetworkEditorComponent(ref)

        val (startNode, targetNode) = findRequiredNodes()
            ?: return failure(Exception("Could not find start or target node"))

        visualizer = PathfindingDebugDisplayManager(player, startNode.position, targetNode.position)

        nearbyNodes = +NearbyNodesDebugComponent(
            networkFetcher = { network },
            excludeNodeId = startNodeId
        )

        plugin.registerEvents(this)

        setupBossBar()
        setupControlComponents()
        setupNodeDisplays(startNode, targetNode)
        setupRadiusVisualization()

        updateVisualization()
        return ok(Unit)
    }

    private fun findRequiredNodes(): Pair<RoadNode, RoadNode>? {
        val startNode = network.nodes.find { it.id == startNodeId }
        val targetNode = network.nodes.find { node ->
            val targetPos = session.targetPosition
            node.position.x == targetPos.x && node.position.y == targetPos.y &&
                    node.position.z == targetPos.z && node.position.world == targetPos.world
        }
        return if (startNode != null && targetNode != null) startNode to targetNode else null
    }

    private fun setupBossBar() {
        bossBar {
            val stepDisplay = (currentStepIndex + 1).toString().padStart(visibleSteps.size.toString().length)
            var statusIndicators = ""

            if (scrollingPlayerId != null) statusIndicators += " <gradient:#9452ff:#ff2eea><b>(Scrolling)</b></gradient>"
            if (verboseMode) statusIndicators += " <yellow><b>(Verbose)</b></yellow>"
            if (nearbyNodes.isShowingNodes() || nearbyNodes.isShowingRadius()) {
                statusIndicators += " <blue><b>(Context)</b></blue>"
            }
            if (session.intermediateNodeCollision != null) {
                statusIndicators += " <red><b>(Collision)</b></red>"
            }

            if (statusIndicators.isNotBlank()) statusIndicators = " <gray>-$statusIndicators"

            title =
                "Debug: <gray>$startNodeId</gray> → Target <white>$stepDisplay/${visibleSteps.size} (${playbackSpeed}x)$statusIndicators"

            color = when {
                !session.successful -> BossBar.Color.RED
                scrollingPlayerId != null -> BossBar.Color.PURPLE
                verboseMode -> BossBar.Color.YELLOW
                playbackSpeed != 0.0 -> BossBar.Color.GREEN
                else -> BossBar.Color.WHITE
            }

            progress = when (visibleSteps.size) {
                0 -> 0f
                1 -> 1f
                else -> (timelinePosition / (visibleSteps.size - 1)).toFloat()
            }
        }
        exit()
    }

    private fun setupControlComponents() {
        +PlaybackControls(
            onSetSpeed = { playbackSpeed = it },
            onUpdateSpeed = { playbackSpeed += it },
            onSetStep = { timelinePosition = it },
            isPaused = { playbackSpeed == 0.0 }
        )

        +StepNavigation(
            onUpdateStep = { timelinePosition += it },
            onToggleScrolling = { toggleScrolling() }
        )

        +VerboseModeToggle(
            isVerbose = { verboseMode },
            onToggleVerbose = {
                verboseMode = !verboseMode
                player.playSound("ui.button.click")
            }
        )

        +NearbyNodesDebugControlComponent(nearbyNodes)
    }

    private fun setupNodeDisplays(startNode: RoadNode, targetNode: RoadNode) {
        nodes({ listOf(startNode, targetNode) }, ::rotatingPosition) { node ->
            item = ItemStack(
                if (node.id == startNodeId) Material.EMERALD_BLOCK else Material.REDSTONE_BLOCK
            )
            glow = if (node.id == startNodeId) NamedTextColor.GREEN else NamedTextColor.RED
            scale = Vector3f(0.7f, 0.7f, 0.7f)
        }

        if (nearbyNodes.isShowingNodes()) {
            nodes({ nearbyNodes.getNearbyRegularNodes() }, ::staticPosition) { node ->
                item = ItemStack(node.material(network.modifications))
                val collidingNode = getHighlightedCollidingNode()

                glow = when {
                    collidingNode != null && node.id == collidingNode.id -> NamedTextColor.GOLD
                    network.edges.any { it.start == startNodeId && it.end == node.id } -> NamedTextColor.BLUE
                    network.modifications.containsRemoval(startNodeId, node.id) -> NamedTextColor.GOLD
                    network.modifications.containsAddition(startNodeId, node.id) -> NamedTextColor.GREEN
                    else -> null
                }
                scale = Vector3f(0.5f, 0.5f, 0.5f)
            }

            nodes({ nearbyNodes.getNearbyNegativeNodes() }, ::staticPosition) { _ ->
                item = ItemStack(Material.NETHERITE_BLOCK)
                glow = NamedTextColor.BLACK
                scale = Vector3f(0.5f, 0.5f, 0.5f)
            }
        }
    }

    private fun setupRadiusVisualization() {
        +NodeRadiusVisualization(nearbyNodes)
    }

    private fun toggleScrolling() {
        scrollingPlayerId = if (scrollingPlayerId == null) {
            player.playSound("block.amethyst_block.hit")
            player.uniqueId
        } else {
            player.playSound("block.amethyst_block.fall")
            null
        }
    }

    override suspend fun tick(deltaTime: Duration) {
        super.tick(deltaTime)
        cycle++

        updateCollisionOverride()

        if (playbackSpeed != 0.0 && visibleSteps.isNotEmpty()) {
            timelinePosition += playbackSpeed / 5.0
            if (timelinePosition >= visibleSteps.size - 1 || timelinePosition <= 0) {
                playbackSpeed = 0.0
            }
        } else if (cycle % 10 == 0) {
            visualizer.updateVisualization(
                steps = visibleSteps,
                currentStepIndex = currentStepIndex,
                finalPath = if (currentStepIndex >= visibleSteps.size - 1) session.finalPath else null,
                showVerbose = verboseMode,
                isPlayback = playbackSpeed != 0.0,
                successful = session.successful,
                intermediateNodeCollision = session.intermediateNodeCollision,
                timeoutOnly = true
            )
        }
    }

    @EventHandler
    private fun onScroll(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != scrollingPlayerId) return

        val delta = loopingDistance(event.previousSlot, event.newSlot, 8)
        val stepChange = delta * if (delta > 0) scrollVelocity.forward() else scrollVelocity.backward()
        timelinePosition += stepChange
        event.player.playSound("block.note_block.hat", pitch = 1f + (delta * 0.1f), volume = 0.5f)
        event.isCancelled = true
    }

    private fun updateCollisionOverride() {
        val collision = session.intermediateNodeCollision
        if (collision != null) {
            val isOnFinalStep = currentStepIndex >= visibleSteps.size - 1
            val shouldShowCollisionNode = isOnFinalStep && !session.successful

            if (shouldShowCollisionNode) {
                nearbyNodes.setCollisionNodeOverride(collision.collidingNode)
            } else {
                nearbyNodes.setCollisionNodeOverride(null)
            }
        } else {
            nearbyNodes.setCollisionNodeOverride(null)
        }
    }

    private suspend fun updateVisualization() {
        if (visibleSteps.isEmpty()) return

        visualizer.updateVisualization(
            steps = visibleSteps,
            currentStepIndex = currentStepIndex,
            finalPath = if (currentStepIndex >= visibleSteps.size - 1) session.finalPath else null,
            showVerbose = verboseMode,
            isPlayback = playbackSpeed != 0.0,
            successful = session.successful,
            intermediateNodeCollision = session.intermediateNodeCollision
        )
    }

    private fun rotatingPosition(node: RoadNode): Position = node.position.withYaw((cycle % 360).toFloat())
    private fun staticPosition(node: RoadNode): Position = node.position.withYaw(0f)

    override suspend fun dispose() {
        super.dispose()
        unregister()
        visualizer.clearAll()
        nearbyNodes.setCollisionNodeOverride(null)
    }

    private fun getHighlightedCollidingNode(): RoadNode? {
        val collision = session.intermediateNodeCollision ?: return null
        val collisionStepIndex = visibleSteps.indexOfFirst {
            it.event is PathfindingDebugEvent.IntermediateNodeCollision
        }
        return if (collisionStepIndex in 0..currentStepIndex) collision.collidingNode else null
    }
}

private class NodeRadiusVisualization(
    private val nearbyNodes: NearbyNodesDebugComponent
) : ContentComponent {

    private var cycle = 0

    override suspend fun initialize(player: Player) {}

    override suspend fun tick(player: Player) {
        cycle++
        if (!nearbyNodes.isShowingRadius() || cycle % 4 != 0) return

        nearbyNodes.getNearbyRegularNodesForRadius().forEach { node ->
            node.position.particleSphere(
                player = player,
                radius = node.radius,
                color = Color.BLUE,
                phiDivisions = 12,
                thetaDivisions = 6
            )
        }

        nearbyNodes.getNearbyNegativeNodesForRadius().forEach { node ->
            node.position.particleSphere(
                player = player,
                radius = node.radius,
                color = Color.BLACK,
                phiDivisions = 12,
                thetaDivisions = 6
            )
        }
    }

    override suspend fun dispose(player: Player) {}
}

private class ScrollVelocity(private val minimum: Int = 1) {
    private var lastUpdate: Instant = Instant.now()
    private var velocity: Int = minimum
    private var acceleration: Int = 0
    private var direction: VelocityDirection = VelocityDirection.FORWARD

    private fun swapDirection(target: VelocityDirection) {
        if (direction == target) return
        direction = target
        velocity /= 2
        acceleration = 0
    }

    private fun move() {
        val diff = Duration.between(lastUpdate, Instant.now()).toKotlinDuration()
        lastUpdate = Instant.now()
        if (diff > 500.milliseconds) {
            velocity = minimum
            acceleration = 0
        }
        acceleration += 1
        velocity += (acceleration / 5)
    }

    fun forward(): Int {
        swapDirection(VelocityDirection.FORWARD)
        move()
        return velocity
    }

    fun backward(): Int {
        swapDirection(VelocityDirection.BACKWARD)
        move()
        return velocity
    }

    private enum class VelocityDirection { FORWARD, BACKWARD }
}

private class PlaybackControls(
    private val onSetSpeed: (Double) -> Unit,
    private val onUpdateSpeed: (Double) -> Unit,
    private val onSetStep: (Double) -> Unit,
    private val isPaused: () -> Boolean,
) : ContentComponent, ItemsComponent {

    override fun items(player: Player): Map<Int, IntractableItem> {
        val item = ItemStack(Material.CLOCK).apply {
            editMeta { meta ->
                meta.name = "<yellow><b>Playback Speed"
                meta.loreString = """
                    |<line> <green><b>Right Click: </b><white>Increases speed by 1
                    |<line> <green>Shift + Right Click: <white>Increases speed by 0.25
                    |<line> <red><b>Left Click: </b><white>Decreases speed by 1
                    |<line> <red>Shift + Left Click: <white>Decreases speed by 0.25
                    |<line> <yellow><b><key:key.drop>: </b><white>Rewind to start
                    |<line> <blue><b><key:key.swapOffhand>: </b><white>Pause/Resume
                """.trimMargin()
            }
        } onInteract { (type) ->
            when (type) {
                ItemInteractionType.RIGHT_CLICK -> onUpdateSpeed(1.0)
                ItemInteractionType.SHIFT_RIGHT_CLICK -> onUpdateSpeed(0.25)
                ItemInteractionType.LEFT_CLICK -> onUpdateSpeed(-1.0)
                ItemInteractionType.SHIFT_LEFT_CLICK -> onUpdateSpeed(-0.25)
                ItemInteractionType.DROP -> onSetStep(0.0)
                ItemInteractionType.SWAP -> onSetSpeed(if (isPaused()) 1.0 else 0.0)
                else -> return@onInteract
            }
            player.playSound("ui.button.click")
        }
        return mapOf(0 to item)
    }

    override suspend fun initialize(player: Player) {}
    override suspend fun tick(player: Player) {}
    override suspend fun dispose(player: Player) {}
}

private class StepNavigation(
    private val onUpdateStep: (Double) -> Unit,
    private val onToggleScrolling: () -> Unit
) : ContentComponent, ItemsComponent {

    private val scrollVelocity = ScrollVelocity()

    override fun items(player: Player): Map<Int, IntractableItem> {
        val item = ItemStack(Material.AMETHYST_SHARD).apply {
            editMeta { meta ->
                meta.name = "<yellow><b>Navigate Steps"
                meta.loreString = """
                    |<line> <green><b>Right Click: </b><white>Goes forward (with velocity)
                    |<line> <green>Shift + Right Click: <white>Goes forward 1 step
                    |<line> <red><b>Left Click: </b><white>Goes backwards (with velocity)
                    |<line> <red>Shift + Left Click: <white>Goes backwards 1 step
                    |<line> <blue><b><key:key.swapOffhand>: </b><white>Toggle mouse wheel scrolling
                """.trimMargin()
            }
        } onInteract { (type) ->
            when (type) {
                ItemInteractionType.RIGHT_CLICK -> onUpdateStep(scrollVelocity.forward().toDouble())
                ItemInteractionType.SHIFT_RIGHT_CLICK -> onUpdateStep(1.0)
                ItemInteractionType.LEFT_CLICK -> onUpdateStep(-scrollVelocity.backward().toDouble())
                ItemInteractionType.SHIFT_LEFT_CLICK -> onUpdateStep(-1.0)
                ItemInteractionType.SWAP -> onToggleScrolling()
                else -> return@onInteract
            }
            if (type != ItemInteractionType.SWAP) player.playSound("ui.button.click")
        }
        return mapOf(1 to item)
    }

    override suspend fun initialize(player: Player) {}
    override suspend fun tick(player: Player) {}
    override suspend fun dispose(player: Player) {}
}

private class VerboseModeToggle(
    private val isVerbose: () -> Boolean,
    private val onToggleVerbose: () -> Unit
) : ContentComponent, ItemComponent {

    override fun item(player: Player): Pair<Int, IntractableItem> {
        val item = if (isVerbose()) {
            ItemStack(Material.ENCHANTED_BOOK).apply {
                editMeta { meta ->
                    meta.name = "<green><b>Verbose Mode: ON"
                    meta.loreString = """
                        |<line> <gray>Currently showing all debug events
                        |<line> <gray>including basic structural checks
                        |
                        |<line> <yellow>Click to show only important events
                    """.trimMargin()
                }
            }
        } else {
            ItemStack(Material.BOOK).apply {
                editMeta { meta ->
                    meta.name = "<white><b>Verbose Mode: OFF"
                    meta.loreString = """
                        |<line> <gray>Currently showing only important events
                        |<line> <gray>like gameplay constraints and failures
                        |
                        |<line> <yellow>Click to show all debug events
                    """.trimMargin()
                }
            }
        }

        return 7 to (item onInteract { onToggleVerbose() })
    }

    override suspend fun initialize(player: Player) {}
    override suspend fun tick(player: Player) {}
    override suspend fun dispose(player: Player) {}
}