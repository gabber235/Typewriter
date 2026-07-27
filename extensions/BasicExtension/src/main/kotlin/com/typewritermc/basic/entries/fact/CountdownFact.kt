package com.typewritermc.basic.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
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
import kotlin.math.max
import kotlin.time.Duration.Companion.seconds

private const val NEVER = "never"

@Entry(
    "countdown_fact",
    "A fact that counts down from the set value",
    Colors.PURPLE,
    "ph:clock-countdown-fill"
)
/**
 * The `Countdown Fact` is a fact that reflects the time left since the last set value.
 *
 * When the value is set, it will count every second down from the set value.
 *
 * Suppose the value is set to 10.
 * Then after 3 seconds, the value will be 7.
 *
 * The countdown will continue regardless if the player is online/offline or if the server is online/offline.
 *
 * A negative value never counts down and never expires, so setting the fact to `-1` marks a countdown
 * that was cancelled rather than one that ran out on its own.
 *
 * ## How could this be used?
 * This can be used to create a cooldown on a specific action.
 * For example, daily rewards that the player can only get once a day.
 */
class CountdownFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
) : PersistableFactEntry, ExpirableFactEntry {
    override fun read(id: FactId): FactData {
        val data = super<PersistableFactEntry>.read(id)
        return FactData(calculateValue(data), data.lastUpdate)
    }

    override fun hasExpired(id: FactId, data: FactData): Boolean {
        return calculateValue(data) == 0
    }

    // A negative value is a marker rather than a duration. Counting it down would clamp it to zero,
    // which is the very state it is there to be told apart from.
    private fun calculateValue(data: FactData): Int {
        if (data.value < 0) return data.value
        val timeDifference = Duration.between(data.lastUpdate, LocalDateTime.now())
        return max(0, (data.value - timeDifference.seconds).toInt())
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super<ExpirableFactEntry>.parser())

        literal("time") {
            literal("expires") {
                literal("relative") {
                    supplyPlayer { player ->
                        val value = readForPlayersGroup(player).value
                        if (value < 0) return@supplyPlayer NEVER

                        value.seconds.formatCompact()
                    }
                }

                supplyPlayer { player ->
                    val value = readForPlayersGroup(player).value
                    if (value < 0) return@supplyPlayer NEVER

                    val expireTime = LocalDateTime.now().plusSeconds(value.toLong())
                    expireTime.format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"))
                }
            }
        }
    }
}