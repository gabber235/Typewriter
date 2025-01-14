package com.typewritermc.engine.paper.entry.temporal

import com.typewritermc.core.entries.Query
import com.typewritermc.core.interaction.Interaction
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.entry.temporal.TemporalState.*
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.events.AsyncCinematicEndEvent
import com.typewritermc.engine.paper.events.AsyncCinematicStartEvent
import com.typewritermc.engine.paper.events.AsyncCinematicTickEvent
import com.typewritermc.engine.paper.interaction.*
import com.typewritermc.engine.paper.utils.ThreadType.DISPATCHERS_ASYNC
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent
import java.time.Duration

class TemporalInteraction(
    val pageId: String,
    private val player: Player,
    override val context: InteractionContext,
    val eventTriggers: List<EventTrigger>,
    private val settings: TemporalSettings,
) : Interaction {
    internal var state = STARTING
        private set
    private var playTime = Duration.ofMillis(-1)
    private val frame: Int get() = (playTime.toMillis() / 50).toInt()

    override val priority by lazy { Query.findPageById(pageId)?.priority ?: 0 }

    private lateinit var actions: List<CinematicAction>

    override suspend fun initialize(): Result<Unit> {
        if (state != STARTING) return failure("Temporal interaction is already initialized")

        if (settings.blockChatMessages) player.startBlockingMessages()
        if (settings.blockActionBarMessages) player.startBlockingActionBar()

        actions = Query.findWhereFromPage<CinematicEntry>(pageId) {
            it.criteria.matches(player, context)
        }.map { it.create(player) }.toList()

        actions.forEach {
            try {
                it.setup()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        state = PLAYING

        DISPATCHERS_ASYNC.switchContext {
            AsyncCinematicStartEvent(player, pageId).callEvent()
        }
        return ok(Unit)
    }

    override suspend fun tick(deltaTime: Duration) {
        if (state != PLAYING) return
        if (canEnd) return

        // Make sure that the first frame is 0
        if (playTime.isNegative) playTime = Duration.ZERO
        else playTime += deltaTime

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
        AsyncCinematicTickEvent(player, frame).callEvent()

        if (canEnd) {
            TemporalStopTrigger.triggerFor(player, context)
        }
    }

    private val canEnd get() = actions.all { it.canFinish(frame) }

    override suspend fun teardown(force: Boolean) {
        if (state != PLAYING) return
        state = ENDING
        val originalFrame = frame

        if (settings.blockChatMessages) {
            player.stopBlockingMessages()
            player.chatHistory.resendMessages(player)
        }
        if (settings.blockActionBarMessages) player.stopBlockingActionBar()

        actions.forEach {
            try {
                it.teardown()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        if (force) return

        DISPATCHERS_ASYNC.switchContext {
            AsyncCinematicEndEvent(player, originalFrame, pageId).callEvent()
        }
    }

    fun playTime(playTime: Duration) {
        if (state != PLAYING) return
        this.playTime = playTime
    }

    fun frame(frame: Int) = playTime(Duration.ofMillis(frame * 50L))
}

internal enum class TemporalState {
    STARTING, PLAYING, ENDING
}

private val Player.temporalInteraction: TemporalInteraction?
    get() = with(KoinJavaComponent.get<PlayerSessionManager>(PlayerSessionManager::class.java)) {
        session?.interaction as? TemporalInteraction
    }

fun Player.isPlayingTemporal(pageId: String): Boolean = temporalInteraction?.pageId == pageId

fun Player.isPlayingTemporal(): Boolean = temporalInteraction != null

data class TemporalStartTrigger(
    val pageId: String,
    val eventTriggers: List<EventTrigger> = emptyList(),
    val settings: TemporalSettings = TemporalSettings(),
) : EventTrigger {
    val priority: Int by lazy(LazyThreadSafetyMode.NONE) { Query.findPageById(pageId)?.priority ?: 0 }

    override val id: String
        get() = "system.temporal.start.$pageId"
}

data class TemporalSettings(
    val blockChatMessages: Boolean = true,
    val blockActionBarMessages: Boolean = true,
)

data object TemporalStopTrigger : EventTrigger {
    override val id: String
        get() = "system.temporal.stop"
}

data class TemporalSetFrameTrigger(
    val frame: Int,
) : EventTrigger {
    override val id: String
        get() = "system.temporal.setFrame"
}