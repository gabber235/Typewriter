package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.server
import net.kyori.adventure.bossbar.BossBar
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry("boss_bar", "Boss Bar", Colors.GREEN, "carbon:progress-bar")
/**
 * The `BossBarEntry` is a display that shows a bar at the top of the screen.
 *
 * ## How could this be used?
 * This could be used to show objectives in a quest, or to show the progress of a task.
 */
class BossBarEntry(
    override val id: String = "",
    override val name: String = "",
    @Colored
    @Placeholder
    @LabelKey("basic.boss_bar.fields.title.label")
    @Help(key = "basic.boss_bar.fields.title.help")
    val title: Var<String> = ConstVar(""),
    @LabelKey("basic.boss_bar.fields.progress.label")
    @Help(key = "basic.boss_bar.fields.progress.help")
    val progress: Var<Double> = ConstVar(1.0),
    @LabelKey("basic.boss_bar.fields.color.label")
    @Help(key = "basic.boss_bar.fields.color.help")
    val color: Var<BossBar.Color> = ConstVar(BossBar.Color.WHITE),
    @LabelKey("basic.boss_bar.fields.style.label")
    @Help(key = "basic.boss_bar.fields.style.help")
    val style: Var<BossBar.Overlay> = ConstVar(BossBar.Overlay.PROGRESS),
    @LabelKey("basic.boss_bar.fields.flags.label")
    @Help(key = "basic.boss_bar.fields.flags.help")
    val flags: List<BossBar.Flag> = emptyList(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        return BossBarDisplay(title, progress, color, style, flags)
    }
}

class BossBarDisplay(
    private val title: Var<String>,
    private val progress: Var<Double>,
    private val color: Var<BossBar.Color>,
    private val style: Var<BossBar.Overlay>,
    private val flags: List<BossBar.Flag>,
) : AudienceDisplay(), TickableDisplay {
    private val bars = ConcurrentHashMap<UUID, BossBar>()

    override fun tick() {
        for ((id, bar) in bars) {
            val player = server.getPlayer(id) ?: continue
            bar.name(title.get(player).parsePlaceholders(id).asMini())
            bar.progress(progress.get(player).toFloat().coerceIn(0.0f, 1.0f))
            bar.color(color.get(player))
            bar.overlay(style.get(player))
        }
    }

    override fun onPlayerAdd(player: Player) {
        val bar = BossBar.bossBar(
            title.get(player).parsePlaceholders(player).asMini(),
            progress.get(player).toFloat().coerceIn(0.0f, 1.0f),
            color.get(player),
            style.get(player),
            flags.toSet()
        )
        bars[player.uniqueId] = bar
        player.showBossBar(bar)
    }

    override fun onPlayerRemove(player: Player) {
        bars.remove(player.uniqueId)?.let { player.hideBossBar(it) }
    }
}