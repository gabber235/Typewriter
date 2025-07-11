package com.typewritermc.core.serialization

import com.typewritermc.core.utils.point.Coordinate
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNamingStrategy
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.SerializersModuleBuilder
import kotlin.reflect.KClass

interface DataSerializer<T : Any> : KSerializer<T> {
    val clazz: KClass<T>

    companion object {
        inline fun <reified T : Any> KSerializer<T>.toDataSerializer(): DataSerializer<T> = object: DataSerializer<T> {
            override val clazz: KClass<T> = T::class
            override val descriptor: SerialDescriptor = this@toDataSerializer.descriptor

            override fun serialize(encoder: Encoder, value: T) = this@toDataSerializer.serialize(encoder, value)
            override fun deserialize(decoder: Decoder): T = this@toDataSerializer.deserialize(decoder)
        }
    }
}

@OptIn(ExperimentalSerializationApi::class)
fun createJsonFormat(module: SerializersModule) = Json {
    prettyPrint = false
    serializersModule = module
    namingStrategy = JsonNamingStrategy.SnakeCase
}

fun createSerializationModule(serializers: List<DataSerializer<*>>): SerializersModule {
    fun <R : Any> SerializersModuleBuilder.add(serializer: DataSerializer<R>) {
        contextual(serializer.clazz, serializer)
    }

    return SerializersModule {
        for (serializer in serializers) {
            add(serializer)
        }
    }
}

// Name inspo from mojang.serialization!!!1
fun <T, R> KSerializer<T>.xmap(serial: R.() -> T, deserial: T.() -> R): KSerializer<R> = object: KSerializer<R> {
    override val descriptor: SerialDescriptor = this@xmap.descriptor
    override fun deserialize(decoder: Decoder): R = this@xmap.deserialize(decoder).deserial()
    override fun serialize(encoder: Encoder, value: R) = this@xmap.serialize(encoder, value.serial())
}