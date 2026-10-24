package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.Handled
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.conditional
import com.typewritermc.expression.field
import com.typewritermc.expression.let
import com.typewritermc.expression.portableLiteral
import skirout.editor.v1.type_catalog.DataValue

/*
 * Building blocks of the shortcuts. Every shortcut is ordinary Kotlin over the primitive DSL: it lowers to primitive
 * calls and structural forms only, so the checker, both evaluators and the shared fixture already cover it.
 */

/**
 * Binds [value] once through the value.let primitive and builds [body] over the bound local, so a composition that
 * needs a value twice evaluates it once.
 *
 * The local holds the value the call already evaluated, so value.let adds no missing data of its own: the result is
 * missing exactly when [value] or [body] is, and keeps their policy [M].
 */
@Suppress("UNCHECKED_CAST")
internal fun <T, R, M : MissingPolicy> shared(
    value: Expr<T, M>,
    body: (Expr<T, M>) -> Expr<R, M>,
): Expr<R, M> = let(value) { local -> body(local as Expr<T, M>) } as Expr<R, M>

/** [then] when [test] holds, otherwise [otherwise]; only the chosen branch evaluates, so the policy is theirs. */
@Suppress("UNCHECKED_CAST")
internal fun <T, M : MissingPolicy> choose(
    test: Expr<Boolean, M>,
    then: Expr<T, M>,
    otherwise: Expr<T, M>,
): Expr<T, M> = conditional(test, then, otherwise) as Expr<T, M>

/**
 * This never missing expression, such as a literal, under the policy [M] of the composition around it. Kotlin cannot
 * see that [Handled] is the narrowest policy, so a shortcut generic in [M] lifts its literals explicitly.
 */
@Suppress("UNCHECKED_CAST")
internal fun <T, M : MissingPolicy> Expr<T, Handled>.lift(): Expr<T, M> = this as Expr<T, M>

/** This expression where a nullable one is expected; a value of T is a value of T?. */
@Suppress("UNCHECKED_CAST")
internal fun <T, M : MissingPolicy> Expr<T, M>.orNull(): Expr<T?, M> = this as Expr<T?, M>

/** The explicit null literal. */
internal fun <T, M : MissingPolicy> nullLiteral(): Expr<T?, M> = portableLiteral<T?>(DataValue.NULL).lift()

/**
 * Projects the field [name] of a complete record, such as a calendar fields or entry record a primitive produced.
 * Such a record always has the field, so the projection is missing exactly when the record is.
 */
@Suppress("UNCHECKED_CAST")
internal fun <V, M : MissingPolicy> Expr<*, M>.member(name: String): Expr<V, M> = field<V>(name) as Expr<V, M>

/** The key of a map entry. */
internal val <K, M : MissingPolicy> Expr<out Map.Entry<K, *>, M>.entryKey: Expr<K, M> get() = member("key")

/** The value of a map entry. */
internal val <V, M : MissingPolicy> Expr<out Map.Entry<*, V>, M>.entryValue: Expr<V, M> get() = member("value")
