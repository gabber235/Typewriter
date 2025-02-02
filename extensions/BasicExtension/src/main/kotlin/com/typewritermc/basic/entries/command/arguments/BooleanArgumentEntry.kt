package com.typewritermc.basic.entries.command.arguments

import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.BoolArgumentType
import com.typewritermc.basic.entries.command.ArgumentCommandArgument
import com.typewritermc.basic.entries.command.CommandArgumentEntry
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContextBuilder
import com.typewritermc.engine.paper.entry.TriggerableEntry
import kotlin.reflect.KClass

@Entry("boolean_argument", "A boolean argument", Colors.RED, "fa6-solid:toggle-on")
@ContextKeys(BooleanArgumentContextKeys::class)
/**
 * The `Boolean Argument` entry is an argument that takes a boolean.
 */
class BooleanArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ArgumentCommandArgument<Boolean> {
    override val type: ArgumentType<Boolean> get() = BoolArgumentType.bool()
    override val klass: KClass<Boolean> get() = Boolean::class

    override fun InteractionContextBuilder.apply(value: Boolean) {
        set(BooleanArgumentContextKeys.VALUE, value)
    }
}

enum class BooleanArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Boolean::class)
    VALUE(Boolean::class)
}