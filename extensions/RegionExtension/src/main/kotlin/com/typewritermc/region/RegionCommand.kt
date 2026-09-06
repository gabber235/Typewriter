package com.typewritermc.region

import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.extension.annotations.TypewriterCommand
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.command.dsl.*
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentModeSwapTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.TICK_MS
import com.typewritermc.engine.paper.utils.msg
import com.typewritermc.engine.paper.utils.sendMini
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.content.*
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.displayColor
import com.typewritermc.region.flag.RegionFlagManager
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.flagReport
import com.typewritermc.region.flag.standingReport
import io.papermc.paper.command.brigadier.CommandSourceStack
import kotlinx.coroutines.*
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.block.Block
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.java.KoinJavaComponent
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

private val visualizeMode by snippet(
    "region.visualize.mode",
    "multiple",
    "How the visualize command behaves without an explicit single/multiple argument. " +
            "With multiple, shown regions stack; with single, showing a region hides the previous one.",
)

private fun exclusiveByDefault(): Boolean = when (visualizeMode.lowercase()) {
    "multiple" -> false
    "single" -> true
    else -> {
        logger.warning("Invalid region.visualize.mode '$visualizeMode', falling back to multiple. Valid values: multiple, single.")
        false
    }
}

@TypewriterCommand
fun CommandTree.regionCommand() = literal("region") {
    withPermission("typewriter.region")
    literal("visualize") {
        withPermission("typewriter.region.visualize")
        entry<RegionDefinitionEntry>("definition") { definition ->
            literal("single") { visualizeArguments(definition, exclusive = true) }
            literal("multiple") { visualizeArguments(definition, exclusive = false) }
            visualizeArguments(definition, exclusive = null)
        }
        executePlayerOrTarget { target -> hideAllVisualizations(target) }
    }
    literal("edit") {
        withPermission("typewriter.region.edit")
        entry<RegionDefinitionEntry>("definition") { definition ->
            executePlayerOrTarget { target -> startRegionEditor(target, definition()) }
        }
        executePlayerOrTarget { target -> startWorkspace(target) }
    }
    literal("debug") {
        withPermission("typewriter.region.debug")
        entry<RegionDefinitionEntry>("definition") { definition ->
            executePlayerOrTarget { target -> startDebugMode(target, definition()) }
        }
    }
    literal("flags") {
        withPermission("typewriter.region.flags")
        flagsArguments()
    }
}

// The commands swap instead of pushing: running them from inside a region mode replaces
// that mode, so repeated commands cannot stack sub mode onto sub mode. Outside a content
// interaction a swap starts one, exactly like a push.
private fun ExecutionContext<CommandSourceStack>.startRegionEditor(target: Player, definition: RegionDefinitionEntry) {
    val registry = KoinJavaComponent.get<RegionEditRegistry>(RegionEditRegistry::class.java)
    if (registry.isEditing(target.uniqueId, definition.id)) {
        sender.msg("${target.name} is already editing <blue>${definition.name}</blue>.")
        return
    }
    val session = registry.sessionOf(definition.id)
    if (session != null && session.editorId != target.uniqueId) {
        sender.msg("<red>${session.editorName} is editing ${definition.name} right now.")
        return
    }
    if (registry.activeMode(target.uniqueId) == RegionModeKind.Editor) {
        sender.msg("<red>${target.name} has another region editor open. Apply or close it first.")
        return
    }
    val contentContext = regionEditorContext(definition)
    val mode = regionEditorMode(definition, contentContext, target) ?: run {
        sender.msg("<red>${definition.name} has no in-game editor.")
        return
    }
    ContentModeSwapTrigger(contentContext, mode).triggerFor(target, context())
    sender.msg("Opened the region editor of <blue>${definition.name}</blue> for ${target.name}.")
}

private fun ExecutionContext<CommandSourceStack>.startWorkspace(target: Player) {
    val registry = KoinJavaComponent.get<RegionEditRegistry>(RegionEditRegistry::class.java)
    if (registry.activeMode(target.uniqueId) == RegionModeKind.Workspace) {
        sender.msg("The region workspace is already open for ${target.name}.")
        return
    }
    // Swapping modes disposes the outgoing one, and an editor's unsaved writes go with it.
    if (registry.activeMode(target.uniqueId) == RegionModeKind.Editor) {
        sender.msg("<red>${target.name} has a region editor open. Apply or close it first.")
        return
    }
    val contentContext = ContentContext(emptyMap())
    ContentModeSwapTrigger(contentContext, RegionWorkspaceContentMode(contentContext, target))
        .triggerFor(target, context())
    sender.msg("Opened the region workspace for ${target.name}. Aim at a region and right-click the compass to edit it.")
}

