@file:Suppress("UnstableApiUsage")

package com.typewritermc.engine.paper.command.dsl

import com.typewritermc.core.entries.Entry
import com.typewritermc.engine.paper.utils.msg
import io.papermc.paper.command.brigadier.CommandSourceStack
import io.papermc.paper.command.brigadier.argument.ArgumentTypes
import io.papermc.paper.command.brigadier.argument.resolvers.selector.PlayerSelectorArgumentResolver
import org.bukkit.command.CommandSender
import org.bukkit.entity.Player

typealias CommandTree = DslCommandTree<CommandSourceStack, *>

val ExecutionContext<CommandSourceStack>.sender: CommandSender
    get() = source.sender

fun CommandTree.withPermission(permission: String): CommandTree {
    requires { it.sender.hasPermission(permission) }
    return this
}

fun CommandTree.requiresPlayer() {
    requires { it.sender is Player || it.executor is Player }
}

fun <S> DslCommandTree<S, *>.playerResolver(
    name: String,
    block: ArgumentBlock<S, PlayerSelectorArgumentResolver> = {},
) = argument(name, ArgumentTypes.player(), block)


fun <S> DslCommandTree<S, *>.playersResolver(
    name: String,
    block: ArgumentBlock<S, PlayerSelectorArgumentResolver> = {},
) = argument(name, ArgumentTypes.players(), block)

fun CommandTree.executePlayerOrTarget(block: ExecutionContext<CommandSourceStack>.(Player) -> Unit) {
    playersResolver("target") { resolver ->
        executes {
            resolver().resolve(source).forEach { player ->
                block(this, player)
            }
        }
    }

    executes {
        (source.executor as? Player)?.let { player ->
            block(this, player)
            return@executes
        }
        (sender as? Player)?.let { player ->
            block(this, player)
            return@executes
        }
        sender.msg("Provide a player to execute this command on.")
    }
}

inline fun <reified E : Entry> CommandTree.entry(
    name: String,
    noinline block: ArgumentBlock<CommandSourceStack, E> = {},
) = argument(name, EntryArgumentType(E::class), E::class, block)
