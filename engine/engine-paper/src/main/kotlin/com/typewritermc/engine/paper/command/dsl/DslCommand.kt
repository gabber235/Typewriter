package com.typewritermc.engine.paper.command.dsl

import com.mojang.brigadier.tree.CommandNode

fun <S> command(
    literal: String,
    vararg aliases: String,
    builder: LiteralCommandTree<S>.() -> Unit
): DslCommand<S> {
    val node = LiteralCommandTree<S>(literal).apply(builder).build()
    return DslCommand(literal, aliases.toList(), node)
}

class DslCommand<S>(
    val literal: String,
    val aliases: List<String> = emptyList(),
    val node: CommandNode<S>,
)

