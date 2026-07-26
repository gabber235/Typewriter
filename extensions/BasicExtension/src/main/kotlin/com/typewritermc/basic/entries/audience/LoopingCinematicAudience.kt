package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Query
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Page
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.toTicks
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import org.bukkit.entity.Player
import java.time.Duration
import java.time.Instant
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "looping_cinematic_audience",
    "Show the audience members a cinematic that loops",
    Colors.GREEN,
    "mdi:movie-open-play"
)
/**
 * The `Looping Cinematic Audience` entry is used to show the audience members a cinematic that loops.
 *
 * **It is recommended that this entry is bounded by location or region,
 * to prevent players from receiving packets for cinematics they cannot see.**
 *
 * :::caution
 * The Cinematic can only have entries that are compatible with looping (non-primary entries).
 * Anything that cannot have two or more instances active at once will not work.
 * :::
 *
 * ## How could this be used?
 * To display particles on a loop, such as a fountain.
 * Or sparks that come from a broken wire.
 */
class LoopingCinematicAudience(
    override val id: String = "",
    override val name: String = "",
    @Page(PageType.CINEMATIC)
    val cinematicId: String = "",
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        val entries = Query.findWhereFromPage<CinematicEntry>(cinematicId) { true }.toList()

        val inValidEntries = entries.filterIsInstance<PrimaryCinematicEntry>().map { it.name }

        if (inValidEntries.isNotEmpty()) {
            logger.warning("The cinematic $cinematicId has primary entries that cannot be looped: $inValidEntries, skipping these entries.")
        }

        val loopingEntries = entries.filter { it !is PrimaryCinematicEntry }

        return LoopingCinematicAudienceDisplay(loopingEntries)
    }
}

private class LoopingCinematicAudienceDisplay(
    private val loopingEntries: List<CinematicEntry>,
) : AudienceDisplay(), TickableDisplay {
    private val tracked = ConcurrentHashMap<UUID, LoopingCinematicPlayerDisplay>()

    override fun tick() {
        tracked.values.forEach { it.tick() }
    }

    override fun onPlayerAdd(player: Player) {
        tracked[player.uniqueId] = LoopingCinematicPlayerDisplay(player, loopingEntries)
    }

    override fun onPlayerRemove(player: Player) {
        tracked.remove(player.uniqueId)?.teardown()
    }
}

private class LoopingCinematicPlayerDisplay(
    private val player: Player,
    private val loopingEntries: List<CinematicEntry>,
) {
    private var display = setupDisplay()

    private fun setupDisplay(after: Job? = null): CinematicDisplay {
        val actions = loopingEntries.filter { it.criteria.matches(player) }.map { it.create(player) }
        return CinematicDisplay(actions).also { it.setup(after) }
    }

    fun tick() {
        display.tick()

        if (!display.isFinished) return
        // The next round only starts once the previous one has stopped, otherwise the teardown of the
        // round that just ended can cut off what the new one already started.
        display = setupDisplay(after = display.teardown())
    }

    fun teardown() {
        display.teardown()
    }
}

private class CinematicDisplay(
    private val actions: List<CinematicAction>,
) {
    private var startTime: Instant? = null

    // Setting up and tearing down run off the ticking thread, so they are chained to keep a teardown
    // from overtaking the setup it is meant to undo.
    private var lifecycle: Job? = null

    val frame: Int
        get() = if (startTime != null) Duration.between(startTime, Instant.now()).toTicks().toInt() else 0

    val isFinished: Boolean
        get() = actions.all { it canFinish frame }

    fun setup(after: Job? = null) {
        lifecycle = Dispatchers.UntickedAsync.launch {
            after?.join()
            actions.forEach { it.setup() }
            startTime = Instant.now()
        }
    }

    fun tick() {
        if (startTime == null) return
        val frame = frame
        Dispatchers.UntickedAsync.launch {
            actions.forEach { it.tick(frame) }
        }
    }

    /** @return the job that completes once every action has been torn down. */
    fun teardown(): Job {
        startTime = null
        val previous = lifecycle
        val job = Dispatchers.UntickedAsync.launch {
            previous?.join()
            actions.forEach { it.teardown() }
        }
        lifecycle = job
        return job
    }
}