package com.typewritermc.engine.paper.content.modes

import com.google.gson.Gson
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.content.*
import com.typewritermc.engine.paper.content.components.*
import com.typewritermc.engine.paper.entry.AssetManager
import com.typewritermc.engine.paper.entry.entries.AssetEntry
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.getAssetFromFieldValue
import com.typewritermc.engine.paper.entry.forceTriggerFor
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.startBlockingActionBar
import com.typewritermc.engine.paper.interaction.stopBlockingActionBar
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType.SYNC
import com.typewritermc.engine.paper.utils.loreString
import com.typewritermc.engine.paper.utils.name
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import net.kyori.adventure.bossbar.BossBar
import net.kyori.adventure.key.Key
import net.kyori.adventure.sound.Sound
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.event.Listener
import org.bukkit.inventory.ItemStack
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import kotlin.reflect.KClass

inline fun <reified F : Frame<F>> ComponentContainer.recordingCinematic(
    context: ContentContext,
    slot: Int,
    noinline frameFetcher: () -> Int,
    noinline modeCreator: (ContentContext, Player, Int) -> RecordingCinematicContentMode<F>,
) = +RecordingCinematicComponent(context, slot, frameFetcher, modeCreator, F::class)

class RecordingCinematicComponent<F : Frame<F>>(
    private val context: ContentContext,
    val slot: Int,
    val frameFetcher: () -> Int,
    val modeCreator: (ContentContext, Player, Int) -> RecordingCinematicContentMode<F>,
    val klass: KClass<F>,
) : ContentComponent, ItemsComponent {
    override suspend fun initialize(player: Player) {}
    override suspend fun tick(player: Player) {}
    override suspend fun dispose(player: Player) {}

    override fun items(player: Player): Map<Int, IntractableItem> {
        if (frameFetcher() > (context.endFrame ?: 0)) {
            val item = ItemStack(Material.BARRIER).apply {
                editMeta { meta ->
                    meta.name = "<red><b>Cannot Start Recording"
                    meta.loreString = """
                    |<line> <gray>Recording cannot start 
                    |<line> <gray>because the frame is out of range.
                    |
                    |<line> <gray>Make sure that the cinematic frame
                    |<line> <gray>is before the end frame of the segment.
                """.trimMargin()
                }
            } onInteract {}
            return mapOf(slot to item)
        }

        val item = ItemStack(Material.BOOK).apply {
            editMeta { meta ->
                meta.name = "<green><b>Start Recording"
                meta.loreString = "<line> <gray>Click to start recording the cinematic."
            }
        } onInteract {
            ContentModeTrigger(context, modeCreator(context, player, frameFetcher())).triggerFor(
                player,
                context()
            )
        }

        return mapOf(slot to item)
    }
}

abstract class RecordingCinematicContentMode<F : Frame<F>>(
    context: ContentContext,
    player: Player,
    private val initialFrame: Int = 0,
) : ContentMode(context, player), Listener, KoinComponent {
    private val gson: Gson by inject(named("bukkitDataParser"))
    private val assetManager: AssetManager by inject()

    private var asset: AssetEntry? = null
    private lateinit var actions: List<CinematicAction>
    private var frame = initialFrame
    private lateinit var frames: IntRange

    private var recorder = Recorder<F>()

    override suspend fun setup(): Result<Unit> {
        val startFrame = context.startFrame
        val endFrame = context.endFrame
        if (startFrame == null || endFrame == null) {
            return failure(
                """
                |Missing startFrame or endFrame in context.
                |Context: $context
                |
                |RecordingCinematicContentMode can only be used for segments of a cinematic.
                |Report this to the extension developer.
            """.trimMargin()
            )
        }

        frames = startFrame..endFrame

        val result = getAssetFromFieldValue(context.fieldValue)
        if (result.isFailure) {
            return failure(
                """
                |Failed to get asset from field value (${context.fieldValue}):
                |${result.exceptionOrNull()?.message}
                |
                |It is likely that you forgot to publish the asset before using it in a content mode.
            """.trimMargin()
            )
        }

        asset = result.getOrThrow()


        val page =
            findCinematicPageById(context.pageId) ?: return failure("No cinematic page found with id ${context.pageId}")

        val entryId = context.entryId

        actions = page.entries.filterIsInstance<CinematicEntry>().mapNotNull {
            if (it.id == entryId) {
                it.createRecording(player)
            } else {
                it.createSimulating(player)
            }
        }

        bossBar {
            color = BossBar.Color.YELLOW
            if (frame < startFrame) {
                val secondsLeft = (startFrame - frame) / 20
                val color = when {
                    secondsLeft <= 1 -> "red"
                    secondsLeft <= 3 -> "#de751f"
                    secondsLeft <= 5 -> "yellow"
                    else -> "green"
                }

                title = "Starting recording in <$color><bold>$secondsLeft</bold></$color>"
                progress = 1f - (frame - initialFrame) / (startFrame - initialFrame).toFloat()
                return@bossBar
            }

            val secondsLeft = (endFrame - frame) / 20
            title = "Recording ends in <bold>$secondsLeft</bold>"
            progress = (frame - frames.first) / (frames.last - frames.first).toFloat()
        }
        return ok(Unit)
    }

    override suspend fun initialize() {
        plugin.registerEvents(this)
        super.initialize()

        // Load in the old tape if it exists
        val asset = asset
            ?: throw IllegalStateException("No asset found for recording cinematic after setup, this should not happen. Asset: '${context.fieldValue}'")
        val oldTapeData = if (assetManager.containsAsset(asset)) assetManager.fetchAsset(asset) else null
        if (oldTapeData != null) {
            recorder = Recorder.create(gson, oldTapeData)
        }
        // If we are starting from the middle of the segment, apply the state
        if (frame > frames.first) {
            applyStartingState()
        }

        player.startBlockingActionBar()

        actions.forEach {
            try {
                it.setup()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override suspend fun tick() {
        frame++
        coroutineScope {
            actions.map {
                launch {
                    try {
                        it.tick(frame.coerceAtLeast(0))
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }.joinAll()
        }
        super.tick()

        if (frame in frames) {
            recordFrame()
        } else if (frame > frames.last) {
            saveStore()
            ContentPopTrigger.forceTriggerFor(player, context())
        } else if (frame < frames.first) {
            preStart(frame)
        }
    }

    private fun preStart(frame: Int) {
        val secondsLeft = (frames.first - frame) / 20

        if (secondsLeft > 5) return
        if ((frames.first - frame) % 20 != 0) return
        player.playSound(
            Sound.sound(
                Key.key("block.note_block.bell"),
                Sound.Source.MASTER,
                1f,
                1f - (secondsLeft * 0.1f)
            )
        )
    }

    abstract fun captureFrame(): F
    abstract fun applyState(value: F)

    private suspend fun applyStartingState() {
        val value = recorder[frame] ?: return
        SYNC.switchContext {
            applyState(value)
        }
    }

    private fun recordFrame() {
        val relativeFrame = frame - frames.first
        val value = captureFrame()
        recorder.record(relativeFrame, value)
    }

    private suspend fun saveStore() {
        val asset = asset ?: return
        val tape = recorder.buildAndOptimize()
        val json = gson.toJsonTree(tape)
        assetManager.storeAsset(asset, json.toString())
    }

    override suspend fun dispose() {
        unregister()
        player.stopBlockingActionBar()
        super.dispose()
        if (!::actions.isInitialized) return
        actions.forEach {
            try {
                it.teardown()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}