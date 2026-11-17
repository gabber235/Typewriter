package com.typewritermc.playtest.wire

import build.skir.reflection.ArrayDescriptor
import build.skir.reflection.EnumConstantVariant
import build.skir.reflection.EnumDescriptor
import build.skir.reflection.EnumWrapperVariant
import build.skir.reflection.OptionalDescriptor
import build.skir.reflection.PrimitiveDescriptor
import build.skir.reflection.StructDescriptor
import build.skir.reflection.StructField
import build.skir.reflection.TypeDescriptor
import okio.ByteString.Companion.toByteString

/**
 * Values of the type [descriptor] describes that together hold every variant of every enum within it,
 * with no field at its default, so a variant added to the wire is covered without a new case here. An
 * enum gives one value per variant and its values' own samples; a struct as many values as its field
 * with the most samples, each field cycling through its own.
 */
@Suppress("UNCHECKED_CAST")
fun <T> samples(descriptor: TypeDescriptor.Reflective<T>): List<T> =
    when (descriptor) {
        is PrimitiveDescriptor.Reflective<*> -> {
            listOf(primitive(descriptor) as T)
        }

        is OptionalDescriptor.Reflective<*> -> {
            samples(descriptor.otherType) as List<T>
        }

        is ArrayDescriptor.Reflective<*, *> -> {
            val array = descriptor as ArrayDescriptor.Reflective<Any?, List<Any?>>
            listOf(array.toList(samples(array.itemType)) as T)
        }

        is EnumDescriptor.Reflective<*> -> {
            (descriptor as EnumDescriptor.Reflective<T>).variants.flatMap { variant ->
                when (variant) {
                    is EnumConstantVariant.Reflective<T> -> listOf(variant.constant)
                    is EnumWrapperVariant.Reflective<T, *> -> wrapped(variant)
                }
            }
        }

        is StructDescriptor.Reflective<*, *> -> {
            structs(descriptor as StructDescriptor.Reflective<T, Any?>)
        }

        // Kotlin's generated types describe optionals as nullable values, never as Java's Optional.
        is OptionalDescriptor.JavaReflective<*> -> {
            error("the wire's types describe no Java optional")
        }
    }

private fun <T, V> wrapped(variant: EnumWrapperVariant.Reflective<T, V>): List<T> = samples(variant.type).map(variant::wrap)

private fun <T, M> structs(struct: StructDescriptor.Reflective<T, M>): List<T> {
    val fields = struct.fields.map { field -> field to samples(field.type) }
    val count = fields.maxOfOrNull { (_, samples) -> samples.size } ?: 1
    return List(count) { index ->
        val mutable = struct.newMutable()
        fields.forEach { (field, samples) -> set(field, mutable, samples[index % samples.size]) }
        struct.toFrozen(mutable)
    }
}

@Suppress("UNCHECKED_CAST")
private fun <T, M, V> set(
    field: StructField.Reflective<T, M, V>,
    mutable: M,
    value: Any?,
) = field.set(mutable, value as V)

private fun primitive(descriptor: PrimitiveDescriptor.Reflective<*>): Any =
    when (descriptor) {
        PrimitiveDescriptor.Reflective.Bool -> true
        PrimitiveDescriptor.Reflective.Int32 -> -70_000
        PrimitiveDescriptor.Reflective.Int64 -> 1_700_000_000_000L
        PrimitiveDescriptor.Reflective.Float32 -> 0.25f
        PrimitiveDescriptor.Reflective.Float64 -> 101.62
        PrimitiveDescriptor.Reflective.String -> "é ".repeat(40_000)
        PrimitiveDescriptor.Reflective.Bytes -> byteArrayOf(1, -2, 3).toByteString()
        else -> error("the wire declares no field of type ${descriptor.primitiveType}; add a sample for it")
    }