private fun ExecutionContext<CommandSourceStack>.startDebugMode(target: Player, definition: RegionDefinitionEntry) {
    val registry = KoinJavaComponent.get<RegionEditRegistry>(RegionEditRegistry::class.java)
    // Swapping modes disposes the outgoing one, and an editor's unsaved writes go with it.
    if (registry.activeMode(target.uniqueId) == RegionModeKind.Editor) {
        sender.msg("<red>${target.name} has a region editor open. Apply or close it first.")
        return
    }
    val contentContext = ContentContext(mapOf("entryId" to definition.id))
    ContentModeSwapTrigger(contentContext, RegionDebugContentMode(contentContext, target))
        .triggerFor(target, context())
    sender.msg("Debugging <blue>${definition.name}</blue> for ${target.name}. The exit item closes the debugger.")
}

private const val FLAGS_REACH = 32.0
private const val MAX_FLAGS_HIGHLIGHT_SECONDS = 300
private val DEFAULT_FLAGS_HIGHLIGHT = 5.seconds

/**
 * Why a block can or cannot be changed: every region [target] stands in with the flags it
 * carries, then every flag type in force at the block [target] is looking at, the region that
 * decided it, and its priority. A flag no region decides is reported as undecided. The aimed block is
 * highlighted for [duration] so the answer is never ambiguous about which block was judged.
 */
private fun ExecutionContext<CommandSourceStack>.showFlagReport(target: Player, duration: Duration) {
    val index = KoinJavaComponent.get<RegionFlagManager>(RegionFlagManager::class.java).index
    if (index == null) {
        sender.msg("The region flag index has not loaded yet.")
        return
    }

    sender.msg("<blue>${target.name}</blue> is standing in:")
    standingReport(index, target.location.toPosition(), target).forEach(sender::sendMini)

    val block = target.rayTraceBlocks(FLAGS_REACH)?.hitBlock
    if (block == null) {
        sender.msg("${target.name} is not looking at a block within ${FLAGS_REACH.toInt()} blocks.")
        return
    }

    sender.msg("Looking at <blue>${block.x}, ${block.y}, ${block.z}</blue>:")
    flagReport(index, block.centerPosition(), target).forEach(sender::sendMini)

    KoinJavaComponent.get<FlagHighlighter>(FlagHighlighter::class.java).show(target, block, duration)
}

// The seconds argument must be registered before executePlayerOrTarget's target selector,
// so numeric input parses as a duration and not as a player name.
private fun CommandTree.visualizeArguments(
    definition: ArgumentReference<RegionDefinitionEntry>,
    exclusive: Boolean?,
) {
    int("seconds", min = 1, max = 3600) { seconds ->
        executePlayerOrTarget { target ->
            startVisualization(target, definition(), exclusive, seconds().seconds)
        }
    }
    executePlayerOrTarget { target ->
        toggleVisualization(target, definition(), exclusive)
    }
}

// The seconds argument must be registered before executePlayerOrTarget's target selector,
// so numeric input parses as a duration and not as a player name.
private fun CommandTree.flagsArguments() {
    // Minutes rather than the visualize command's hour: the highlight can be aimed at another
    // player, whose only way out of it is to log off. Nothing hides it for them.
    int("seconds", min = 1, max = MAX_FLAGS_HIGHLIGHT_SECONDS) { seconds ->
        executePlayerOrTarget { target -> showFlagReport(target, seconds().seconds) }
    }
    executePlayerOrTarget { target -> showFlagReport(target, DEFAULT_FLAGS_HIGHLIGHT) }
}

private fun ExecutionContext<CommandSourceStack>.hideAllVisualizations(target: Player) {
    val visualizer = KoinJavaComponent.get<RegionVisualizer>(RegionVisualizer::class.java)
    val count = visualizer.hideAll(target)
    if (count == 0) {
        sender.msg("No regions were being visualized.")
        return
    }
    sender.msg("No longer showing <blue>$count</blue> visualized region${if (count == 1) "" else "s"}.")
}

private fun ExecutionContext<CommandSourceStack>.toggleVisualization(
    target: Player,
    definition: RegionDefinitionEntry,
    exclusive: Boolean?,
) {
    val visualizer = KoinJavaComponent.get<RegionVisualizer>(RegionVisualizer::class.java)
    if (visualizer.hide(target, definition)) {
        sender.msg("No longer showing the boundary of <blue>${definition.name}</blue>.")
        return
    }
    visualizer.show(target, definition, Duration.INFINITE, exclusive ?: exclusiveByDefault())
    sender.msg("Showing the boundary of <blue>${definition.name}</blue>. Run the command again to stop.")
}

private fun ExecutionContext<CommandSourceStack>.startVisualization(
    target: Player,
    definition: RegionDefinitionEntry,
    exclusive: Boolean?,
    duration: Duration,
) {
    val visualizer = KoinJavaComponent.get<RegionVisualizer>(RegionVisualizer::class.java)
    visualizer.show(target, definition, duration, exclusive ?: exclusiveByDefault())
    sender.msg("Showing the boundary of <blue>${definition.name}</blue> for ${duration.inWholeSeconds} seconds.")
}

/**
 * Renders region boundaries outside of content mode, for inspecting and debugging
 * definitions, dynamic ones in particular. Each shown region draws as glowing display
 * entity edge lines in its color, which move with a dynamic region instead of leaving a
 * particle trail behind it. One session per player and definition. A session ends when its
 * duration passes, when the player leaves, or on [hide].
 */
