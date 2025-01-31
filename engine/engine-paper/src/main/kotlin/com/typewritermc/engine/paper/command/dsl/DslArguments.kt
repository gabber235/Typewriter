package com.typewritermc.engine.paper.command.dsl

import com.mojang.brigadier.arguments.ArgumentType
import com.mojang.brigadier.arguments.BoolArgumentType
import com.mojang.brigadier.arguments.DoubleArgumentType
import com.mojang.brigadier.arguments.FloatArgumentType
import com.mojang.brigadier.arguments.IntegerArgumentType
import com.mojang.brigadier.arguments.LongArgumentType
import com.mojang.brigadier.arguments.StringArgumentType

inline fun <S, reified T : Any> DslCommandTree<S, *>.argument(
    name: String,
    type: ArgumentType<T>,
    noinline block: ArgumentBlock<S, T> = {},
) = argument(name, type, T::class, block)

fun <S> DslCommandTree<S, *>.boolean(
    name: String,
    block: ArgumentBlock<S, Boolean> = {},
) = argument(name, BoolArgumentType.bool(), block)

fun <S> DslCommandTree<S, *>.int(
    name: String,
    min: Int = Integer.MIN_VALUE,
    max: Int = Integer.MAX_VALUE,
    block: ArgumentBlock<S, Int> = {},
) = argument(name, IntegerArgumentType.integer(min, max), block)

fun <S> DslCommandTree<S, *>.long(
    name: String,
    min: Long = Long.MIN_VALUE,
    max: Long = Long.MAX_VALUE,
    block: ArgumentBlock<S, Long> = {},
) = argument(name, LongArgumentType.longArg(min, max), block)

fun <S> DslCommandTree<S, *>.float(
    name: String,
    min: Float = Float.MIN_VALUE,
    max: Float = Float.MAX_VALUE,
    block: ArgumentBlock<S, Float> = {},
) = argument(name, FloatArgumentType.floatArg(min, max), block)

fun <S> DslCommandTree<S, *>.double(
    name: String,
    min: Double = Double.MIN_VALUE,
    max: Double = Double.MAX_VALUE,
    block: ArgumentBlock<S, Double> = {},
) = argument(name, DoubleArgumentType.doubleArg(min, max), block)

fun <S> DslCommandTree<S, *>.word(
    name: String,
    block: ArgumentBlock<S, String> = {},
) = argument(name, StringArgumentType.word(), block)

fun <S> DslCommandTree<S, *>.string(
    name: String,
    block: ArgumentBlock<S, String> = {},
) = argument(name, StringArgumentType.string(), block)

fun <S> DslCommandTree<S, *>.greedyString(
    name: String,
    block: ArgumentBlock<S, String> = {},
) = argument(name, StringArgumentType.greedyString(), block)