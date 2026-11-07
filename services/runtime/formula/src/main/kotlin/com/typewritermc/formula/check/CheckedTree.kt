package com.typewritermc.formula.check

import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.BinaryOperator
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.TypeUse

/**
 * The checked tree the interpreter runs. Every name is already decided, every call names its function and its solved
 * type arguments, and every operator is the call or built in node it means. A part that did not check is an [Invalid]
 * node, which the interpreter never reaches, since a formula with problems does not run.
 */
sealed interface CheckedExpression {
    val type: TypeUse
    val span: TextSpan
}

/** A constant: a Kotlin `Int`, `Long`, `Double`, `BigDecimal`, `String`, `Boolean`, or null. */
data class Constant(
    val value: Any?,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** A value bound in the formula or given to it: a `let`, a parameter, a lambda parameter, or a context value. */
data class LocalRead(
    val name: String,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** What naming the resource [id] gives. */
data class ResourceRead(
    val id: ResourceId,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/**
 * Field [field] of [target]: a record's field, or the field of the resource a reference points at. A `Var` field
 * reads as its value. With [safe], a null target gives null.
 */
data class FieldRead(
    val target: CheckedExpression,
    val field: String,
    val safe: Boolean,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/**
 * A call of a formula function. [arguments] holds one entry per slot of the signature, context first; null is a
 * defaulted parameter the call left out. With [safe], a null first context argument gives null without the call.
 */
data class FunctionCall(
    val function: FormulaFunction,
    val typeArguments: Map<ParameterKey, TypeUse>,
    val arguments: List<CheckedExpression?>,
    val safe: Boolean,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** A formula function used as a function value, with its type arguments solved. */
data class FunctionReference(
    val function: FormulaFunction,
    val typeArguments: Map<ParameterKey, TypeUse>,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** A call of a function value, with one argument per context slot and parameter of its type, context first. */
data class Invoke(
    val function: CheckedExpression,
    val arguments: List<CheckedExpression>,
    val safe: Boolean,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** A record of [type] built from [fields] by name, code or content alike; a field with a constructor default may be absent. */
data class Construct(
    val fields: Map<String, CheckedExpression>,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** A function value whose [parameters] are bound in [body]. */
data class Lambda(
    val parameters: List<CheckedBinding>,
    val body: CheckedExpression,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** Lines that run in order; the block's value is [result]'s. */
data class Block(
    val lines: List<CheckedLine>,
    val result: CheckedExpression,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

sealed interface CheckedLine

/**
 * `let binding = value`. With [otherwise], a null [value] ends the block with [otherwise]'s value instead, and the
 * binding has the value's non null type.
 */
data class LetLine(
    val binding: CheckedBinding,
    val value: CheckedExpression,
    val otherwise: CheckedExpression?,
) : CheckedLine

/** A local function, in scope in its own body, so it may recurse. */
data class FunctionLine(
    val name: String,
    val function: Lambda,
) : CheckedLine

/** An expression line whose value is not used. */
data class ExpressionLine(
    val value: CheckedExpression,
) : CheckedLine

/** What a `let`, a lambda parameter or a case pattern binds. */
sealed interface CheckedBinding {
    data class Named(
        val name: String,
        val type: TypeUse,
    ) : CheckedBinding

    /** Binds the record's [fields] by field name. */
    data class Fields(
        val fields: List<Pair<String, CheckedBinding>>,
    ) : CheckedBinding

    /** `_`: binds nothing. */
    data object Ignored : CheckedBinding
}

/** `if`: [condition] is a Boolean expression, or with [binding], a nullable value bound when it is not null. */
data class If(
    val condition: CheckedExpression,
    val binding: CheckedBinding?,
    val then: CheckedExpression,
    val otherwise: CheckedExpression,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/**
 * `when`: the first arm whose pattern matches and whose guard holds gives the value. The subject, when there is one,
 * is bound as [subjectName], so value and `in` patterns read it as a local.
 */
data class When(
    val subject: CheckedExpression?,
    val subjectName: String?,
    val arms: List<WhenArm>,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

data class WhenArm(
    val patterns: List<CheckedPattern>,
    val guard: CheckedExpression?,
    val body: CheckedExpression,
)

sealed interface CheckedPattern {
    /** The subject is a value of [type]; [bindings] bind its fields, and [narrowed] names the subject again at [type]. */
    data class Is(
        val type: TypeUse,
        val bindings: List<Pair<String, CheckedBinding>>,
        val narrowed: String?,
    ) : CheckedPattern

    /** A Boolean expression over the subject's local: a value pattern, an `in` pattern, or a condition. */
    data class Test(
        val condition: CheckedExpression,
    ) : CheckedPattern

    data object Else : CheckedPattern
}

/** `==` or `!=` when [negated]: structural equality. */
data class Equals(
    val left: CheckedExpression,
    val right: CheckedExpression,
    val negated: Boolean,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** [comparison] is a `compareTo` call; the result is [operator] applied to its answer and zero. */
data class Compare(
    val comparison: CheckedExpression,
    val operator: BinaryOperator,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** `and`, `or`, or a chained comparison: [right] runs only when [left] does not decide. */
data class Logic(
    val operator: BinaryOperator,
    val left: CheckedExpression,
    val right: CheckedExpression,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

data class Not(
    val value: CheckedExpression,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** `left ?: right`: [right] runs only when [left] is null. */
data class Elvis(
    val left: CheckedExpression,
    val right: CheckedExpression,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** `value is tested`, or `!is` when [negated]. */
data class TypeTest(
    val value: CheckedExpression,
    val tested: TypeUse,
    val negated: Boolean,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** `value as? tested`: the value when it is a [tested], otherwise null. */
data class SafeCast(
    val value: CheckedExpression,
    val tested: TypeUse,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

data class ListOf(
    val items: List<CheckedExpression>,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

data class MapOf(
    val entries: List<Pair<CheckedExpression, CheckedExpression>>,
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression

/** A part that did not check; its problem is in the formula's problems. */
data class Invalid(
    override val type: TypeUse,
    override val span: TextSpan,
) : CheckedExpression
