package com.typewritermc.basic.entries.fact

import com.mthaler.aparser.arithmetic.Expression
import com.mthaler.aparser.arithmetic.tryEval
import com.mthaler.aparser.util.Try
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.parseDoubleFlexible
import org.bukkit.entity.Player
import kotlin.math.roundToInt

@Entry("calculated_fact", "A fact where the value is calculated", Colors.PURPLE, "fa6-solid:calculator")
/**
 * A [fact](/docs/creating-stories/facts) where the value is calculated.
 * You can use Placeholders and other facts for the value to change dynamically.
 *
 * ## How could this be used?
 * This could be used to show the remaining of something.
 * If the player needs to collect 10 items, and they have collected `3` items, the fact would show `7`.
 */
class CalculatedFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Placeholder val expression: String = "",
) : ReadableFactEntry {
    private val placeholderRegex by lazy(LazyThreadSafetyMode.NONE) { Regex("[%]([^%]+)[%]") }

    override fun readSinglePlayer(player: Player): FactData {
        val processedExpression = placeholderRegex.replace(this.expression) { matchResult ->
            val placeholder = matchResult.value
            val resolvedValue = placeholder.parsePlaceholders(player).trim()
            val number = resolvedValue.parseDoubleFlexible()
            number?.toString() ?: resolvedValue
        }.trim()

        if (processedExpression.isBlank()) {
            return FactData(0)
        }

        val result = Expression(processedExpression).tryEval()

        return when (result) {
            is Try.Success -> FactData(result.value.roundToInt())
            is Try.Failure -> {
                logger.warning(
                    "Could not evaluate processed expression '$processedExpression' (original: '${this.expression}') for player ${player.name} for fact $id"
                )
                FactData(0)
            }
        }
    }
}