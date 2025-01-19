package com.typewritermc.engine.paper.entry

import com.google.gson.annotations.SerializedName
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Negative
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.WritableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import org.bukkit.entity.Player

@Tags("static")
interface StaticEntry : Entry

@Tags("manifest")
interface ManifestEntry : Entry


enum class CriteriaOperator {
    @SerializedName("==")
    EQUALS,

    @SerializedName("<")
    LESS_THAN,

    @SerializedName(">")
    GREATER_THAN,

    @SerializedName("<=")
    LESS_THAN_OR_EQUALS,

    @SerializedName(">=")
    GREATER_THAN_OR_EQUAL,

    @SerializedName("!=")
    NOT_EQUALS

    ;

    fun isValid(value: Int, criteria: Int): Boolean {
        return when (this) {
            EQUALS -> value == criteria
            LESS_THAN -> value < criteria
            GREATER_THAN -> value > criteria
            LESS_THAN_OR_EQUALS -> value <= criteria
            GREATER_THAN_OR_EQUAL -> value >= criteria
            NOT_EQUALS -> value != criteria
        }
    }
}

data class Criteria(
    @Help("The fact to check before triggering the entry")
    val fact: Ref<ReadableFactEntry> = emptyRef(),
    @Help("The operator to use when comparing the fact value to the criteria value")
    val operator: CriteriaOperator = CriteriaOperator.EQUALS,
    @Help("The value to compare the fact value to")
    @Negative
    val value: Var<Int> = ConstVar(0),
) {
    fun isValid(fact: FactData?, player: Player, context: InteractionContext): Boolean {
        val value = fact?.value ?: 0
        return operator.isValid(value, this.value.get(player, context))
    }
}

fun Iterable<Criteria>.matches(player: Player, context: InteractionContext = context()): Boolean = all {
    val entry = it.fact.get()
    val fact = entry?.readForPlayersGroup(player)
    it.isValid(fact, player, context)
}

enum class ModifierOperator {
    @SerializedName("=")
    SET,

    @SerializedName("+")
    ADD,

    @SerializedName("*")
    MULTIPLY,
    ;
}

data class Modifier(
    @Help("The fact to modify after the entry is completed")
    val fact: Ref<WritableFactEntry> = emptyRef(),
    @Help("The operator to use when modifying the fact value")
    val operator: ModifierOperator = ModifierOperator.ADD,
    @Help("The value to modify the fact value by")
    @Negative
    val value: Var<Int> = ConstVar(0),
)
