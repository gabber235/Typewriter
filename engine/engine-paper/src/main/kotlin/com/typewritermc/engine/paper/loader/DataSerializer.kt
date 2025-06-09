package com.typewritermc.engine.paper.loader

import com.typewritermc.core.serialization.DataSerializer
import com.typewritermc.engine.paper.loader.serializers.*
import org.koin.core.qualifier.named
import org.koin.dsl.module

val dataSerializerModule = module {
    single<DataSerializer<*>>(named("closedRange")) { ClosedRangeSerializer() }
    single<DataSerializer<*>>(named("color")) { ColorSerializer() }
    single<DataSerializer<*>>(named("coordinate")) { CoordinateSerializer() }
    single<DataSerializer<*>>(named("cronExpression")) { CronExpressionSerializer() }
    single<DataSerializer<*>>(named("duration")) { DurationSerializer() }
    single<DataSerializer<*>>(named("entryInteractionContextKey")) { EntryInteractionContextKeySerializer() }
    single<DataSerializer<*>>(named("entryReference")) { EntryReferenceSerializer() }
    single<DataSerializer<*>>(named("generic")) { GenericSerializer() }
    single<DataSerializer<*>>(named("optional")) { OptionalSerializer() }
    single<DataSerializer<*>>(named("position")) { PositionSerializer() }
    single<DataSerializer<*>>(named("potionEffectType")) { PotionEffectTypeSerializer() }
    single<DataSerializer<*>>(named("skinProperty")) { SkinPropertySerializer() }
    single<DataSerializer<*>>(named("soundId")) { SoundIdSerializer() }
    single<DataSerializer<*>>(named("soundSource")) { SoundSourceSerializer() }
    single<DataSerializer<*>>(named("var")) { VarSerializer() }
    single<DataSerializer<*>>(named("vector")) { VectorSerializer() }
    single<DataSerializer<*>>(named("world")) { WorldSerializer() }
}