package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.Argument
import com.typewritermc.formula.syntax.Call
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.Index
import com.typewritermc.formula.syntax.LiteralValue
import com.typewritermc.formula.syntax.Member
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.StringTemplate
import com.typewritermc.formula.syntax.TemplatePart
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.floatScalar
import com.typewritermc.types.function
import com.typewritermc.types.named
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigDecimal
import com.typewritermc.formula.syntax.ListLiteral as ListNode
import com.typewritermc.formula.syntax.MapLiteral as MapNode

// Literals, names, calls, collections and string templates.

internal fun Checker.literal(
    value: LiteralValue,
    span: TextSpan,
    expected: TypeUse?,
    negative: Boolean,
): CheckedExpression {
    val scalar = (expected?.nonNull() as? TypeUse.ScalarWrapper)?.value
    return when (value) {
        is LiteralValue.Integer -> number(BigDecimal.valueOf(value.value).signed(negative), scalar, span, whole = true)
        is LiteralValue.Decimal -> number(value.value.signed(negative), scalar, span, whole = false)
        is LiteralValue.Text -> Constant(value.value, TEXT, span)
        is LiteralValue.Bool -> Constant(value.value, BOOLEAN, span)
        LiteralValue.Null -> Constant(null, if (expected?.isNullable == true) expected else NULL, span)
    }
}

private fun BigDecimal.signed(negative: Boolean): BigDecimal = if (negative) negate() else this

/**
 * A number literal takes the expected numeric type; otherwise a whole number is an Int, or a Long when it must be.
 * Its value is the form a stored value of that type has: an exact Int or Long, the nearest Float or Double, or the
 * Decimal exactly as written.
 */
private fun Checker.number(
    value: BigDecimal,
    expected: ScalarKind?,
    span: TextSpan,
    whole: Boolean,
): CheckedExpression {
    val kind = numberKind(value, expected, whole)
    val constant: Any? =
        when (kind) {
            is ScalarKind.IntegerWrapper -> {
                runCatching {
                    if (kind.use ==
                        INT
                    ) {
                        value.intValueExact()
                    } else {
                        value.longValueExact()
                    }
                }.getOrNull()
            }

            is ScalarKind.FloatWrapper -> {
                if (kind.value.width == FloatWidth.THIRTY_TWO) {
                    value.toFloat().takeIf(Float::isFinite)
                } else {
                    value.toDouble().takeIf(Double::isFinite)
                }
            }

            else -> {
                value
            }
        }
    if (constant == null) {
        report(span, "formula_number_out_of_range", "$value does not fit ${shown(kind.use)}")
        return Invalid(ERROR, span)
    }
    return Constant(constant, kind.use, span)
}

private fun numberKind(
    value: BigDecimal,
    expected: ScalarKind?,
    whole: Boolean,
): ScalarKind =
    when {
        expected is ScalarKind.IntegerWrapper && whole -> expected
        expected is ScalarKind.FloatWrapper || expected == ScalarKind.DECIMAL -> expected
        !whole -> floatScalar(FloatWidth.SIXTY_FOUR)
        runCatching { value.intValueExact() }.isSuccess -> (INT as TypeUse.ScalarWrapper).value
        else -> (LONG as TypeUse.ScalarWrapper).value
    }

/** A name: a value, read or called by what is expected; a case; a function, called or as a value; or a type. */
internal fun Checker.name(
    name: Name,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val wantedFunction = expected?.nonNull()?.function
    return when (val named = lookup(name, expected, scope)) {
        is Named.Value -> {
            val function = named.node.type.function
            if (function != null &&
                wantedFunction == null
            ) {
                invoke(named.node, function, emptyList(), expected, false, name.span, scope)
            } else {
                named.node
            }
        }

        is Named.Case -> {
            construct(named.type, emptyList(), name.span, scope)
        }

        is Named.Functions -> {
            if (wantedFunction != null) {
                functionValue(name, named.functions, wantedFunction)
            } else {
                callFunctions(named.functions, null, emptyList(), expected, false, name.span, scope)
            }
        }

        is Named.Type -> {
            Constant(named.type, TYPE_VALUE, name.span)
        }

        Named.Nothing -> {
            Invalid(ERROR, name.span)
        }
    }
}

