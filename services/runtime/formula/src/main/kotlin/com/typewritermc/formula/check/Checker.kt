package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.Binary
import com.typewritermc.formula.syntax.Call
import com.typewritermc.formula.syntax.ChainedComparison
import com.typewritermc.formula.syntax.Error
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.Index
import com.typewritermc.formula.syntax.Literal
import com.typewritermc.formula.syntax.Member
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.Parsed
import com.typewritermc.formula.syntax.Shorthand
import com.typewritermc.formula.syntax.StringTemplate
import com.typewritermc.formula.syntax.Unary
import com.typewritermc.types.function
import com.typewritermc.types.memberName
import skirout.editor.v1.type_catalog.AppliedSchema
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import java.util.IdentityHashMap
import com.typewritermc.formula.syntax.Block as BlockNode
import com.typewritermc.formula.syntax.If as IfNode
import com.typewritermc.formula.syntax.Lambda as LambdaNode
import com.typewritermc.formula.syntax.ListLiteral as ListNode
import com.typewritermc.formula.syntax.MapLiteral as MapNode
import com.typewritermc.formula.syntax.SafeCast as SafeCastNode
import com.typewritermc.formula.syntax.TypeTest as TypeTestNode
import com.typewritermc.formula.syntax.When as WhenNode

/** How deep the checker walks before it reports a problem instead, so very deep text cannot overflow the stack. */
private const val MAX_DEPTH = 200

/** What checking found so far: problems, name answers and reads. A call's candidates each check in a trace of their own. */
internal class Trace {
    val problems = mutableListOf<FormulaProblem>()
    val names = mutableListOf<NameAnswer>()
    val context = mutableSetOf<String>()
    val providers = mutableSetOf<String>()

    /** Expressions checked once and shared by every candidate that used them; counted once, by whichever is kept. */
    val shared = LinkedHashSet<Shared>()

    fun absorb(other: Trace) {
        problems += other.problems
        names += other.names
        context += other.context
        providers += other.providers
        shared += other.shared
    }
}

internal class Shared(
    val node: CheckedExpression,
    val trace: Trace,
) {
    var counted = false
}

/**
 * Checks one formula. The expected type goes down through [infer] and the inferred type comes up in each node; a
 * problem stays at its span and its part gets the error type, which fits everywhere, so the rest keeps checking.
 */
