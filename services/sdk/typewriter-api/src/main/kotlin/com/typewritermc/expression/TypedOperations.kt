package com.typewritermc.expression

import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigDecimal

/*
 * The DSL of the operations whose types the arguments cannot state: the catalog type they work with is a type
 * argument of the call. Callers name it with the type use of a generated declaration (`XDefinition.use`, or the
 * `...Type` constants of the core library); numeric conversions name it with the Kotlin target type.
 */

/** Parses canonical value JSON as a value of [type]; fails when the text is not value JSON of that type. */
fun <X, M : MissingPolicy> Expr<String, M>.fromJson(type: TypeUse): Expr<X, M> =
    call(PortableOperationCatalog.VALUE_FROM_JSON, this, typeArguments = listOf(type.toTemplate()))

/** Whether this value's actual type is [type] or one of its descendants. */
fun <M : MissingPolicy> Expr<*, M>.isInstance(type: TypeUse): Expr<Boolean, M> =
    call(PortableOperationCatalog.VALUE_INSTANCE_OF, this, typeArguments = listOf(type.toTemplate()))

/** This value as [type] when its actual type is [type] or a descendant, otherwise null. */
fun <X, M : MissingPolicy> Expr<*, M>.castTo(type: TypeUse): Expr<X?, M> =
    call(PortableOperationCatalog.VALUE_CAST, this, typeArguments = listOf(type.toTemplate()))

/** A value of the named [type] over this representation. */
fun <X, M : MissingPolicy> Expr<*, M>.wrapAs(type: TypeUse): Expr<X, M> =
    call(PortableOperationCatalog.VALUE_WRAP, this, typeArguments = listOf(type.toTemplate()))

/** The representation of this value of a named type, such as the text of a text backed type. */
fun <R, M : MissingPolicy> Expr<*, M>.unwrap(): Expr<R, M> = call(PortableOperationCatalog.VALUE_UNWRAP, this)

/** This record with the field [name] replaced by [value]. */
fun <X, M : MissingPolicy> Expr<X, M>.withField(
    name: String,
    value: Expr<*, M>,
): Expr<X, M> = call(PortableOperationCatalog.RECORD_WITH_FIELD, this, literal(name), value)

/** The case of the enumeration [type] with this name, or null when it has no such case. */
fun <E, M : MissingPolicy> Expr<String, M>.enumValueOrNull(type: TypeUse): Expr<E?, M> =
    call(PortableOperationCatalog.ENUM_FROM_NAME, this, typeArguments = listOf(type.toTemplate()))

/** Every case of the enumeration [type], in declaration order. */
fun <E> enumEntries(type: TypeUse): Expr<List<E>, Handled> =
    call(PortableOperationCatalog.ENUM_CASES, typeArguments = listOf(type.toTemplate()))

/** The configured value of the resource of [type] with this identity; missing when there is none of that type. */
fun <T : Resource, M : MissingPolicy> Expr<ResourceId, M>.resourceValue(type: TypeUse): Expr<T, MayBeMissing> =
    call(PortableOperationCatalog.RESOURCE_VALUE_OF, this, typeArguments = listOf(type.toTemplate()))

/** This number as a [Byte]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toByte(): Expr<Byte, M> = convert(integerScalar(IntegerWidth.SIGNED_EIGHT))

/** This number as a [Short]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toShort(): Expr<Short, M> = convert(integerScalar(IntegerWidth.SIGNED_SIXTEEN))

/** This number as an [Int]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toInt(): Expr<Int, M> = convert(integerScalar(IntegerWidth.SIGNED_THIRTY_TWO))

/** This number as a [Long]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toLong(): Expr<Long, M> = convert(integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR))

/** This number as a [UByte]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toUByte(): Expr<UByte, M> = convert(integerScalar(IntegerWidth.UNSIGNED_EIGHT))

/** This number as a [UShort]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toUShort(): Expr<UShort, M> = convert(integerScalar(IntegerWidth.UNSIGNED_SIXTEEN))

/** This number as a [UInt]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toUInt(): Expr<UInt, M> = convert(integerScalar(IntegerWidth.UNSIGNED_THIRTY_TWO))

/** This number as a [ULong]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toULong(): Expr<ULong, M> = convert(integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR))

/** This number as a [Float]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toFloat(): Expr<Float, M> = convert(floatScalar(FloatWidth.THIRTY_TWO))

/** This number as a [Double]; fails unless it is exactly representable. */
fun <M : MissingPolicy> Expr<out Number, M>.toDouble(): Expr<Double, M> = convert(floatScalar(FloatWidth.SIXTY_FOUR))

/** This number as a [BigDecimal]; integers and floats convert exactly. */
fun <M : MissingPolicy> Expr<out Number, M>.toBigDecimal(): Expr<BigDecimal, M> = convert(ScalarKind.DECIMAL)

private fun <N, M : MissingPolicy> Expr<out Number, M>.convert(target: ScalarKind): Expr<N, M> =
    call(PortableOperationCatalog.NUMBER_CONVERT, this, typeArguments = listOf(target.use.toTemplate()))
