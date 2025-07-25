package com.typewritermc.basic.entries.command.arguments

import com.mojang.brigadier.StringReader
import com.mojang.brigadier.arguments.ArgumentType
import com.typewritermc.basic.entries.command.ArgumentCommandArgument
import com.typewritermc.basic.entries.command.CommandArgumentEntry
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContextBuilder
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.command.dsl.ExecutionContext
import com.typewritermc.engine.paper.entry.TriggerableEntry
import io.papermc.paper.command.brigadier.CommandSourceStack
import io.papermc.paper.command.brigadier.argument.ArgumentTypes
import io.papermc.paper.command.brigadier.argument.resolvers.FinePositionResolver
import kotlin.reflect.KClass

@Entry("vector_argument", "A vector argument", Colors.GREEN, "ph:vector-three-bold")
@ContextKeys(VectorArgumentContextKeys::class)
/**
 * The `Vector Argument` entry is an argument that takes a vector.
 *
 * It can be used to specify a direction or offset in 3D space.
 *
 * ## How could this be used?
 * This could be used to create commands that require a direction, such as setting a velocity or offset.
 */
class VectorArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ArgumentCommandArgument<Vector> {
    override val type: ArgumentType<Vector> get() = VectorArgument()
    override val klass: KClass<Vector> get() = Vector::class

    override fun InteractionContextBuilder.apply(context: ExecutionContext<CommandSourceStack>, value: Vector) {
        set(VectorArgumentContextKeys.VECTOR, value)
    }
}

enum class VectorArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Vector::class)
    VECTOR(Vector::class),
}

class VectorArgument : ChainArgumentType<Vector>() {
    override val argumentTypes = listOf(
        ArgumentTypes.finePosition(true)
    )

    override fun <S : Any> parseChain(reader: StringReader, source: S, parsedValues: List<Any>): Vector {
        if (source !is CommandSourceStack) {
            throw IllegalArgumentException("Source must be a CommandSourceStack")
        }
        val posResolver = parsedValues[0] as FinePositionResolver
        val pos = posResolver.resolve(source)

        return Vector(pos.x(), pos.y(), pos.z())
    }
}
