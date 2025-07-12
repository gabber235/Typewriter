package com.typewritermc.engine.paper.serialization

import com.typewritermc.core.serialization.createCoreSerializersModule
import com.typewritermc.engine.paper.serialization.format.createJsonFormat
import kotlinx.serialization.json.Json
import kotlinx.serialization.modules.SerializersModule
import org.koin.core.qualifier.named
import org.koin.dsl.module

val koinSerializationModule = module {
    factory<SerializersModule>(named("paperSerializersModule")) { createPaperSerializersModule() }
    factory<SerializersModule>(named("coreSerializersModule")) { createCoreSerializersModule() }
    single<Json> { createJsonFormat(getAll()) }
}