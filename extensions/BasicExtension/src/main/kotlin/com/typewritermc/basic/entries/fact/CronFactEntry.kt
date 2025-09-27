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
import com.typewritermc.engine.paper.utils.CronExpression
import java.time.Duration
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import kotlin.time.toKotlinDuration

@Entry("cron_fact", "Saved until a specified date, like (0 0 * * 1)", Colors.PURPLE, "mingcute:calendar-time-add-fill")
/**
 * A [fact](/docs/creating-stories/facts) that is saved until a specified date, like (0 0 \* \* 1).
 *
 * ## How could this be used?
 *
 * This fact could be used to create weekly rewards, which are reset every week. Or to simulate the opening hours of a shop.
 */
class CronFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("The cron expression when the fact expires.")
    // The <Link to="https://www.netiq.com/documentation/cloud-manager-2-5/ncm-reference/data/bexyssf.html">Cron Expression</Link> when the fact expires.
    val cron: CronExpression = CronExpression.default(),
) : ExpirableFactEntry, PersistableFactEntry {
    override fun hasExpired(id: FactId, data: FactData): Boolean {
        return cron.nextLocalDateTimeAfter(data.lastUpdate).isBefore(LocalDateTime.now())
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super<ExpirableFactEntry>.parser())

        literal("time") {
            literal("expires") {
                literal("relative") {
                    supplyPlayer { player ->
                        val lastUpdate = readForPlayersGroup(player).lastUpdate
                        val expires = cron.nextLocalDateTimeAfter(lastUpdate)
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
                    val expires = cron.nextLocalDateTimeAfter(lastUpdate)

                    expires.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
                }
            }
        }
    }
}