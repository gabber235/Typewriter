package com.typewritermc.engine.paper.loader

import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.core.serialization.DataSerializer.Companion.toDataSerializer
import com.typewritermc.core.serialization.serializer
import com.typewritermc.core.serialization.xmap
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.SkinProperty
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.loader.serializers.*
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.CronExpression
import com.typewritermc.engine.paper.utils.SoundId
import com.typewritermc.engine.paper.utils.SoundSource
import kotlinx.serialization.builtins.nullable
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.serializer
import net.kyori.adventure.key.Key
import org.bukkit.Registry
import org.bukkit.potion.PotionEffectType
import org.bukkit.util.Vector
import org.koin.core.component.get
import org.koin.core.qualifier.named
import org.koin.dsl.module
import java.time.Duration
import kotlin.time.toJavaDuration
import kotlin.time.toKotlinDuration


// TODO better serialization module management.
val dataSerializerModule = module {
    single<DataSerializer<*>>(named("closedRange")) {
        // Contextual
        plugin.get<Json>(named("dataSerializer")).serializersModule.serializer<ClosedRange<*>>().toDataSerializer()
    }
    single<DataSerializer<*>>(named("color")) {
        Int.serializer().xmap(Color::color, ::Color).toDataSerializer()
    }
    single<DataSerializer<*>>(named("duration")) {
        kotlin.time.Duration.serializer().xmap(Duration::toKotlinDuration, kotlin.time.Duration::toJavaDuration).toDataSerializer()
    }
    single<DataSerializer<*>>(named("position")) { Position.serializer().toDataSerializer() }
    single<DataSerializer<*>>(named("potionEffectType")) {
        String.serializer().xmap<String, PotionEffectType>(
            { key.asString() },
            { Registry.EFFECT.get(Key.key(this)) ?: error("Unknown potion type '$this'") }
        ).toDataSerializer()
    }
    single<DataSerializer<*>>(named("skinProperty")) {
        SkinProperty.serializer().toDataSerializer()
    }
    single<DataSerializer<*>>(named("soundId")) {
        SoundId.serializer().toDataSerializer()
    }
    single<DataSerializer<*>>(named("soundSource")) {
        SoundSource.serializer().toDataSerializer()
    }
    single<DataSerializer<*>>(named("world")) {
        World.serializer().toDataSerializer()
    }
    single<DataSerializer<*>>(named("vector")) {
        serializer(
            "x", { x }, Double.serializer(),
            "y", { y }, Double.serializer(),
            "z", { z }, Double.serializer(),
            ::Vector
        )
    }
    single<DataSerializer<*>>(named("coordinate")) {
        serializer(
            "x", { x }, Double.serializer().nullable,
            "y", { y }, Double.serializer().nullable,
            "z", { z }, Double.serializer().nullable,
            "yaw", { yaw }, Float.serializer().nullable,
            "pitch", { pitch }, Float.serializer().nullable,
            { x, y, z, yaw, pitch -> Coordinate(x ?: 0.0, y ?: 0.0, z ?: 0.0, yaw ?: 0f, pitch ?: 0f) }
        )
    }
    single<DataSerializer<*>>(named("cronExpression")) {
        String.serializer().xmap(
            { expression },
            { CronExpression.createDynamic(this) }
        ).toDataSerializer()
    }

    // TODO
    single<DataSerializer<*>>(named("var")) { VarSerializer() }
    single<DataSerializer<*>>(named("entryReference")) { EntryReferenceSerializer() }
    single<DataSerializer<*>>(named("entryInteractionContextKey")) { EntryInteractionContextKeySerializer() }
    single<DataSerializer<*>>(named("generic")) { GenericSerializer() }
    single<DataSerializer<*>>(named("optional")) { OptionalSerializer() }
}