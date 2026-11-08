package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.Binding
import com.typewritermc.formula.syntax.Destructuring
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.Let
import com.typewritermc.formula.syntax.LetCondition
import com.typewritermc.formula.syntax.LocalFunction
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.NameBinding
import com.typewritermc.formula.syntax.Shorthand
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.TypeUse
import com.typewritermc.formula.syntax.Block as BlockNode
import com.typewritermc.formula.syntax.If as IfNode
import com.typewritermc.formula.syntax.Lambda as LambdaNode
import com.typewritermc.formula.syntax.TypeTest as TypeTestNode

// What binds names: blocks and their `let`s, local functions, lambdas, `if let`, and narrowing after `is`.

internal fun Checker.ifExpression(
    node: IfNode,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val (condition, binding, thenScope) =
        when (val written = node.condition) {
            is LetCondition -> {
                val value = infer(written.value, null, scope)
                val (binding, bound) = bind(written.binding, value.type.nonNull(), scope)
                Triple(value, binding, bound)
            }

            is Expression -> {
                Triple(condition(written, scope), null, narrowedBy(written, scope))
            }
        }
    val then = infer(node.then, expected, thenScope)
    val written = node.otherwise
    if (written == null) {
        report(node.span, "formula_if_needs_else", "This `if` needs an `else`, since the formula needs a value either way")
        return Invalid(ERROR, node.span)
    }
    val otherwise = infer(written, expected, scope)
    if (expected != null) {
        expect(then, expected)
        expect(otherwise, expected)
    }
    val type =
        expected ?: join(then.type, otherwise.type) ?: run {
            report(written.span, "formula_type_mismatch", "The branches give a ${shown(then.type)} and a ${shown(otherwise.type)}")
            ERROR
        }
    return If(condition, binding, then, otherwise, type, node.span)
}

/** The scope where [condition] holds: `x is T` narrows a name `x` to `T`. */
private fun Checker.narrowedBy(
    condition: Expression,
    scope: Scope,
): Scope {
    if (condition !is TypeTestNode || condition.negated) return scope
    val subject = condition.value as? Name ?: return scope
    val type = typeTests[condition] ?: return scope
    return scope.narrowing(subject.text, type)
}

internal fun Checker.block(
    block: BlockNode,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val lines = mutableListOf<CheckedLine>()
    var current = scope
    for ((index, line) in block.lines.withIndex()) {
        val (checked, next) =
            when (line) {
                is Let -> let(line, expected, current)
                is LocalFunction -> localFunction(line, current)
                is Expression -> (if (index == block.lines.lastIndex) null else ExpressionLine(infer(line, null, current))) to current
            }
        checked?.let(lines::add)
        current = next
    }
    val last = block.lines.lastOrNull() as? Expression
    if (last == null) {
        report(block.lines.lastOrNull()?.span ?: block.span, "formula_block_needs_value", "A block ends with the value it gives")
        return Invalid(ERROR, block.span)
    }
    val result = infer(last, expected, current)
    if (lines.isEmpty()) return result
    return Block(lines, result, result.type, block.span)
}

private fun Checker.let(
    line: Let,
    expected: TypeUse?,
    scope: Scope,
): Pair<CheckedLine, Scope> {
    val declared = (line.binding as? NameBinding)?.type?.let { lower(it, scope) }
    val wanted = if (line.otherwise != null) declared?.orNull() else declared
    val value = infer(line.value, wanted, scope)
    if (wanted != null) expect(value, wanted)
    val otherwise = line.otherwise?.let { infer(it, expected, scope) }
    if (line.otherwise != null && !value.type.isNullable && value.type != ERROR) {
        report(line.value.span, "formula_let_else_needs_nullable", "`let ... else` needs a value that may be null")
    }
    val type = declared ?: if (line.otherwise != null) value.type.nonNull() else value.type
    val (binding, next) = bind(line.binding, type, scope, typeChecked = declared != null)
    return LetLine(binding, value, otherwise) to next
}

/** What [binding] binds when it receives a value of [type], and the scope with those names. */
internal fun Checker.bind(
    binding: Binding,
    type: TypeUse,
    scope: Scope,
    typeChecked: Boolean = false,
): Pair<CheckedBinding, Scope> =
    when (binding) {
        is NameBinding -> bindName(binding, type, scope, typeChecked)
        is Destructuring -> destructure(binding, type, scope)
    }

private fun Checker.bindName(
    binding: NameBinding,
    type: TypeUse,
    scope: Scope,
    typeChecked: Boolean,
): Pair<CheckedBinding, Scope> {
    val declared = if (typeChecked) null else binding.type?.let { lower(it, scope) }
    if (declared != null && !fits(type, declared)) {
        report(binding.span, "formula_type_mismatch", "Expected ${shown(declared)}, found ${shown(type)}")
    }
    val bound = declared ?: type
    if (binding.name.text == "_") return CheckedBinding.Ignored to scope
    return CheckedBinding.Named(binding.name.text, bound) to scope.with(Bound(binding.name.text, bound, NameMeaning.Local))
}

