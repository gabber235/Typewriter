@file:Suppress("DuplicatedCode", "UNCHECKED_CAST")
package com.typewritermc.core.serialization

import com.typewritermc.core.utils.toSnakeCase
import kotlinx.serialization.*
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.*
import org.jetbrains.annotations.ApiStatus
import kotlin.reflect.KClass

@OptIn(ExperimentalSerializationApi::class)
@ApiStatus.Internal
@PublishedApi
internal inline fun <R> internalSerializer(
    desc: SerialDescriptor,
    crossinline fields: R.() -> Array<Any?>,
    crossinline constructor: (Array<Any?>)-> R,
    vararg serializers: KSerializer<*>
): KSerializer<R> = object: KSerializer<R> {
    override val descriptor: SerialDescriptor = desc

    override fun serialize(encoder: Encoder, value: R) = encoder.encodeStructure(descriptor) {
        val f = value.fields()
        for ((i, s) in serializers.withIndex()) {
            untypedSerialize(descriptor, i, s as KSerializer<Any?>, f[i])
        }
    }

    override fun deserialize(decoder: Decoder): R = decoder.decodeStructure(descriptor) {
        val fields = Array<Any?>(descriptor.elementsCount) { null }
        while (true) {
            val index = decodeElementIndex(descriptor)
            if (index == CompositeDecoder.DECODE_DONE) break
            val ser = serializers[index]
            fields[index] = decodeSerializableElement(descriptor, index, ser)
        }

        val missing = mutableListOf<String>()
        for ((i, field )in fields.withIndex()) {
            val d = descriptor.getElementDescriptor(i)
            if (field == null && !d.isNullable) missing += descriptor.getElementName(i)
        }
        if (missing.isNotEmpty()) throw MissingFieldException(missing, descriptor.serialName)

        constructor(fields)
    }

    // Will still work thanks to the underlying type still existing. It's just cast to Any above.
    private fun <T> CompositeEncoder.untypedSerialize(descriptor: SerialDescriptor, index: Int, serializer: KSerializer<T>, value: T) {
        encodeSerializableElement(descriptor, index, serializer, value)
    }
}

inline fun <T1, reified R : Any> serializer(
    nt1: String, crossinline gt1: R.() -> T1, st1: KSerializer<T1>,
    crossinline ctor: (T1) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(nt1.toSnakeCase(), st1.descriptor)
        },
        { arrayOf(gt1()) },
        { ctor(it[0] as T1) },
        st1
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}


inline fun <T1, T2, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    crossinline ctor: (T1, T2) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
        },
        { arrayOf(get1(), get2()) },
        { ctor(it[0] as T1, it[1] as T2) },
        serial1, serial2
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    crossinline ctor: (T1, T2, T3) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
        },
        { arrayOf(get1(), get2(), get3()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3) },
        serial1, serial2, serial3
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    crossinline ctor: (T1, T2, T3, T4) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4) },
        serial1, serial2, serial3, serial4
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, T5, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    name5: String, crossinline get5: R.() -> T5, serial5: KSerializer<T5>,
    crossinline ctor: (T1, T2, T3, T4, T5) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
            element(name5.toSnakeCase(), serial5.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4(), get5()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4, it[4] as T5) },
        serial1, serial2, serial3, serial4, serial5
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, T5, T6, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    name5: String, crossinline get5: R.() -> T5, serial5: KSerializer<T5>,
    name6: String, crossinline get6: R.() -> T6, serial6: KSerializer<T6>,
    crossinline ctor: (T1, T2, T3, T4, T5, T6) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
            element(name5.toSnakeCase(), serial5.descriptor)
            element(name6.toSnakeCase(), serial6.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4(), get5(), get6()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4, it[4] as T5, it[5] as T6) },
        serial1, serial2, serial3, serial4, serial5, serial6
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, T5, T6, T7, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    name5: String, crossinline get5: R.() -> T5, serial5: KSerializer<T5>,
    name6: String, crossinline get6: R.() -> T6, serial6: KSerializer<T6>,
    name7: String, crossinline get7: R.() -> T7, serial7: KSerializer<T7>,
    crossinline ctor: (T1, T2, T3, T4, T5, T6, T7) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
            element(name5.toSnakeCase(), serial5.descriptor)
            element(name6.toSnakeCase(), serial6.descriptor)
            element(name7.toSnakeCase(), serial7.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4(), get5(), get6(), get7()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4, it[4] as T5, it[5] as T6, it[6] as T7) },
        serial1, serial2, serial3, serial4, serial5, serial6, serial7
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, T5, T6, T7, T8, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    name5: String, crossinline get5: R.() -> T5, serial5: KSerializer<T5>,
    name6: String, crossinline get6: R.() -> T6, serial6: KSerializer<T6>,
    name7: String, crossinline get7: R.() -> T7, serial7: KSerializer<T7>,
    name8: String, crossinline get8: R.() -> T8, serial8: KSerializer<T8>,
    crossinline ctor: (T1, T2, T3, T4, T5, T6, T7, T8) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
            element(name5.toSnakeCase(), serial5.descriptor)
            element(name6.toSnakeCase(), serial6.descriptor)
            element(name7.toSnakeCase(), serial7.descriptor)
            element(name8.toSnakeCase(), serial8.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4(), get5(), get6(), get7(), get8()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4, it[4] as T5, it[5] as T6, it[6] as T7, it[7] as T8) },
        serial1, serial2, serial3, serial4, serial5, serial6, serial7, serial8
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, T5, T6, T7, T8, T9, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    name5: String, crossinline get5: R.() -> T5, serial5: KSerializer<T5>,
    name6: String, crossinline get6: R.() -> T6, serial6: KSerializer<T6>,
    name7: String, crossinline get7: R.() -> T7, serial7: KSerializer<T7>,
    name8: String, crossinline get8: R.() -> T8, serial8: KSerializer<T8>,
    name9: String, crossinline get9: R.() -> T9, serial9: KSerializer<T9>,
    crossinline ctor: (T1, T2, T3, T4, T5, T6, T7, T8, T9) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
            element(name5.toSnakeCase(), serial5.descriptor)
            element(name6.toSnakeCase(), serial6.descriptor)
            element(name7.toSnakeCase(), serial7.descriptor)
            element(name8.toSnakeCase(), serial8.descriptor)
            element(name9.toSnakeCase(), serial9.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4(), get5(), get6(), get7(), get8(), get9()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4, it[4] as T5, it[5] as T6, it[6] as T7, it[7] as T8, it[8] as T9) },
        serial1, serial2, serial3, serial4, serial5, serial6, serial7, serial8, serial9
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}