@Singleton
class RegionVisualizer : Initializable, KoinComponent {
    private val engine: RegionEngine by inject()
    private val editRegistry: RegionEditRegistry by inject()
    private val sessions = ConcurrentHashMap<SessionKey, Job>()
    private var scope: CoroutineScope? = null

    override suspend fun initialize() {
        scope = CoroutineScope(SupervisorJob() + Dispatchers.UntickedAsync)
    }

    override suspend fun shutdown() {
        val scope = this.scope ?: return
        this.scope = null
        scope.coroutineContext.job.cancelAndJoinBounded()
        sessions.clear()
    }

    /**
     * Shows the boundary of [definition] to [player] for [duration], replacing an active
     * session for the same pair. When [exclusive], every other region shown to the player
     * is hidden first. The definition is resolved again every tick, so the outline follows a
     * dynamic region.
     */
    fun show(player: Player, definition: RegionDefinitionEntry, duration: Duration, exclusive: Boolean) {
        val scope = scope ?: return
        if (exclusive) hideAll(player)

        val key = SessionKey(player.uniqueId, definition.id)
        val data = RegionReferenceData(definition.ref())
        val color = definition.displayColor(definition.id)
        val deadline = TimeSource.Monotonic.markNow() + duration

        val job = scope.launch {
            val outline = RegionOutline(player)
            try {
                while (deadline.hasNotPassedNow() && player.isOnline) {
                    val tracker = if (editRegistry.isEditing(player.uniqueId, definition.id)) {
                        null
                    } else {
                        engine.query(data, player)
                    }
                    val transform = tracker?.lastTransform
                    Dispatchers.Sync.switchContext {
                        val world = transform?.let { resolveBukkitWorld(it.world.identifier) }
                        if (tracker == null || transform == null || world == null) {
                            outline.despawn()
                        } else {
                            val anchor = transform.worldOrigin
                            outline.update(
                                Location(world, anchor.x, anchor.y, anchor.z),
                                transform.yawDegrees,
                                transform.pitchDegrees,
                                tracker.shape,
                                color,
                                rollDegrees = transform.rollDegrees,
                            )
                        }
                    }
                    delay(TICK_MS.milliseconds)
                }
            } finally {
                withContext(NonCancellable) {
                    Dispatchers.Sync.switchContext { outline.despawn() }
                }
            }
        }
        sessions.put(key, job)?.cancel()
        job.invokeOnCompletion { sessions.remove(key, job) }
    }

    /** Stops an active session. Returns `false` when none was active. */
    fun hide(player: Player, definition: RegionDefinitionEntry): Boolean {
        val job = sessions.remove(SessionKey(player.uniqueId, definition.id)) ?: return false
        job.cancel()
        return true
    }

    /** Stops every active session of [player]. Returns how many were active. */
    fun hideAll(player: Player): Int {
        var count = 0
        val iterator = sessions.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.key.playerId != player.uniqueId) continue
            iterator.remove()
            entry.value.cancel()
            count++
        }
        return count
    }

    private data class SessionKey(val playerId: UUID, val definitionId: String)
}

/**
 * Highlights one block with a glowing wireframe box for up to [Duration], so a player running
 * `/tw region flags` can see which block the report is about. One highlight per player: showing
 * a new one replaces the last.
 *
 * The box is spawned once, since the aimed block does not move, but the session keeps polling
 * until the duration elapses so the box is despawned as soon as the player quits.
 */
@Singleton
class FlagHighlighter : Initializable, KoinComponent {
    private val sessions = ConcurrentHashMap<UUID, Job>()
    private var scope: CoroutineScope? = null

    override suspend fun initialize() {
        scope = CoroutineScope(SupervisorJob() + Dispatchers.UntickedAsync)
    }

    override suspend fun shutdown() {
        val scope = this.scope ?: return
        this.scope = null
        scope.coroutineContext.job.cancelAndJoinBounded()
        sessions.clear()
    }

    /**
     * Draws a glowing box around [block], visible only to [player], for [duration], ending early
     * if [player] disconnects first.
     */
    fun show(player: Player, block: Block, duration: Duration) {
        val scope = scope ?: return
        val anchor = block.location
        val glow = org.bukkit.Color.fromRGB(255, 70, 70)
        val deadline = TimeSource.Monotonic.markNow() + duration

        val job = scope.launch {
            val guide = GuideDisplay(player)
            try {
                Dispatchers.Sync.switchContext {
                    guide.update(anchor, BLOCK_OUTLINE_SEGMENTS, Material.RED_CONCRETE, glow, HIGHLIGHT_THICKNESS)
                }
                while (deadline.hasNotPassedNow() && player.isOnline) {
                    delay(TICK_MS.milliseconds)
                }
            } finally {
                withContext(NonCancellable) {
                    Dispatchers.Sync.switchContext { guide.despawn() }
                }
            }
        }
        sessions.put(player.uniqueId, job)?.cancel()
        job.invokeOnCompletion { sessions.remove(player.uniqueId, job) }
    }

    companion object {
        private const val HIGHLIGHT_THICKNESS = 0.06f
    }
}
