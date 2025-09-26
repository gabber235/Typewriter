package com.typewritermc.basic.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.formatCompact
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.ExpirableFactEntry
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.PersistableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.facts.FactId
import java.time.Duration
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import kotlin.time.toKotlinDuration

@Entry("timed_fact", "Saved for a specified duration, like 20 minutes", Colors.PURPLE, "bi:stopwatch-fill")
/**
 * This fact is stored for a certain amount of time.
 * After that time, it is reset.
 *
 * ## How could this be used?
 *
 * This fact could serve as a timer, and when the fact runs out, it could be used to trigger an action.
 */
class TimedFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("The duration after which the fact expires.")
    val duration: Duration = Duration.ZERO,
) : ExpirableFactEntry, PersistableFactEntry {
    override fun hasExpired(id: FactId, data: FactData): Boolean {
        return LocalDateTime.now().isAfter(data.lastUpdate.plus(duration))
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super<ExpirableFactEntry>.parser())

        literal("time") {
            literal("expires") {
                literal("relative") {
                    supplyPlayer { player ->
                        val lastUpdate = readForPlayersGroup(player).lastUpdate
                        val expires = lastUpdate + duration
                        val now = LocalDateTime.now()
                        if (now.isAfter(expires)) {
                            return@supplyPlayer "now"
                        }
                        val difference =
                            Duration.between(now, expires).toKotlinDuration()

                        difference.formatCompact()
                    }
                }

                supplyPlayer { player ->
                    val lastUpdate = readForPlayersGroup(player).lastUpdate
                    val expires = lastUpdate + duration

                    expires.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
                }
            }
        }
    }
}
