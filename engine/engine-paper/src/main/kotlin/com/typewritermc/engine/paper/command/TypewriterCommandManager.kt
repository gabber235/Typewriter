package com.typewritermc.engine.paper.command

import com.mojang.brigadier.CommandDispatcher
import com.mojang.brigadier.builder.LiteralArgumentBuilder
import com.mojang.brigadier.tree.CommandNode
import com.mojang.brigadier.tree.LiteralCommandNode
import com.typewritermc.core.entries.Query
import com.typewritermc.engine.paper.command.dsl.DslCommand
import com.typewritermc.engine.paper.entry.entries.CustomCommandEntry
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.server
import io.papermc.paper.command.brigadier.CommandSourceStack
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType


@Suppress("UnstableApiUsage")
class TypewriterCommandManager {
    private var dispatcher: CommandDispatcher<CommandSourceStack>? = null
    private var commandsLabels = emptyList<String>()

    val labels: List<String>
        get() = commandsLabels

    fun registerDispatcher(dispatcher: CommandDispatcher<CommandSourceStack>) {
        this.dispatcher = dispatcher
    }

    fun registerCommands() {
        val dispatcher = this.dispatcher
        if (dispatcher == null) {
            throw IllegalStateException("TypewriterCommandManager has not been initialized with a dispatcher")
        }

        val commands = listOf(
            typewriterCommand(),
        ) + Query.find<CustomCommandEntry>().map { it.command() }

        commandsLabels = commands.flatMap {
            dispatcher.register(it, plugin.name.lowercase())
        }

        server.onlinePlayers.forEach {
            it.updateCommands()
        }
    }


    fun unregisterCommands() {
        val dispatcher = this.dispatcher
        if (dispatcher == null) {
            throw IllegalStateException("TypewriterCommandManager has not been initialized with a dispatcher")
        }

        commandsLabels.forEach {
            dispatcher.unregister(it)
        }
    }
}

private val removeCommandMethod by lazy {
    MethodHandles.lookup().findVirtual(
        CommandNode::class.java,
        "removeCommand",
        MethodType.methodType(Void.TYPE, String::class.java)
    )
}

fun <S> CommandDispatcher<S>.unregister(literal: String) {
    try {
        removeCommandMethod.invoke(this.root, literal)
    } catch (e: Throwable) {
        e.printStackTrace()
    }
}

fun <S> CommandDispatcher<S>.register(command: DslCommand<S>, identifier: String): List<String> {
    val commandsLabels = mutableListOf<String>()
    val sourceCommand = LiteralArgumentBuilder.literal<S>("$identifier:${command.literal}")
        .executes(command.node.command)
        .requires(command.node.requirement)
        .build()
        .apply {
            command.node.children.forEach(this::addChild)
        }

    register(sourceCommand)
    commandsLabels.add(sourceCommand.literal)

    registerRedirect(command.literal, sourceCommand)
    commandsLabels.add(command.literal)

    command.aliases.forEach {
        registerRedirect(it, sourceCommand)
        commandsLabels.add(it)

        val alias = "$identifier:$it"
        registerRedirect(alias, sourceCommand)
        commandsLabels.add(alias)
    }

    return commandsLabels
}

fun <S> CommandDispatcher<S>.registerRedirect(aliasLiteral: String, target: LiteralCommandNode<S>) {
    val redirect = LiteralArgumentBuilder.literal<S>(aliasLiteral)
        .executes(target.command)
        .redirect(target)
        .requires(target.requirement)
        .build()

    register(redirect)
}

private fun <S> CommandDispatcher<S>.register(node: LiteralCommandNode<S>) {
    root.getChild(node.literal)?.let {
        unregister(node.literal)
    }
    root.addChild(node)
}