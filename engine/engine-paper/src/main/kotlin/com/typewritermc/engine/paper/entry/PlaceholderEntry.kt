package com.typewritermc.engine.paper.entry

import com.typewritermc.core.entries.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass
import kotlin.reflect.cast

@Tags("placeholder")
interface PlaceholderEntry : Entry {
    fun parser(): PlaceholderParser
}

interface PlaceholderSupplier {
    fun supply(context: ParsingContext): String?
}

class ParsingContext(
    val player: Player?,
    private val arguments: Map<ArgumentReference<out Any>, Any>
) {
    fun <T : Any> getArgument(reference: ArgumentReference<T>): T {
        val value = arguments[reference]
        return reference.type.cast(value)
    }

    fun hasArgument(reference: ArgumentReference<out Any>): Boolean {
        return arguments.containsKey(reference)
    }

    operator fun <T : Any> ArgumentReference<T>.invoke(): T {
        return getArgument(this)
    }
}

interface PlaceholderArgument<T : Any> {
    fun parse(player: Player?, argument: String): Result<T>
}

class ArgumentReference<T : Any>(
    val id: String = UUID.randomUUID().toString(),
    val type: KClass<T>,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ArgumentReference<*>) return false

        if (id != other.id) return false

        return true
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }

    override fun toString(): String {
        return "ArgumentReference(id='$id', type=$type)"
    }
}

sealed interface PlaceholderNode

class SupplierNode(val supplier: PlaceholderSupplier) : PlaceholderNode

class ArgumentNode<T : Any>(
    val name: String,
    val reference: ArgumentReference<T>,
    val argument: PlaceholderArgument<T>,
    val children: List<PlaceholderNode>
) : PlaceholderNode

class PlaceholderParser(
    val nodes: List<PlaceholderNode>,
) {
    fun parse(player: Player?, arguments: List<String>): String? {
        val parsedArguments = mutableMapOf<ArgumentReference<out Any>, Any>()
        var currentNodes = nodes
        for (argument in arguments) {
            val nextNodes = mutableListOf<PlaceholderNode>()
            for (node in currentNodes) {
                when (node) {
                    is SupplierNode -> {}
                    is ArgumentNode<*> -> {
                        val result = node.argument.parse(player, argument)
                        if (result.isSuccess) {
                            parsedArguments[node.reference] = result.getOrThrow()
                            nextNodes.addAll(node.children)
                        }
                    }
                }
            }
            if (nextNodes.isEmpty()) {
                return null
            }
            currentNodes = nextNodes
        }

        val context = ParsingContext(player, parsedArguments)
        val suppliers = currentNodes.filterIsInstance<SupplierNode>()
        if (suppliers.isEmpty()) {
            return null
        }

        return suppliers.first().supplier.supply(context)
    }
}

class PlaceholderNodeBuilder {
    internal val nodes = mutableListOf<PlaceholderNode>()
    operator fun plusAssign(node: PlaceholderNode) {
        nodes += node
    }
}

fun placeholderParser(builder: PlaceholderNodeBuilder.() -> Unit): PlaceholderParser {
    val nodes = PlaceholderNodeBuilder().apply(builder).nodes
    return PlaceholderParser(nodes)
}

fun PlaceholderNodeBuilder.include(parser: PlaceholderParser) {
    nodes.addAll(parser.nodes)
}

fun PlaceholderNodeBuilder.supply(supplier: ParsingContext.(Player?) -> String?) {
    this += SupplierNode(object : PlaceholderSupplier {
        override fun supply(context: ParsingContext): String? {
            return supplier(context, context.player)
        }
    })
}

fun PlaceholderNodeBuilder.supplyPlayer(supplier: ParsingContext.(Player) -> String?) {
    this += SupplierNode(object : PlaceholderSupplier {
        override fun supply(context: ParsingContext): String? {
            return supplier(context, context.player ?: return null)
        }
    })
}

typealias ArgumentBuilder<T> = PlaceholderNodeBuilder.(ArgumentReference<T>) -> Unit

fun <T : Any> PlaceholderNodeBuilder.argument(
    name: String,
    type: KClass<T>,
    argument: PlaceholderArgument<T>,
    builder: ArgumentBuilder<T>,
) {
    val reference = ArgumentReference(type = type)
    val children = PlaceholderNodeBuilder().apply { builder(reference) }.nodes
    this += ArgumentNode(name, reference, argument, children)
}

fun PlaceholderNodeBuilder.literal(name: String, builder: PlaceholderNodeBuilder.() -> Unit) =
    argument(name, String::class, LiteralArgument(name)) { builder() }

class LiteralArgument(val name: String) : PlaceholderArgument<String> {
    override fun parse(player: Player?, argument: String): Result<String> {
        if (argument != name) return failure("Literal '$name' didn't match argument '$argument'")
        return ok(argument)
    }
}

fun PlaceholderNodeBuilder.string(name: String, builder: ArgumentBuilder<String>) =
    argument(name, String::class, StringArgument, builder)

object StringArgument : PlaceholderArgument<String> {
    override fun parse(player: Player?, argument: String): Result<String> {
        return ok(argument)
    }
}

fun PlaceholderNodeBuilder.int(name: String, builder: ArgumentBuilder<Int>) =
    argument(name, Int::class, IntArgument, builder)

object IntArgument : PlaceholderArgument<Int> {
    override fun parse(player: Player?, argument: String): Result<Int> {
        return try {
            ok(argument.toInt())
        } catch (e: NumberFormatException) {
            failure("Could not parse '$argument' as an integer")
        }
    }
}

fun <E : Enum<E>> PlaceholderNodeBuilder.enum(name: String, enumKClass: KClass<E>, builder: ArgumentBuilder<E>) =
    argument(name, enumKClass, EnumArgument(enumKClass), builder)

class EnumArgument<E : Enum<E>>(private val enumKClass: KClass<E>) : PlaceholderArgument<E> {
    override fun parse(player: Player?, argument: String): Result<E> {
        return try {
            ok(enumKClass.java.enumConstants.first { it.name.equals(argument, ignoreCase = true) })
        } catch (e: NoSuchElementException) {
            failure("Could not parse '$argument' as a valid value, possible values are ${enumKClass.java.enumConstants.joinToString { it.name.lowercase() }}")
        }
    }
}