internal fun written(argument: Argument): CallArgument = CallArgument.Written(argument.name, argument.value, argument.span)

internal fun written(expression: Expression): CallArgument = CallArgument.Written(null, expression, expression.span)

internal fun Checker.call(
    call: Call,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val arguments = call.arguments.map(::written) + listOfNotNull(call.trailing?.let(::written))
    return when (val callee = call.callee) {
        is Name -> callName(callee, arguments, expected, call.span, scope)
        is Member -> callMember(callee, arguments, expected, call.span, scope)
        else -> invokeValue(synthOnce(callee, scope), arguments, expected, false, call.span, scope)
    }
}

private fun Checker.callName(
    callee: Name,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    val looked = lookup(callee, null, scope)
    val named = if (looked is Named.Nothing) caseCallee(callee, expected) ?: looked else looked
    return when (named) {
        is Named.Value -> invokeValue(named.node, arguments, expected, false, span, scope)
        is Named.Case -> construct(named.type, arguments, span, scope)
        is Named.Type -> construct(named.type, arguments, span, scope)
        is Named.Functions -> callFunctions(named.functions, null, arguments, expected, false, span, scope)
        Named.Nothing -> construct(ERROR, arguments, span, scope)
    }
}

private fun Checker.callMember(
    callee: Member,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    qualifiedType(callee, scope)?.let { return construct(it, arguments, span, scope) }
    val target = synthOnce(callee.target, scope)
    if (target.type == ERROR) return construct(ERROR, arguments, span, scope)
    val field =
        fieldType(target.type.nonNull(), callee.name.text)
            ?: return callNamed(callee.name.text, target, arguments, expected, span, scope, callee.safe, callee.name)
    val read = FieldRead(target, callee.name.text, callee.safe, field, callee.span)
    return invokeValue(read, arguments, expected, callee.safe, span, scope)
}

/** A case name the lookup did not know because a callee has no expected type of its own: the expected union's case. */
private fun Checker.caseCallee(
    callee: Name,
    expected: TypeUse?,
): Named? {
    val case = caseNamed(callee.text, expected) ?: return null
    trace.problems.removeAll { it.span == callee.span }
    trace.names.removeAll { it.span == callee.span }
    answer(callee, NameMeaning.Case, environment.inScope(callee.text))
    return Named.Case(case)
}

private fun Checker.invokeValue(
    callee: CheckedExpression,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    safe: Boolean,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    if (callee.type == ERROR) return construct(ERROR, arguments, span, scope)
    val function = callee.type.nonNull().function
    if (function == null) {
        report(callee.span, "formula_not_callable", "This is a ${shown(callee.type)}, not a function")
        return construct(ERROR, arguments, span, scope)
    }
    return invoke(callee, function, arguments, expected, safe, span, scope)
}

/** Calls the functions named [name] with [receiver] as their first context slot. */
internal fun Checker.callNamed(
    name: String,
    receiver: CheckedExpression,
    arguments: List<CallArgument>,
    expected: TypeUse?,
    span: TextSpan,
    scope: Scope,
    safe: Boolean = false,
    member: Name? = null,
    operator: String? = null,
): CheckedExpression {
    val functions = environment.functions(name)
    if (functions.isNotEmpty() ||
        receiver.type == ERROR
    ) {
        return callFunctions(functions, receiver, arguments, expected, safe, span, scope, operator)
    }
    if (member != null) {
        report(member.span, "formula_unknown_member", "${shown(recordBehind(receiver.type.nonNull()))} has no member `$name`")
    } else {
        report(span, "formula_type_mismatch", "`${operator ?: name}` does not apply to ${shown(receiver.type)}")
    }
    arguments.filterIsInstance<CallArgument.Written>().forEach { infer(it.value, null, scope) }
    return Invalid(ERROR, span)
}

