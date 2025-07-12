package com.typewritermc.engine.paper.serialization

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.interaction.EntryInteractionContextKey
import com.typewritermc.core.serialization.serializer
import com.typewritermc.core.serialization.xmap
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.serialization.serializer.*
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.CronExpression
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import net.kyori.adventure.key.Key
import org.bukkit.Registry
import org.bukkit.potion.PotionEffectType
import org.bukkit.util.Vector
import java.lang.Class.forName
import java.util.*
import kotlin.reflect.KClass
import kotlin.time.Duration
import kotlin.time.toJavaDuration
import kotlin.time.toKotlinDuration

fun createPaperSerializersModule() = SerializersModule {
    polymorphic(ClosedRange::class) {
        subclass(IntRangeSerializer)
        subclass(LongRangeSerializer)
        subclass(FloatRangeSerializer)
        subclass(DoubleRangeSerializer)
    }
    contextual(Color::class, Int.serializer().xmap(
        Color::color,
        ::Color
    ))
    contextual(java.time.Duration::class, Duration.serializer().xmap(
        java.time.Duration::toKotlinDuration,
        Duration::toJavaDuration
    ))
    contextual(PotionEffectType::class, String.serializer().xmap(
        { key.asString() },
        { Registry.EFFECT.get(Key.key(this)) ?: error("Unknown potion type '$this'") }
    ))
    contextual(Vector::class, serializer(
        "x", { x }, Double.serializer(),
        "y", { y }, Double.serializer(),
        "z", { z }, Double.serializer(),
        ::Vector
    ))
    contextual(CronExpression::class, String.serializer().xmap(
        { expression },
        { CronExpression.createDynamic(this) }
    ))
    contextual(KClass::class, String.serializer().xmap(
        { qualifiedName ?: error("No qualified name for $this") },
        { forName(this).kotlin }
    ))

    // TODO
    contextual(Var::class) { Var.serializer(it[0]) }
    contextual(Ref::class) { Ref.serializer(it[0]) }
    contextual(EntryInteractionContextKey::class) { EntryInteractionContextKey.serializer(it[0]) }
    contextual(Optional::class) {
        @Suppress("UNCHECKED_CAST") // Untrue
        OptionalSerializer(it[0] as KSerializer<Any>)
    }
}