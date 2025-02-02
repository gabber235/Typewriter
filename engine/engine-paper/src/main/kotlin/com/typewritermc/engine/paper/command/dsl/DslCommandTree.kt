package com.typewritermc.engine.paper.command.dsl

import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.builder.ArgumentBuilder
import com.mojang.brigadier.builder.LiteralArgumentBuilder
import com.mojang.brigadier.builder.RequiredArgumentBuilder
import com.mojang.brigadier.context.CommandContext
import com.mojang.brigadier.suggestion.SuggestionProvider
import com.mojang.brigadier.tree.CommandNode
import java.util.function.Predicate
import kotlin.reflect.KClass

class ExecutionContext<S>(
    val context: CommandContext<S>,
) {
    val source: S
        get() = context.source

    operator fun <T : Any> ArgumentReference<T>.invoke(): T {
        return context.getArgument<T>(name, klass.java)
    }

    fun <T : Any> getArgument(name: String, klass: KClass<T>): T {
        return context.getArgument<T>(name, klass.java)
    }
}

typealias Executor<S> = ExecutionContext<S>.() -> Unit

typealias ArgumentBlock<S, T> = ArgumentCommandTree<S, T>.(ArgumentReference<T>) -> Unit

abstract class DslCommandTree<S, A : ArgumentBuilder<S, A>> {
    private val children = mutableListOf<DslCommandTree<S, *>>()
    private var requirement: Predicate<S>? = null
    private var executor: Executor<S>? = null

    fun executes(executor: Executor<S>) {
        this.executor = executor
    }

    fun requires(requirement: Predicate<S>) {
        this.requirement = requirement
    }

    fun literal(literal: String, block: LiteralCommandTree<S>.() -> Unit = {}): LiteralCommandTree<S> {
        val literalCommandTree = LiteralCommandTree<S>(literal).apply(block)
        children.add(literalCommandTree)
        return literalCommandTree
    }

    fun <T : Any> argument(
        name: String,
        type: ArgumentType<T>,
        klass: KClass<T>,
        block: ArgumentBlock<S, T> = {},
    ): ArgumentCommandTree<S, T> {
        val reference = ArgumentReference(name, klass)
        val argumentCommandTree = ArgumentCommandTree<S, T>(name, type).apply { block(reference) }
        children.add(argumentCommandTree)
        return argumentCommandTree
    }

    abstract fun buildArgument(): A
    fun build(): CommandNode<S> {
        val argument = buildArgument()

        requirement?.let {
            argument.requires(it)
        }
        executor?.let {
            argument.executes { context ->
                it(ExecutionContext(context))
                1
            }
        }

        children.map(DslCommandTree<S, *>::build).forEach(argument::then)

        return argument.build()
    }
}

class LiteralCommandTree<S>(
    private val literal: String,
) : DslCommandTree<S, LiteralArgumentBuilder<S>>() {
    override fun buildArgument(): LiteralArgumentBuilder<S> {
        return LiteralArgumentBuilder.literal(literal)
    }
}

class ArgumentCommandTree<S, T>(
    private val name: String,
    private val type: ArgumentType<T>,
) : DslCommandTree<S, RequiredArgumentBuilder<S, T>>() {
    private var suggestionsProvider: SuggestionProvider<S>? = null
    override fun buildArgument(): RequiredArgumentBuilder<S, T> {
        return RequiredArgumentBuilder.argument<S, T>(name, type).suggests(suggestionsProvider)
    }
}

class ArgumentReference<T : Any>(
    val name: String,
    val klass: KClass<T>,
)