package com.typewritermc.basic.entries.audience

import com.mthaler.aparser.arithmetic.Context
import com.mthaler.aparser.arithmetic.Expression
import com.mthaler.aparser.arithmetic.TrigonometricUnit
import com.mthaler.aparser.arithmetic.tryEval
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.PriorityEntry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.audience.PlayerSingleDisplay
import com.typewritermc.engine.paper.entry.audience.SingleFilter
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.logger
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

@Entry("experience_audience", "Sets the level and experience for a player to a certain value.", Colors.GREEN, "icon-park-solid:experiment")
/**
 * The `ExpAudienceEntry` is an audience that displays the experience of the player from a value and level requirement.
 *
 * 1. Base experience value (for example `100`)
 * 2. Total experience per level calculation (for example `level² + 10 * level`)
 *
 * | Level |  Calculation  | Total Exp Required |
 * |-------|---------------|--------------------|
 * | 1     | 1² + 10 * 1   | 11                 |
 * | 2     | 2² + 10 * 2   | 24                 |
 * | 3     | 3² + 10 * 3   | 39                 |
 * | 4     | 4² + 10 * 4   | 56                 |
 * | 5     | 5² + 10 * 5   | 75                 |
 * | 6     | 6² + 10 * 6   | 96                 |
 * | 7     | 7² + 10 * 7   | 119                |
 * | 8     | 8² + 10 * 8   | 144                |
 * | 9     | 9² + 10 * 9   | 171                |
 * | 10    | 10² + 10 * 10 | 200                |
 *
 * So a player with exp `100` will be level `6`
 *
 * ## How could this be used?
 * This could be used to show the player a custom level and experience bar.
 */
class ExperienceAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    val experience: Var<Int> = ConstVar(0),
    @Default("\"L^2 + L*10\"")
    @Help("Can be mathematical expression. The expression may contain the variable L, which will be replaced with the player's level.")
    val levelRequirement: String = "L^2 + L*10",
    override val priorityOverride: Optional<Int> = Optional.empty()
) : AudienceFilterEntry, PriorityEntry {
    override val children: List<Ref<out AudienceEntry>> get() = emptyList()
    override suspend fun display(): AudienceFilter = ExpAudienceFilter(ref()) { player ->
        PlayerExpDisplay(player, ExpAudienceFilter::class, ref(), experience, levelRequirement)
    }
}

private class ExpAudienceFilter(
    ref: Ref<ExperienceAudienceEntry>,
    createDisplay: (Player) -> PlayerExpDisplay,
) : SingleFilter<ExperienceAudienceEntry, PlayerExpDisplay>(ref, createDisplay) {
    override val displays: MutableMap<UUID, PlayerExpDisplay>
        get() = map

    companion object {
        private val map = ConcurrentHashMap<UUID, PlayerExpDisplay>()
    }
}

private class PlayerExpDisplay(
    player: Player,
    displayKClass: KClass<out SingleFilter<ExperienceAudienceEntry, *>>,
    current: Ref<ExperienceAudienceEntry>,
    private val experience: Var<Int>,
    private val levelRequirement: String,
) : PlayerSingleDisplay<ExperienceAudienceEntry>(player, displayKClass, current), TickableDisplay {
    private var originalExperienceLevel: ExperienceLevel? = null
    private var currentExperience: Int? = null
    private val expression = Expression(levelRequirement)

    override fun initialize() {
        originalExperienceLevel = ExperienceLevel(player.exp, player.level)
        super.initialize()
    }

    override fun setup() {
        super.setup()
        updateLevel()
    }

    override fun tick() {
        updateLevel()
    }

    override fun dispose() {
        super.dispose()
        originalExperienceLevel?.let { old ->
            player.exp = old.exp
            player.level = old.level
        }
    }

    private fun updateLevel() {
        val exp = experience.get(player)
        if (exp == currentExperience) return
        currentExperience = exp
        val level = calculateLevel(exp)
        player.exp = level.exp
        player.level = level.level
    }

    private fun calculateLevel(experience: Int): ExperienceLevel {
        val levelRequirement = levelRequirement(1)
        if (experience < levelRequirement) {
            val progress = experience.toFloat() / levelRequirement
            return ExperienceLevel(progress.coerceIn(0f..1f), 0)
        }

        var lower = 1
        var upper = 2
        while (levelRequirement(upper) <= experience) {
            lower = upper
            upper *= 2
        }

        while (lower < upper - 1) {
            val mid = (lower + upper) / 2
            if (levelRequirement(mid) <= experience) {
                lower = mid
            } else {
                upper = mid
            }
        }

        val currentLevelExp = levelRequirement(lower)
        val nextLevelExp = levelRequirement(lower + 1)
        val progress = (experience - currentLevelExp).toFloat() / (nextLevelExp - currentLevelExp)

        return ExperienceLevel(progress.coerceIn(0f..1f), lower.coerceAtLeast(1))
    }

    private fun levelRequirement(level: Int): Int {
        val context = Context(TrigonometricUnit.Rad, mapOf(Pair("L", level.toDouble())))
        return when (val expressionResult = expression.tryEval(context)) {
            is com.mthaler.aparser.util.Try.Success -> expressionResult.value.toInt()
            is com.mthaler.aparser.util.Try.Failure -> {
                logger.warning("Could not evaluate expression '$levelRequirement' for player for level $level")
                return 1
            }
        }
    }
}

private data class ExperienceLevel(
    val exp: Float,
    val level: Int,
)