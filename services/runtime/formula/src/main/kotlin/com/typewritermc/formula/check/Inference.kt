package com.typewritermc.formula.check

import com.typewritermc.types.function
import com.typewritermc.types.integerScalar
import com.typewritermc.types.named
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.toUse
import com.typewritermc.types.use
import com.typewritermc.types.walk
import com.typewritermc.types.zipParts
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

// Type relations: when a value fits where another type is wanted, the type two branches share, and unification,
// which solves a call's type parameters as a plain substitution map. Function types are not generic and there is no
// inference across calls.

/** The type of a part that did not check. It fits everywhere, so one problem never causes another. */
internal val ERROR: TypeUse = TypeDefinitionId.qualified("formula", "error").use()

/** The type of `null` before it meets an expected type. */
internal val NULL: TypeUse = ERROR.nullable()

/** The type of a value that is itself a type, as a `Definition<Type>` holds. */
internal val TYPE_VALUE: TypeUse = ScalarKind.TYPE.use
internal val BOOLEAN: TypeUse = ScalarKind.BOOLEAN.use
internal val TEXT: TypeUse = ScalarKind.TEXT.use
internal val INT: TypeUse = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
internal val LONG: TypeUse = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use

internal val TypeUse.isNullable: Boolean get() = this is TypeUse.NullableWrapper

internal fun TypeUse.nonNull(): TypeUse = (this as? TypeUse.NullableWrapper)?.value?.value ?: this

internal fun TypeUse.orNull(): TypeUse = if (isNullable) this else nullable()

private val FunctionTypeUse.slots: List<FunctionParameterUse> get() = context + parameters

private val FunctionTypeTemplate.allSlots get() = context + parameters

internal fun TypeUse.mentionsError(): Boolean = walk().any { it == ERROR }

/**
 * Whether a value of [actual] may stand where [expected] is wanted. An alias stands for the type it names, everywhere
 * in either type. Parameter names do not matter for a function value.
 */
internal fun Checker.fits(
    actual: TypeUse,
    expected: TypeUse,
): Boolean = fitsExpanded(environment.expand(actual), environment.expand(expected))

private fun Checker.fitsExpanded(
    actual: TypeUse,
    expected: TypeUse,
): Boolean =
    when {
        actual == ERROR || expected == ERROR || actual == expected -> true
        expected is TypeUse.NullableWrapper -> fitsExpanded(actual.nonNull(), expected.value.value)
        actual is TypeUse.NamedWrapper -> expected.named?.let { fitsNamed(actual, it.definition, it.arguments) } == true
        actual is TypeUse.FunctionWrapper -> expected.function?.let { fitsFunction(actual.value, it) } == true
        else -> false
    }

private fun Checker.fitsNamed(
    actual: TypeUse.NamedWrapper,
    definition: TypeDefinitionId,
    arguments: List<TypeUse>,
): Boolean {
    val own = actual.value
    val matching = if (own.definition == definition) own else ancestors(actual).firstOrNull { it.definition == definition }
    return matching != null && matching.arguments.size == arguments.size && matching.arguments.zip(arguments).all { (a, b) -> same(a, b) }
}

private fun Checker.fitsFunction(
    actual: FunctionTypeUse,
    expected: FunctionTypeUse,
): Boolean =
    actual.context.size == expected.context.size &&
        actual.parameters.size == expected.parameters.size &&
        actual.slots.zip(expected.slots).all { (mine, theirs) -> fitsExpanded(theirs.type, mine.type) } &&
        fitsExpanded(actual.result, expected.result)

/** Equal, apart from parts that did not check. Type arguments are invariant. */
private fun same(
    a: TypeUse,
    b: TypeUse,
): Boolean = a == b || a == ERROR || b == ERROR || a.zipParts(b)?.all { (x, y) -> same(x, y) } == true

/** The wider of two branch types, or null when neither fits the other. */
internal fun Checker.join(
    a: TypeUse,
    b: TypeUse,
): TypeUse? =
    when {
        a == ERROR -> b
        b == ERROR -> a
        a == NULL -> b.orNull()
        b == NULL -> a.orNull()
        fits(a, b) -> b
        fits(b, a) -> a
        fits(a.nonNull(), b.nonNull()) -> b.orNull()
        fits(b.nonNull(), a.nonNull()) -> a.orNull()
        else -> null
    }

/**
 * Binds the free parameters of [template] so that [actual] fits it. False when it cannot fit. An alias in [actual]
 * stands for the type it names, so a parameter binds to that type.
 */
internal fun Checker.unify(
    template: TypeTemplate,
    actual: TypeUse,
    solved: MutableMap<ParameterKey, TypeUse>,
): Boolean = unifyExpanded(template, environment.expand(actual), solved)

private fun Checker.unifyExpanded(
    template: TypeTemplate,
    actual: TypeUse,
    solved: MutableMap<ParameterKey, TypeUse>,
): Boolean =
    when {
        actual == ERROR -> true
        template is TypeTemplate.ParameterWrapper -> unifyParameter(template.value, actual, solved)
        template is TypeTemplate.NullableWrapper -> unifyExpanded(template.value.value, actual.nonNull(), solved)
        template is TypeTemplate.NamedWrapper -> unifyNamed(template.value, actual, solved)
        template is TypeTemplate.FunctionWrapper -> actual.function?.let { unifyFunction(template.value, it, solved) } == true
        template is TypeTemplate.ScalarWrapper -> fits(actual, template.value.use)
        else -> false
    }

private fun Checker.unifyParameter(
    parameter: ParameterKey,
    actual: TypeUse,
    solved: MutableMap<ParameterKey, TypeUse>,
): Boolean {
    val bound = solved[parameter]
    return when {
        bound == null || fits(bound, actual) -> {
            solved[parameter] = actual
            true
        }

        else -> {
            fits(actual, bound)
        }
    }
}

private fun Checker.unifyNamed(
    wanted: NamedTypeTemplate,
    actual: TypeUse,
    solved: MutableMap<ParameterKey, TypeUse>,
): Boolean {
    val own = actual.named ?: return false
    val matching = if (own.definition == wanted.definition) own else ancestors(actual).firstOrNull { it.definition == wanted.definition }
    return matching != null &&
        matching.arguments.size == wanted.arguments.size &&
        matching.arguments.zip(wanted.arguments).all { (argument, slot) -> unifyExpanded(slot, argument, solved) }
}

private fun Checker.unifyFunction(
    wanted: FunctionTypeTemplate,
    actual: FunctionTypeUse,
    solved: MutableMap<ParameterKey, TypeUse>,
): Boolean =
    actual.context.size == wanted.context.size &&
        actual.parameters.size == wanted.parameters.size &&
        actual.slots.zip(wanted.allSlots).all { (mine, slot) -> unifyExpanded(slot.type, mine.type, solved) } &&
        unifyExpanded(wanted.result, actual.result, solved)

/** [template] with [solved] applied, or null while it still has a free parameter. */
internal fun TypeTemplate.applied(solved: Map<ParameterKey, TypeUse>): TypeUse? = toUse(solved::get)
