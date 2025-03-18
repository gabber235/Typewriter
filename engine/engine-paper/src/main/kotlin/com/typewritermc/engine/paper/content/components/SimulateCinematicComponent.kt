package com.typewritermc.engine.paper.content.components

import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Page
import com.typewritermc.core.entries.Query
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.components.ItemInteractionType.*
import com.typewritermc.engine.paper.content.pageId
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.maxFrame
import com.typewritermc.engine.paper.interaction.*
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.*
import io.papermc.paper.event.player.AsyncChatEvent
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import net.kyori.adventure.bossbar.BossBar
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerItemHeldEvent
import org.bukkit.inventory.ItemStack
import java.time.Duration
import java.time.Instant
import java.util.*
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.toKotlinDuration

fun ContentMode.cinematic(context: ContentContext) = +SimulateCinematicComponent(context)

class SimulateCinematicComponent(
    private val context: ContentContext,
) : CompoundContentComponent(), ItemsComponent, Listener {
    private var actions = emptyList<CinematicAction>()
    private var maxFrame = 0

    private var playbackSpeed = 0.0
    private var partialFrame: Double = 0.0
        set(value) {
            field = value.coerceIn(0.0, maxFrame.toDouble())
        }
    val frame: Int
        get() = partialFrame.toInt()

    private val scrollVelocity: ScrollVelocity = ScrollVelocity()

    // If we are in scrolling modes where we scroll through the frames. If set to the UUID of the player
    private var scrollFrames: UUID? = null

    // If we are requiring the player to input a specific frame. If set to the UUID of the player
    private var inputting: UUID? = null

    override suspend fun initialize(player: Player) {
        val page = findCinematicPageById(context.pageId) ?: return

        actions = page.entries.filterIsInstance<CinematicEntry>().mapNotNull { it.createSimulating(player) }

        plugin.registerEvents(this)
        player.startBlockingActionBar()

        actions.forEach {
            try {
                it.setup()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }


        maxFrame = actions.maxFrame()

        bossBar {
            val frameDisplay = "$frame".padStart(maxFrame.digits)
            var prefix = ""

            if (scrollFrames != null) prefix += " <gradient:#9452ff:#ff2eea><b>(Scrolling)</b></gradient>"
            if (inputting != null) prefix += " <gradient:#52a3ff:#2effea><b>(Inputting)</b></gradient>"

            if (prefix.isNotBlank()) prefix = " <gray>-$prefix"

            title =
                "<yellow><bold>${page.id} <reset><gray>- <white>$frameDisplay/$maxFrame (${playbackSpeed}x)$prefix"
            color = when {
                scrollFrames != null -> BossBar.Color.PURPLE
                inputting != null -> BossBar.Color.BLUE
                playbackSpeed == 0.0 -> BossBar.Color.RED
                else -> BossBar.Color.YELLOW
            }
            overlay = BossBar.Overlay.NOTCHED_20
            progress = (partialFrame / maxFrame).toFloat()
        }

        super.initialize(player)
    }

    override suspend fun tick(player: Player) {
        partialFrame += playbackSpeed

        if (frame >= maxFrame) {
            playbackSpeed = 0.0
        }

        if (frame <= 0) {
            playbackSpeed = 0.0
        }

        coroutineScope {
            actions.map {
                launch {
                    try {
                        it.tick(frame)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }.joinAll()
        }

        super.tick(player)
    }

    @EventHandler
    private fun onScroll(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != scrollFrames) return
        val delta = loopingDistance(event.previousSlot, event.newSlot, 8)
        partialFrame += delta * if (delta > 0) scrollVelocity.forward() else scrollVelocity.backward()
        event.player.playSound("block.note_block.hat", pitch = 1f + (delta * 0.1f), volume = 0.5f)
        event.isCancelled = true
    }

    private fun startInputting(player: Player) {
        if (inputting != null) return
        inputting = player.uniqueId
        player.playSound("block.amethyst_block.hit")
        player.startBlockingMessages()
        player.sendInputMessage("Type frame in chat")
    }

    @EventHandler(priority = EventPriority.LOW)
    private fun onChat(event: AsyncChatEvent) {
        val player = event.player
        if (inputting != player.uniqueId) return
        event.isCancelled = true
        val frame = event.message().plainText().toIntOrNull()
        if (frame == null || frame < 0 || frame > maxFrame) {
            player.sendInputMessage("<red>Frame must be between 0 and $maxFrame")
            return
        }

        partialFrame = frame.toDouble()
        player.playSound("block.amethyst_block.hit")
        endInputting(player)
    }

    private fun Player.sendInputMessage(infoText: String) {
        val charactersLeft = (50 - infoText.stripped().length).coerceAtLeast(0)
        val charactersPadding = charactersLeft / 2

        sendMessage(
            chatHistory.composeDarkMessage(
                """
	        |<gray><st>${" ".repeat(60)}</st>
            |
            |<white><b>Enter a frame number:</b>
            |
            |<gray><info_padding><info_text>
	        |<gray><st>${" ".repeat(60)}</st>
        """.trimMargin().asMiniWithResolvers(
                    Placeholder.parsed("info_text", infoText),
                    Placeholder.unparsed("info_padding", " ".repeat(charactersPadding)),
                )
            )
        )
    }

    private fun endInputting(player: Player) {
        if (inputting != player.uniqueId) return
        inputting = null
        player.playSound("block.amethyst_block.fall")
        player.stopBlockingMessages()
        player.chatHistory.resendMessages(player)
    }

    override suspend fun dispose(player: Player) {
        unregister()
        player.stopBlockingActionBar()
        endInputting(player)
        actions.forEach {
            try {
                it.teardown()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        actions = emptyList()
        super.dispose(player)
    }

    override fun items(player: Player): Map<Int, IntractableItem> {
        val playbackSpeed = ItemStack(Material.CLOCK).apply {
            editMeta { meta ->
                meta.name = "<yellow><bold>Playback Speed"
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
                RIGHT_CLICK -> playbackSpeed += 1
                SHIFT_RIGHT_CLICK -> playbackSpeed += 0.25
                LEFT_CLICK -> playbackSpeed -= 1
                SHIFT_LEFT_CLICK -> playbackSpeed -= 0.25
                DROP -> partialFrame = 0.0
                SWAP -> playbackSpeed = if (playbackSpeed != 0.0) 0.0 else 1.0
                else -> {
                    return@onInteract
                }
            }
            player.playSound("ui.button.click")
        }

        val skip = ItemStack(Material.AMETHYST_SHARD).apply {
            editMeta { meta ->
                meta.name = "<yellow><bold>Skip Frame"
                meta.loreString = """
                    |<line> <green><b>Right Click: </b><white>Goes forward (with velocity)
                    |<line> <green>Shift + Right Click: <white>Goes forward 1 frames
                    |<line> <red><b>Left Click: </b><white>Goes backwards (with velocity)
                    |<line> <red>Shift + Left Click: <white>Goes backwards 1 frames
                    |<line> <yellow><b><key:key.drop>: </b><white>Input a specific frame
                    |<line> <blue><b><key:key.swapOffhand>: </b><white>Go into advanced playback control mode
                """.trimMargin()
            }
        } onInteract { (type) ->
            when (type) {
                RIGHT_CLICK -> partialFrame += scrollVelocity.forward()
                SHIFT_RIGHT_CLICK -> partialFrame += 1
                LEFT_CLICK -> partialFrame -= scrollVelocity.backward()
                SHIFT_LEFT_CLICK -> partialFrame -= 1
                DROP -> {
                    if (inputting == null) {
                        startInputting(player)
                    } else {
                        endInputting(player)
                    }
                }

                SWAP -> {
                    scrollFrames = if (scrollFrames == null) {
                        player.playSound("block.amethyst_block.hit")
                        player.uniqueId
                    } else {
                        player.playSound("block.amethyst_block.fall")
                        null
                    }
                }

                else -> {
                    return@onInteract
                }
            }
            player.playSound("ui.button.click")
        }

        return mapOf(
            0 to playbackSpeed,
            1 to skip,
        )
    }
}

fun findCinematicPageById(pageId: String?): Page? {
    if (pageId.isNullOrEmpty()) {
        logger.warning("Can only simulate cinematic for a page")
        return null
    }

    val page = Query.findPageById(pageId)
    if (page == null) {
        logger.warning("Page $pageId not found, make sure to publish before using content mode")
        return null
    }

    if (page.type != PageType.CINEMATIC) {
        logger.warning("Page $pageId is not a cinematic page")
        return null
    }
    return page
}

private class ScrollVelocity(
    private val minimum: Int = 10,
) {
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

        // Only in steps
        velocity += (acceleration / 5) * 5
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

    private enum class VelocityDirection {
        FORWARD,
        BACKWARD
    }
}