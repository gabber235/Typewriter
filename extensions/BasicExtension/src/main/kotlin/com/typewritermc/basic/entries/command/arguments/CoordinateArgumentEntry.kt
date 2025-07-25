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
import com.typewritermc.core.utils.point.*
import com.typewritermc.engine.paper.command.dsl.ExecutionContext
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.utils.toWorld
import io.papermc.paper.command.brigadier.CommandSourceStack
import io.papermc.paper.command.brigadier.argument.ArgumentTypes
import io.papermc.paper.command.brigadier.argument.resolvers.FinePositionResolver
import io.papermc.paper.command.brigadier.argument.resolvers.RotationResolver
import kotlin.reflect.KClass

@Entry("coordinate_argument", "A coordinate argument", Colors.BLUE, "majesticons:map-pin")
@ContextKeys(CoordinateArgumentContextKeys::class)
/**
 * The `Coordinate Argument` entry is an argument that takes a coordinate.
 *
 * It can be used to specify a coordinate in 3D space.
 *
 * ## How could this be used?
 * This could be used to create commands that require a coordinate, such as setting a specific location.
 */
class CoordinateArgumentEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<CommandArgumentEntry>> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ArgumentCommandArgument<Coordinate> {
    override val type: ArgumentType<Coordinate> get() = CoordinateArgument()
    override val klass: KClass<Coordinate> get() = Coordinate::class

    override fun InteractionContextBuilder.apply(context: ExecutionContext<CommandSourceStack>, value: Coordinate) {
        val world = context.source.location.world.toWorld()
        set(CoordinateArgumentContextKeys.POSITION, value.toPosition(world))
        set(CoordinateArgumentContextKeys.COORDINATE, value)
        set(CoordinateArgumentContextKeys.VECTOR, value.toVector())
    }
}

enum class CoordinateArgumentContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Position::class)
    POSITION(Position::class),

    @KeyType(Coordinate::class)
    COORDINATE(Coordinate::class),

    @KeyType(Vector::class)
    VECTOR(Vector::class),
}

class CoordinateArgument : ChainArgumentType<Coordinate>() {
    override val argumentTypes = listOf(
        ArgumentTypes.finePosition(true),
        ArgumentTypes.rotation()
    )

    override fun <S : Any> parseChain(reader: StringReader, source: S, parsedValues: List<Any>): Coordinate {
        if (source !is CommandSourceStack) {
            throw IllegalArgumentException("Source must be a CommandSourceStack")
        }
        val posResolver = parsedValues[0] as FinePositionResolver
        val rotationResolver = parsedValues[1] as RotationResolver

        val pos = posResolver.resolve(source)
        val rotation = rotationResolver.resolve(source)

        return Coordinate(pos.x(), pos.y(), pos.z(), rotation.yaw(), rotation.pitch())
    }
}