internal class Checker(
    val environment: FormulaEnvironment,
    references: List<StoredReference>,
    private val context: List<FunctionParameterUse>,
    private val parameters: List<FunctionParameterUse>,
) {
    val referenceAt: Map<TextSpan, StoredReference> = references.associateBy { it.at }
    var trace = Trace()
    val schemas = mutableMapOf<TypeUse, AppliedSchema?>()

    /** The type each `is` test named, so an `if` can narrow its subject in the branch where the test holds. */
    val typeTests = IdentityHashMap<TypeTestNode, TypeUse>()
    private val once = IdentityHashMap<Expression, IdentityHashMap<Scope, Shared>>()
    private var depth = 0

    fun run(
        parsed: Parsed<Expression>,
        expected: TypeUse?,
    ): CheckedFormula {
        for (problem in parsed.problems) report(problem.span, "formula_syntax", problem.message)
        // A position whose content type is gone has the error type, so its body adds nothing to that type's finding.
        val result = expected?.let { normalize(it) }
        val scope = Scope.root(context.map { it.copy(type = normalize(it.type)) }, parameters.map { it.copy(type = normalize(it.type)) })
        val tree = infer(parsed.root, result, scope)
        if (result != null) expect(tree, result)
        val all = Trace()
        collect(trace, all)
        val problems = all.problems.distinct().sortedBy { it.span.start }
        val type = (result ?: tree.type).takeIf { problems.isEmpty() && !tree.type.mentionsError() }
        return CheckedFormula(
            tree = tree,
            type = type,
            problems = problems,
            reads = FormulaReads(all.context.toSet(), all.providers.toSet()),
            names = all.names.distinctBy { it.span }.sortedBy { it.span.start },
        )
    }

    private fun collect(
        from: Trace,
        into: Trace,
    ) {
        into.problems += from.problems
        into.names += from.names
        into.context += from.context
        into.providers += from.providers
        for (shared in from.shared) {
            if (shared.counted) continue
            shared.counted = true
            collect(shared.trace, into)
        }
    }

    fun report(
        span: TextSpan,
        code: String,
        message: String,
    ) {
        trace.problems += FormulaProblem(span, code, message)
    }

    /** Runs [block] in a fresh trace and gives that trace back, leaving the current one as it was. */
    fun forked(block: () -> Unit): Trace {
        val outer = trace
        val inner = Trace()
        trace = inner
        try {
            block()
        } finally {
            trace = outer
        }
        return inner
    }

    fun absorb(other: Trace) = trace.absorb(other)

    /** [expression] inferred with no expected type, once per scope however many candidates read it. */
    fun synthOnce(
        expression: Expression,
        scope: Scope,
    ): CheckedExpression {
        val byScope = once.getOrPut(expression) { IdentityHashMap() }
        val shared =
            byScope.getOrPut(scope) {
                var node: CheckedExpression? = null
                val trace = forked { node = infer(expression, null, scope) }
                Shared(node!!, trace)
            }
        trace.shared += shared
        return shared.node
    }

    /** Reports a mismatch when [node] does not fit [expected]. */
    fun expect(
        node: CheckedExpression,
        expected: TypeUse,
    ) {
        if (!fits(node.type, expected)) {
            report(node.span, "formula_type_mismatch", "Expected ${shown(expected)}, found ${shown(node.type)}")
        }
    }

    /** Checks [expression] against [expected], or infers its type when [expected] is null. */
    fun infer(
        expression: Expression,
        expected: TypeUse?,
        scope: Scope,
    ): CheckedExpression {
        if (depth >= MAX_DEPTH) {
            report(expression.span, "formula_too_deep", "This formula nests too deeply")
            return Invalid(ERROR, expression.span)
        }
        depth++
        try {
            return when (expression) {
                is Literal, is Name, is Member, is Call, is Index, is StringTemplate -> inferValue(expression, expected, scope)
                is Binary, is ChainedComparison, is Unary, is TypeTestNode, is SafeCastNode -> inferOperator(expression, expected, scope)
                else -> inferStructure(expression, expected, scope)
            }
        } finally {
            depth--
        }
    }

    private fun inferValue(
        expression: Expression,
        expected: TypeUse?,
        scope: Scope,
    ): CheckedExpression =
        when (expression) {
            is Literal -> literal(expression.value, expression.span, expected, negative = false)
            is Name -> name(expression, expected, scope)
            is Member -> member(synthOnce(expression.target, scope), expression.name, expression.safe, expected, scope, expression.span)
            is Call -> call(expression, expected, scope)
            is Index -> index(expression, expected, scope)
            is StringTemplate -> template(expression, expected, scope)
            else -> error("Not a value expression: $expression")
        }

    private fun inferOperator(
        expression: Expression,
        expected: TypeUse?,
        scope: Scope,
    ): CheckedExpression =
        when (expression) {
            is Binary -> binary(expression, expected, scope)
            is ChainedComparison -> chain(expression, scope)
            is Unary -> unary(expression, expected, scope)
            is TypeTestNode -> typeTest(expression, scope)
            is SafeCastNode -> safeCast(expression, scope)
            else -> error("Not an operator expression: $expression")
        }

    private fun inferStructure(
        expression: Expression,
        expected: TypeUse?,
        scope: Scope,
    ): CheckedExpression =
        when (expression) {
            is IfNode -> ifExpression(expression, expected, scope)
            is WhenNode -> whenExpression(expression, expected, scope)
            is BlockNode -> block(expression, expected, scope)
            is LambdaNode -> lambda(expression, expected?.nonNull()?.function, scope)
            is Shorthand -> shorthand(expression, expected?.nonNull()?.function, scope)
            is ListNode -> list(expression, expected, scope)
            is MapNode -> map(expression, expected, scope)
            is Error -> Invalid(ERROR, expression.span)
            else -> error("Not a structure expression: $expression")
        }
}

/** A short name for a type, for messages. */
internal fun shown(type: TypeUse): String =
    when (type) {
        ERROR -> "value"

        NULL -> "null"

        is TypeUse.NullableWrapper -> "${shown(type.value.value)}?"

        is TypeUse.ScalarWrapper -> scalarNames[type.value] ?: "number"

        is TypeUse.FunctionWrapper -> "(${type.value.parameters.joinToString {
            "${it.name}: ${shown(
                it.type,
            )}"
        }}) -> ${shown(type.value.result)}"

        is TypeUse.NamedWrapper -> shownNamed(type)

        else -> "value"
    }

private fun shownNamed(type: TypeUse.NamedWrapper): String {
    val id = type.value.definition
    val name = id.memberName ?: (id.typeId as? TypeId.QualifiedWrapper)?.value?.name?.substringAfterLast('.') ?: "record"
    return if (type.value.arguments.isEmpty()) name else "$name<${type.value.arguments.joinToString { shown(it) }}>"
}

internal fun shownTemplate(template: TypeTemplate): String = template.applied(emptyMap())?.let(::shown) ?: "a matching value"

private val scalarNames: Map<ScalarKind, String> =
    mapOf(
        ScalarKind.TEXT to "String",
        ScalarKind.BOOLEAN to "Boolean",
        ScalarKind.DECIMAL to "Decimal",
        ScalarKind.TIMESTAMP to "Instant",
        ScalarKind.DURATION to "Duration",
        ScalarKind.UNIT to "Unit",
        ScalarKind.TYPE to "Type",
        (INT as TypeUse.ScalarWrapper).value to "Int",
        (LONG as TypeUse.ScalarWrapper).value to "Long",
        com.typewritermc.types.floatScalar(FloatWidth.THIRTY_TWO) to "Float",
        com.typewritermc.types.floatScalar(FloatWidth.SIXTY_FOUR) to "Double",
    )
