package com.typewritermc.presentation

import kotlin.reflect.KClass
import kotlin.reflect.KProperty1

/**
 * Identifies a value supplied to one presentation declaration.
 *
 * Inputs are local to their declaration. The panel binds and edits them, while the caller owns persistence and
 * decides whether an editable value is eventually committed.
 */
class PresentationInputRef<T : Any> internal constructor(
    val name: String,
    val type: KClass<T>,
    val editable: Boolean,
    internal val index: Long,
    @PublishedApi internal val context: PresentationBuildContext,
) {
    /** Returns a binding to the complete input value. */
    fun value(): PresentationValue<T> = PresentationValue(this, emptyList(), type, context)

    /** Returns a binding to a serialized property nested within this input. */
    inline fun <reified V : Any> field(property: KProperty1<T, V>): PresentationValue<V> = value().field(property)

    /** Selects a nullable field whose absence may be recovered with [OptionalPresentationValue.orElse]. */
    inline fun <reified V : Any> optionalField(property: KProperty1<T, V?>): OptionalPresentationValue<V> {
        val field = context.field(type, property.name)
        return OptionalPresentationValue(this, listOf(field.serializedName), V::class, context)
    }

    /** Maps [value] into this input when a presentation is included by another presentation. */
    infix fun <V : T> receives(value: PresentationValue<V>): PresentationArgumentRef = PresentationArgumentRef(this, value)
}

/**
 * A typed binding into a declaration input.
 *
 * Property selection retains the originating input identity and records serialized field names for protocol
 * compilation. It describes data flow only, not storage or mutation.
 */
class PresentationValue<T : Any>
    @PublishedApi
    internal constructor(
        @PublishedApi internal val input: PresentationInputRef<*>,
        @PublishedApi internal val fields: List<String>,
        val type: KClass<T>,
        @PublishedApi internal val context: PresentationBuildContext,
    ) {
        /** Selects a serialized property while preserving this binding's input identity. */
        inline fun <reified V : Any> field(property: KProperty1<T, V>): PresentationValue<V> {
            val field = context.field(type, property.name)
            return PresentationValue(input, fields + field.serializedName, V::class, context)
        }

        internal fun reference(): FieldReference = FieldReference(fields.lastOrNull().orEmpty(), input, fields.dropLast(1))

        /** Uses this bound value as a typed display expression. */
        fun expression(): PresentationExpression<T> = PresentationExpression(type, AuthoredExpression.Binding(this))
    }

/** A nullable binding projection that must be recovered before use by a content primitive. */
class OptionalPresentationValue<T : Any>
    @PublishedApi
    internal constructor(
        @PublishedApi internal val input: PresentationInputRef<*>,
        @PublishedApi internal val fields: List<String>,
        val type: KClass<T>,
        @PublishedApi internal val context: PresentationBuildContext,
    ) {
        /** Projects a field through the optional value. Missing values remain recoverable failures. */
        inline fun <reified V : Any> field(property: KProperty1<T, V>): OptionalPresentationValue<V> {
            val field = context.field(type, property.name)
            return OptionalPresentationValue(input, fields + field.serializedName, V::class, context)
        }

        /** Uses [fallback] when the optional projection is absent. */
        fun orElse(fallback: T): PresentationExpression<T> =
            PresentationExpression(
                type,
                AuthoredExpression.Coalesce(
                    AuthoredExpression.BindingPath(input, fields, type),
                    AuthoredExpression.Literal(fallback),
                ),
            )
    }

/** A typed, immutable expression accepted by presentation content primitives. */
class PresentationExpression<T : Any> internal constructor(
    val type: KClass<T>,
    internal val authored: AuthoredExpression,
)

/** Slices this text with UTF16 code unit offsets supplied by typed expressions. */
fun PresentationExpression<String>.substring(
    start: PresentationExpression<Int>,
    end: PresentationExpression<Int>? = null,
): PresentationExpression<String> =
    PresentationExpression(
        String::class,
        AuthoredExpression.Substring(authored, start.authored, end?.authored),
    )

/** Creates a typed integer expression for authored text bounds. */
fun Int.presentationExpression(): PresentationExpression<Int> = PresentationExpression(Int::class, AuthoredExpression.Literal(this))

/** Projects a named value whose catalog representation is a string into text content. */
fun <T : Any> PresentationValue<T>.asStringExpression(): PresentationExpression<String> =
    PresentationExpression(String::class, AuthoredExpression.StringProjection(this))

internal sealed interface AuthoredExpression {
    data class Binding(
        val value: PresentationValue<*>,
    ) : AuthoredExpression

    data class StringProjection(
        val value: PresentationValue<*>,
    ) : AuthoredExpression

    data class BindingPath(
        val input: PresentationInputRef<*>,
        val fields: List<String>,
        val type: KClass<*>,
    ) : AuthoredExpression

    data class Literal(
        val value: Any,
    ) : AuthoredExpression

    data class Coalesce(
        val value: AuthoredExpression,
        val fallback: AuthoredExpression,
    ) : AuthoredExpression

    data class Substring(
        val value: AuthoredExpression,
        val start: AuthoredExpression,
        val end: AuthoredExpression?,
    ) : AuthoredExpression
}

/** Connects an including presentation's input to an included presentation's input. */
class PresentationArgumentRef internal constructor(
    internal val input: PresentationInputRef<*>,
    internal val value: PresentationValue<*>,
)

/** Builds a composed presentation with no implicit primary input. */
@JvmName("composedPresentation")
context(context: PresentationBuildContext)
fun presentation(
    name: String,
    block: PresentationBuilder<Unit>.() -> Unit,
): PresentationSpec<Unit> = PresentationBuilder(Unit::class, context).apply(block).build(name)
