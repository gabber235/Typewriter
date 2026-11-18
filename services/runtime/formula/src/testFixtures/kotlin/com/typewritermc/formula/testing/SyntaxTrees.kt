package com.typewritermc.formula.testing

import com.typewritermc.formula.syntax.Argument
import com.typewritermc.formula.syntax.Binary
import com.typewritermc.formula.syntax.Binding
import com.typewritermc.formula.syntax.Block
import com.typewritermc.formula.syntax.Call
import com.typewritermc.formula.syntax.CaseNode
import com.typewritermc.formula.syntax.ChainedComparison
import com.typewritermc.formula.syntax.Condition
import com.typewritermc.formula.syntax.Destructuring
import com.typewritermc.formula.syntax.Error
import com.typewritermc.formula.syntax.ErrorType
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.FormulaNode
import com.typewritermc.formula.syntax.FunctionType
import com.typewritermc.formula.syntax.If
import com.typewritermc.formula.syntax.Index
import com.typewritermc.formula.syntax.Lambda
import com.typewritermc.formula.syntax.Let
import com.typewritermc.formula.syntax.LetCondition
import com.typewritermc.formula.syntax.Line
import com.typewritermc.formula.syntax.ListLiteral
import com.typewritermc.formula.syntax.Literal
import com.typewritermc.formula.syntax.LiteralValue
import com.typewritermc.formula.syntax.LocalFunction
import com.typewritermc.formula.syntax.MapLiteral
import com.typewritermc.formula.syntax.Member
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.NameBinding
import com.typewritermc.formula.syntax.NamedType
import com.typewritermc.formula.syntax.NullableType
import com.typewritermc.formula.syntax.ParameterNode
import com.typewritermc.formula.syntax.RecordType
import com.typewritermc.formula.syntax.SafeCast
import com.typewritermc.formula.syntax.Shorthand
import com.typewritermc.formula.syntax.StringTemplate
import com.typewritermc.formula.syntax.TemplatePart
import com.typewritermc.formula.syntax.TypeNode
import com.typewritermc.formula.syntax.TypeTest
import com.typewritermc.formula.syntax.Unary
import com.typewritermc.formula.syntax.UnionType
import com.typewritermc.formula.syntax.When
import com.typewritermc.formula.syntax.WhenArm
import com.typewritermc.formula.syntax.WhenPattern

/**
 * Prints a syntax tree as an S-expression, so a parser case states its grouping in one line: `1 + 2 * 3` prints
 * `(+ 1 (* 2 3))`. A block of one expression prints as that expression; a name that needs backticks prints quoted.
 */
fun FormulaNode.render(): String =
    when (this) {
        is Expression -> renderExpression()
        is TypeNode -> renderType()
        else -> renderPart()
    }

/** Every name in the tree, in source order. */
fun FormulaNode.names(): List<Name> = descendants().filterIsInstance<Name>()

/** This node and every node below it, parents before children. */
fun FormulaNode.descendants(): List<FormulaNode> = listOf(this) + children().flatMap { it.descendants() }

/** The nodes directly below this one, in source order. */
fun FormulaNode.children(): List<FormulaNode> =
    when (this) {
        is Expression -> expressionChildren()
        is TypeNode -> typeChildren()
        else -> partChildren()
    }

private fun sexp(vararg parts: String?): String = parts.filterNotNull().joinToString(" ", "(", ")")

private fun sexpOf(
    head: String?,
    nodes: List<FormulaNode>,
): String = sexp(head, *nodes.map { it.render() }.toTypedArray())

private val plainName = Regex("[\\p{L}_][\\p{L}\\p{N}_]*")

private fun Expression.renderExpression(): String =
    when (this) {
        is Name -> if (plainName.matches(text)) text else "\"$text\""
        is Literal -> value.render()
        is Error -> "(error)"
        is Shorthand -> sexpOf("short", path)
        is StringTemplate -> sexpOf("template", parts)
        is Member -> sexp(if (safe) "?." else ".", target.render(), name.render())
        is Index -> sexp("index", target.render(), index.render())
        is Call -> sexpOf("call", listOf(callee) + arguments + listOfNotNull(trailing))
        is Binary -> sexp(operator.symbol, left.render(), right.render())
        else -> renderCompound()
    }

private fun Expression.renderCompound(): String =
    when (this) {
        is ChainedComparison -> {
            sexp("chain", first.render(), *rest.flatMap { (op, value) -> listOf(op.symbol, value.render()) }.toTypedArray())
        }

        is Unary -> {
            sexp(operator.symbol, value.render())
        }

        is TypeTest -> {
            sexp(if (negated) "!is" else "is", value.render(), type.render())
        }

        is SafeCast -> {
            sexp("as?", value.render(), type.render())
        }

        is If -> {
            renderIf()
        }

        is When -> {
            sexp("when", subject?.renderSubject(), *arms.map { it.render() }.toTypedArray())
        }

        is Block -> {
            lines.singleOrNull()?.takeIf { it is Expression }?.render() ?: sexpOf("block", lines)
        }

        is Lambda -> {
            sexp("lambda", parameters.takeIf { it.isNotEmpty() }?.let { sexpOf(null, it) }, body.render())
        }

        is ListLiteral -> {
            sexpOf("list", items)
        }

        is MapLiteral -> {
            sexp("map", *entries.map { (key, value) -> sexp(key.render(), value.render()) }.toTypedArray())
        }

        else -> {
            error("Unrendered expression $this")
        }
    }

private fun If.renderIf(): String =
    when (val condition = condition) {
        is LetCondition -> {
            sexp("if-let", condition.binding.render(), condition.value.render(), then.render(), otherwise?.render())
        }

        is Expression -> {
            sexp("if", condition.render(), then.render(), otherwise?.render())
        }
    }