inline fun <T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, reified R : Any> serializer(
    name1: String, crossinline get1: R.() -> T1, serial1: KSerializer<T1>,
    name2: String, crossinline get2: R.() -> T2, serial2: KSerializer<T2>,
    name3: String, crossinline get3: R.() -> T3, serial3: KSerializer<T3>,
    name4: String, crossinline get4: R.() -> T4, serial4: KSerializer<T4>,
    name5: String, crossinline get5: R.() -> T5, serial5: KSerializer<T5>,
    name6: String, crossinline get6: R.() -> T6, serial6: KSerializer<T6>,
    name7: String, crossinline get7: R.() -> T7, serial7: KSerializer<T7>,
    name8: String, crossinline get8: R.() -> T8, serial8: KSerializer<T8>,
    name9: String, crossinline get9: R.() -> T9, serial9: KSerializer<T9>,
    name10: String, crossinline get10: R.() -> T10, serial10: KSerializer<T10>,
    crossinline ctor: (T1, T2, T3, T4, T5, T6, T7, T8, T9, T10) -> R
): DataSerializer<R> = object: DataSerializer<R> {
    override val clazz: KClass<R> = R::class
    private val serial = internalSerializer(
        buildClassSerialDescriptor(R::class.simpleName!!.toSnakeCase()) {
            element(name1.toSnakeCase(), serial1.descriptor)
            element(name2.toSnakeCase(), serial2.descriptor)
            element(name3.toSnakeCase(), serial3.descriptor)
            element(name4.toSnakeCase(), serial4.descriptor)
            element(name5.toSnakeCase(), serial5.descriptor)
            element(name6.toSnakeCase(), serial6.descriptor)
            element(name7.toSnakeCase(), serial7.descriptor)
            element(name8.toSnakeCase(), serial8.descriptor)
            element(name9.toSnakeCase(), serial9.descriptor)
            element(name10.toSnakeCase(), serial10.descriptor)
        },
        { arrayOf(get1(), get2(), get3(), get4(), get5(), get6(), get7(), get8(), get9(), get10()) },
        { ctor(it[0] as T1, it[1] as T2, it[2] as T3, it[3] as T4, it[4] as T5, it[5] as T6, it[6] as T7, it[7] as T8, it[8] as T9, it[9] as T10) },
        serial1, serial2, serial3, serial4, serial5, serial6, serial7, serial8, serial9, serial10
    )

    override val descriptor: SerialDescriptor = serial.descriptor
    override fun serialize(encoder: Encoder, value: R) = serial.serialize(encoder, value)
    override fun deserialize(decoder: Decoder): R = serial.deserialize(decoder)
}