internal fun Checker.index(
    index: Index,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression = callNamed("get", synthOnce(index.target, scope), listOf(written(index.index)), expected, index.span, scope)

internal fun Checker.list(
    node: ListNode,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val wanted = expected?.nonNull()?.named?.takeIf { it.definition == StandardTypes.list || it.definition == StandardTypes.set }
    val item = wanted?.arguments?.singleOrNull()
    val items = node.items.map { infer(it, item, scope).also { checked -> if (item != null) expect(checked, item) } }
    val type =
        item ?: joinAll(items.map { it.type }) ?: run {
            cannotInferAt(node.span)
            return Invalid(ERROR, node.span)
        }
    return ListOf(items, (wanted?.definition ?: StandardTypes.list).use(listOf(type)), node.span)
}

internal fun Checker.map(
    node: MapNode,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val wanted = expected?.nonNull()?.named?.takeIf { it.definition == StandardTypes.map }
    val key = wanted?.arguments?.getOrNull(0)
    val value = wanted?.arguments?.getOrNull(1)
    val entries = node.entries.map { (k, v) -> checked(k, key, scope) to checked(v, value, scope) }
    val keyType = key ?: joinAll(entries.map { it.first.type })
    val valueType = value ?: joinAll(entries.map { it.second.type })
    if (keyType == null || valueType == null) {
        cannotInferAt(node.span)
        return Invalid(ERROR, node.span)
    }
    return MapOf(entries, StandardTypes.map.use(listOf(keyType, valueType)), node.span)
}

private fun Checker.checked(
    expression: Expression,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression = infer(expression, expected, scope).also { if (expected != null) expect(it, expected) }

/** The type every one of [types] fits, the error type when they disagree, or null when there are none. */
private fun Checker.joinAll(types: List<TypeUse>): TypeUse? = types.reduceOrNull { a, b -> join(a, b) ?: ERROR }

/** `"a${x}b"` is `template(["a", x.interpolate(), "b"])`, with the `template` the expected type picks. */
internal fun Checker.template(
    node: StringTemplate,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val wanted = expected?.nonNull()?.takeUnless { it == ERROR } ?: TEXT
    val function =
        environment.functions("template").firstOrNull {
            it.signature.result
                .applied(emptyMap())
                ?.let { result -> fits(result, wanted) } ==
                true
        }
    val partType =
        (
            function
                ?.signature
                ?.parameters
                ?.singleOrNull()
                ?.type as? TypeTemplate.NamedWrapper
        )?.value?.arguments?.singleOrNull()?.applied(
            emptyMap(),
        )
    if (function == null || partType == null) {
        report(node.span, "formula_type_mismatch", "No string template makes a ${shown(wanted)}")
        for (part in node.parts) if (part is TemplatePart.Hole) synthOnce(part.value, scope)
        return Invalid(ERROR, node.span)
    }
    val parts =
        node.parts.map { part ->
            when (part) {
                is TemplatePart.Text -> Constant(part.text, TEXT, part.span)
                is TemplatePart.Hole -> hole(part, partType, scope)
            }
        }
    if (parts.any { it.type == ERROR }) return Invalid(ERROR, node.span)
    trace.providers += function.name
    return FunctionCall(
        function,
        emptyMap(),
        listOf(ListOf(parts, StandardTypes.list.use(listOf(partType)), node.span)),
        false,
        wanted,
        node.span,
    )
}

/** `${value}` is `value.interpolate()`, and `${value:format}` is `value.format("format").interpolate()`. */
private fun Checker.hole(
    hole: TemplatePart.Hole,
    partType: TypeUse,
    scope: Scope,
): CheckedExpression {
    var value = synthOnce(hole.value, scope)
    val format = hole.format
    if (format != null && value.type != ERROR) {
        value = callNamed("format", value, listOf(CallArgument.Given(Constant(format, TEXT, hole.span))), null, hole.span, scope)
    }
    if (value.type == ERROR) return Invalid(ERROR, hole.span)
    return callNamed("interpolate", value, emptyList(), partType, hole.span, scope)
}