/** `(a, b)` binds a record's fields in their declared order. */
private fun Checker.destructure(
    binding: Destructuring,
    type: TypeUse,
    scope: Scope,
): Pair<CheckedBinding, Scope> {
    val fields = if (type == ERROR) null else schema(recordBehind(type))?.fields
    if (fields == null && type != ERROR) {
        report(binding.span, "formula_cannot_destructure", "A ${shown(type)} has no fields to take apart")
    }
    if (fields != null && binding.parts.size > fields.size) {
        report(binding.span, "formula_cannot_destructure", "A ${shown(type)} has only ${fields.size} fields")
    }
    var current = scope
    val parts =
        binding.parts.mapIndexed { index, part ->
            val field = fields?.getOrNull(index)
            val (checked, next) = bind(part, field?.let { normalize(readType(it.type)) } ?: ERROR, current)
            current = next
            (field?.key ?: "") to checked
        }
    return CheckedBinding.Fields(parts) to current
}

/** `let f(n: Int): Int = ...`. Without a result type the body cannot call `f`, since checking is local. */
private fun Checker.localFunction(
    line: LocalFunction,
    scope: Scope,
): Pair<CheckedLine, Scope> {
    val parameters = line.parameters.map { FunctionParameterUse(name = it.name.text, type = lower(it.type, scope)) }
    val declared = line.result?.let { lower(it, scope) }
    val name = line.name.text
    val selfType = declared?.let { TypeUse.createFunction(context = emptyList(), parameters = parameters, result = it) }
    val inner = scope.with(Bound(name, selfType, NameMeaning.Local)).with(parameters.map { Bound(it.name, it.type, NameMeaning.Local) })
    val body = infer(line.body, declared, inner)
    if (declared != null) expect(body, declared)
    val type = TypeUse.createFunction(context = emptyList(), parameters = parameters, result = declared ?: body.type)
    val function = Lambda(parameters.map { CheckedBinding.Named(it.name, it.type) }, body, type, line.span)
    return FunctionLine(name, function) to scope.with(Bound(name, type, NameMeaning.Local))
}

/** A lambda against [expected]: its parameters take the expected parameter types, and an unnamed one is `it`. */
internal fun Checker.lambda(
    node: LambdaNode,
    expected: FunctionTypeUse?,
    scope: Scope,
): CheckedExpression {
    val expectedParameters = expected?.parameters
    val count = if (node.parameters.isEmpty() && expectedParameters?.size == 1) 1 else node.parameters.size
    if (expectedParameters != null && count != expectedParameters.size) {
        val plural = if (expectedParameters.size == 1) "" else "s"
        report(node.span, "formula_lambda_parameters", "This lambda takes ${expectedParameters.size} parameter$plural")
        return Invalid(ERROR, node.span)
    }
    val outer = scope.with(expected?.context.orEmpty().map { Bound(it.name, it.type, NameMeaning.Local) })
    val (bindings, types, inner) = lambdaParameters(node, expectedParameters, count, outer)
    val result = expected?.result?.takeUnless { it == ERROR }
    val body = infer(node.body, result, inner)
    if (result != null) expect(body, result)
    val parameters =
        types.mapIndexed {
            index,
            type,
            ->
            FunctionParameterUse(name = expectedParameters?.get(index)?.name ?: "p$index", type = type)
        }
    val type = TypeUse.createFunction(context = expected?.context.orEmpty(), parameters = parameters, result = result ?: body.type)
    return Lambda(bindings, body, type, node.span)
}

private fun Checker.lambdaParameters(
    node: LambdaNode,
    expected: List<FunctionParameterUse>?,
    count: Int,
    scope: Scope,
): Triple<List<CheckedBinding>, List<TypeUse>, Scope> {
    var inner = scope
    val bindings = mutableListOf<CheckedBinding>()
    val types = mutableListOf<TypeUse>()
    for (index in 0 until count) {
        val binding = node.parameters.getOrNull(index)
        val type =
            expected?.get(index)?.type ?: (binding as? NameBinding)?.type?.let { lower(it, scope) }
                ?: untypedParameter(binding?.span ?: node.span)
        val (checked, next) = if (binding == null) bindIt(type, inner) else bind(binding, type, inner)
        bindings += checked
        types += type
        inner = next
    }
    return Triple(bindings, types, inner)
}

private fun Checker.untypedParameter(span: TextSpan): TypeUse {
    report(span, "formula_cannot_infer", "The type of this lambda parameter cannot be inferred here; state it")
    return ERROR
}

private fun bindIt(
    type: TypeUse,
    scope: Scope,
): Pair<CheckedBinding, Scope> = CheckedBinding.Named("it", type) to scope.with(Bound("it", type, NameMeaning.Local))

/** `.a.b` against a function of one value: the lambda `{ it.a.b }`. */
internal fun Checker.shorthand(
    node: Shorthand,
    expected: FunctionTypeUse?,
    scope: Scope,
): CheckedExpression {
    val parameter = expected?.parameters?.singleOrNull()
    if (parameter == null) {
        report(node.span, "formula_cannot_infer", "`.${node.path.joinToString(".") { it.text }}` needs a function of one value here")
        return Invalid(ERROR, node.span)
    }
    val (binding, inner) = bindIt(parameter.type, scope)
    var body: CheckedExpression = LocalRead("it", parameter.type, TextSpan(node.span.start, node.span.start))
    val result = expected.result.takeUnless { it == ERROR }
    for ((index, name) in node.path.withIndex()) {
        val span = TextSpan(node.span.start, name.span.end)
        body = member(body, name, false, if (index == node.path.lastIndex) result else null, inner, span)
    }
    if (result != null) expect(body, result)
    val type = TypeUse.createFunction(context = expected.context, parameters = expected.parameters, result = result ?: body.type)
    return Lambda(listOf(binding), body, type, node.span)
}
