@file:JvmName("SkirEnums")

package com.typewritermc.playtest.wire

import build.skir.reflection.EnumConstantVariant
import build.skir.reflection.EnumDescriptor
import skirout.harness.v1.wire.StateKind

/**
 * Every constant of the Skir enum [descriptor] describes, in the order the wire declares them, as
 * `entries` lists a Kotlin enum's. A generated Skir enum is a sealed class and has no such list.
 */
fun <E> constantsOf(descriptor: EnumDescriptor.Reflective<E>): List<E> =
    descriptor.variants.filterIsInstance<EnumConstantVariant.Reflective<E>>().map { it.constant }

/** The name the wire declares [value]'s variant under, such as `ender_chest`. */
fun <E> variantName(
    descriptor: EnumDescriptor.Reflective<E>,
    value: E,
): String = descriptor.getVariant(value).name

/** Every kind of state an attempt can leave behind, in the order the wire declares them. */
val StateKind.Companion.entries: List<StateKind> get() = constantsOf(typeDescriptor)
