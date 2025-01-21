package com.typewritermc.basic.entries.audience

import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.ThreadType
import org.bukkit.entity.Player
import java.time.Duration
import java.util.*

@Entry(
    "timer_audience",
    "Triggers an action every specified duration when the player is in the audience",
    Colors.GREEN,
    "mdi:timer-outline"
)
/**
 * The `Timer Audience` entry is an audience filter that triggers an action every specified duration when the player is in the audience.
 *
 * :::caution
 * Very short durations can cause performance issues, and may be inaccurate.
 * :::
 *
 * ## How could this be used?
 * This can be used to trigger a sequence every few seconds.
 */
class TimerAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    val duration: Var<Duration> = ConstVar(Duration.ofSeconds(1)),
    val onTimer: Ref<TriggerableEntry> = emptyRef(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = TimerAudienceDisplay(duration, onTimer)
}

class TimerAudienceDisplay(
    private val duration: Var<Duration>,
    private val onTimer: Ref<TriggerableEntry>,
) : AudienceDisplay() {
    private val jobs = mutableMapOf<UUID, Job>()

    override fun onPlayerAdd(player: Player) {
        val duration = duration.get(player)
        if (duration.isZero || duration.isNegative) {
            logger.warning("Timer duration must be positive, otherwise it will infinitely trigger.")
            return
        }
        jobs[player.uniqueId] = ThreadType.DISPATCHERS_ASYNC.launch {
            while (player in this) {
                delay(duration.toMillis())
                onTimer.triggerFor(player, context())
            }
        }
    }

    override fun onPlayerRemove(player: Player) {
        jobs[player.uniqueId]?.cancel()
    }
}