private fun Condition.renderSubject(): String =
    when (this) {
        is LetCondition -> sexp("let", binding.render(), value.render())
        is Expression -> render()
    }

private fun LiteralValue.render(): String =
    when (this) {
        is LiteralValue.Integer -> value.toString()
        is LiteralValue.Decimal -> value.toString()
        is LiteralValue.Text -> sexp("string", "\"$value\"")
        is LiteralValue.Bool -> value.toString()
        LiteralValue.Null -> "null"
    }

private fun FormulaNode.renderPart(): String =
    when (this) {
        is TemplatePart.Text -> "\"$text\""
        is TemplatePart.Hole -> sexp("hole", value.render(), format?.let { "\"$it\"" })
        is Argument -> name?.let { sexp("${it.render()}=", value.render()) } ?: value.render()
        is WhenArm -> sexp(*patterns.map { it.render() }.toTypedArray(), guard?.render(), body.render())
        is WhenPattern -> renderPattern()
        is Binding -> renderBinding()
        is Line -> renderLine()
        is ParameterNode -> sexp(name.render(), type.render())
        is CaseNode -> if (fields.isEmpty()) name.render() else sexpOf(name.render(), fields)
        else -> error("Unrendered node $this")
    }

private fun WhenPattern.renderPattern(): String =
    when (this) {
        is WhenPattern.Is -> "is " + (bindings?.let { sexpOf(type.render(), it) } ?: type.render())
        is WhenPattern.In -> "in " + value.render()
        is WhenPattern.Value -> value.render()
        is WhenPattern.Else -> "else"
    }

private fun Binding.renderBinding(): String =
    when (this) {
        is NameBinding -> type?.let { sexp(name.render(), it.render()) } ?: name.render()
        is Destructuring -> sexp(*parts.map { it.render() }.toTypedArray())
    }

private fun Line.renderLine(): String =
    when (this) {
        is Let -> {
            sexp("let", binding.render(), value.render(), otherwise?.let { sexp("else", it.render()) })
        }

        is LocalFunction -> {
            sexp(
                "fun",
                name.render(),
                *parameters.map { it.render() }.toTypedArray(),
                result?.let { ":" + it.render() },
                body.render(),
            )
        }

        is Expression -> {
            render()
        }
    }

private fun TypeNode.renderType(): String =
    when (this) {
        is NamedType -> {
            if (name.size == 1 && arguments.isEmpty()) {
                name.single().render()
            } else {
                sexp(*(name + arguments).map { it.render() }.toTypedArray())
            }
        }

        is NullableType -> {
            sexp("?", value.render())
        }

        is FunctionType -> {
            sexp(
                "fn",
                sexp(*context.map { it.render() }.toTypedArray()),
                sexp(*parameters.map { it.render() }.toTypedArray()),
                result.render(),
            )
        }

        is RecordType -> {
            sexpOf("record", fields)
        }

        is UnionType -> {
            sexpOf("union", fields + cases)
        }

        is ErrorType -> {
            "(error)"
        }
    }

private fun Expression.expressionChildren(): List<FormulaNode> =
    when (this) {
        is Name, is Literal, is Error -> emptyList()
        is Shorthand -> path
        is StringTemplate -> parts
        is Member -> listOf(target, name)
        is Index -> listOf(target, index)
        is Call -> listOf(callee) + arguments + listOfNotNull(trailing)
        is Binary -> listOf(left, right)
        is ChainedComparison -> listOf(first) + rest.map { it.second }
        is Unary -> listOf(value)
        else -> compoundChildren()
    }

private fun Expression.compoundChildren(): List<FormulaNode> =
    when (this) {
        is TypeTest -> listOf(value, type)
        is SafeCast -> listOf(value, type)
        is If -> listOfNotNull(condition, then, otherwise)
        is When -> listOfNotNull(subject) + arms
        is Block -> lines
        is Lambda -> parameters + body
        is ListLiteral -> items
        is MapLiteral -> entries.flatMap { listOf(it.first, it.second) }
        else -> error("No children known for $this")
    }

private fun TypeNode.typeChildren(): List<FormulaNode> =
    when (this) {
        is NamedType -> name + arguments
        is NullableType -> listOf(value)
        is FunctionType -> context + parameters + result
        is RecordType -> fields
        is UnionType -> (fields + cases).sortedBy { it.span.start }
        is ErrorType -> emptyList()
    }

private fun FormulaNode.partChildren(): List<FormulaNode> =
    when (this) {
        is TemplatePart.Text -> emptyList()
        is TemplatePart.Hole -> listOf(value)
        is Argument -> listOfNotNull(name, value)
        is WhenArm -> patterns + listOfNotNull(guard, body)
        is WhenPattern -> patternChildren()
        is LetCondition -> listOf(binding, value)
        is NameBinding -> listOfNotNull(name, type)
        is Destructuring -> parts
        is Let -> listOfNotNull(binding, value, otherwise)
        is LocalFunction -> listOf(name) + parameters + listOfNotNull(result, body)
        else -> declarationChildren()
    }

private fun WhenPattern.patternChildren(): List<FormulaNode> =
    when (this) {
        is WhenPattern.Is -> listOf(type) + bindings.orEmpty()
        is WhenPattern.In -> listOf(value)
        is WhenPattern.Value -> listOf(value)
        is WhenPattern.Else -> emptyList()
    }

private fun FormulaNode.declarationChildren(): List<FormulaNode> =
    when (this) {
        is ParameterNode -> listOf(name, type)
        is CaseNode -> listOf(name) + fields
        else -> error("No children known for $this")
    }
