package com.typewritermc.formula.check

import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.LetCondition
import com.typewritermc.formula.syntax.Literal
import com.typewritermc.formula.syntax.LiteralValue
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.NameBinding
import com.typewritermc.formula.syntax.WhenPattern
import skirout.editor.v1.type_catalog.TypeUse
import com.typewritermc.formula.syntax.When as WhenNode
import com.typewritermc.formula.syntax.WhenArm as WhenArmNode

// `when`: patterns, the bindings a case pattern makes, narrowing the subject inside an arm, and exhaustiveness
// against a closed record's cases. A guarded arm never counts toward exhaustiveness.

/** The local a `when` subject is held in when the source binds no name for it; no source text can name it. */
private const val SUBJECT = "\u0000subject"

/** A checked `when` subject: its value, the local the arms read it as, and the name an `is` arm narrows. */
private class Subject(
    val value: CheckedExpression?,
    val local: String?,
    val narrowed: String?,
    val scope: Scope,
)

/** What the arms so far cover, for exhaustiveness. */
private class Coverage {
    val types = mutableListOf<TypeUse>()
    var nullCovered = false
    var hasElse = false
}

internal fun Checker.whenExpression(
    node: WhenNode,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val subject = subject(node, scope)
    val coverage = Coverage()
    val arms = node.arms.map { arm(it, subject, expected, coverage) }
    if (!coverage.hasElse) exhaustive(node, subject.value?.type, coverage)
    val type =
        expected ?: arms.map { it.body.type }.reduceOrNull { a, b ->
            join(a, b) ?: ERROR.also { report(node.span, "formula_type_mismatch", "The arms give a ${shown(a)} and a ${shown(b)}") }
        } ?: ERROR
    return When(subject.value, subject.local, arms, type, node.span)
}

private fun Checker.subject(
    node: WhenNode,
    scope: Scope,
): Subject =
    when (val written = node.subject) {
        null -> {
            Subject(null, null, null, scope)
        }

        is LetCondition -> {
            val value = infer(written.value, null, scope)
            val name = (written.binding as? NameBinding)?.name?.text
            if (name == null) {
                report(written.binding.span, "formula_cannot_destructure", "A `when` subject binds one name")
                Subject(value, null, null, scope)
            } else {
                Subject(value, name, name, bind(written.binding, value.type, scope).second)
            }
        }

        is Expression -> {
            val value = synthOnce(written, scope)
            Subject(value, SUBJECT, (written as? Name)?.text, scope.with(Bound(SUBJECT, value.type, NameMeaning.Local)))
        }
    }

private fun Checker.arm(
    arm: WhenArmNode,
    subject: Subject,
    expected: TypeUse?,
    coverage: Coverage,
): WhenArm {
    var inner = subject.scope
    val unguarded = arm.guard == null
    val patterns =
        arm.patterns.map { pattern ->
            when (pattern) {
                is WhenPattern.Is -> {
                    val (checked, next) = isPattern(pattern, subject.value?.type, subject.narrowed.takeIf { arm.patterns.size == 1 }, inner)
                    inner = next
                    if (unguarded) coverage.types += checked.type
                    checked
                }

                is WhenPattern.In -> {
                    inPattern(pattern, subject, inner)
                }

                is WhenPattern.Value -> {
                    if (unguarded && (pattern.value as? Literal)?.value == LiteralValue.Null) coverage.nullCovered = true
                    valuePattern(pattern, subject, inner)
                }

                is WhenPattern.Else -> {
                    coverage.hasElse = true
                    CheckedPattern.Else
                }
            }
        }
    val guard = arm.guard?.let { condition(it, inner) }
    val body = infer(arm.body, expected, inner)
    if (expected != null) expect(body, expected)
    return WhenArm(patterns, guard, body)
}

/** `is Type` or `is Case(a, b)`: the case's fields bind in order, and a named subject reads as that type in its arm. */
private fun Checker.isPattern(
    pattern: WhenPattern.Is,
    subject: TypeUse?,
    narrowed: String?,
    scope: Scope,
): Pair<CheckedPattern.Is, Scope> {
    if (subject == null) {
        report(pattern.span, "formula_when_needs_subject", "`is` needs a `when` with a subject")
        return CheckedPattern.Is(ERROR, emptyList(), null) to scope
    }
    val tested = lower(pattern.type, scope, subject)
    val base = subject.nonNull()
    if (!comparable(tested, base)) {
        report(pattern.type.span, "formula_pattern_never_matches", "A ${shown(subject)} is never a ${shown(tested)}")
    }
    val narrowedScope = if (narrowed != null && tested != ERROR) scope.narrowing(narrowed, tested) else scope
    val (bindings, inner) = caseBindings(pattern, tested, narrowedScope)
    return CheckedPattern.Is(tested, bindings, narrowed) to inner
}

/** The names `is Case(a, b)` binds: the case's fields, in declared order. */
private fun Checker.caseBindings(
    pattern: WhenPattern.Is,
    tested: TypeUse,
    scope: Scope,
): Pair<List<Pair<String, CheckedBinding>>, Scope> {
    val written = pattern.bindings.orEmpty()
    val fields = if (tested == ERROR) null else schema(tested)?.fields.orEmpty()
    if (fields != null && written.size > fields.size) {
        report(pattern.span, "formula_cannot_destructure", "${shown(tested)} has ${fields.size} field${if (fields.size == 1) "" else "s"}")
    }
    var inner = scope
    val bindings =
        written.mapIndexed { index, binding ->
            val field = fields?.getOrNull(index)
            val (checked, next) = bind(binding, field?.let { normalize(readType(it.type)) } ?: ERROR, inner)
            inner = next
            (field?.key ?: "") to checked
        }
    return bindings to inner
}

private fun Checker.inPattern(
    pattern: WhenPattern.In,
    subject: Subject,
    scope: Scope,
): CheckedPattern {
    val value = subject.value
    val local = subject.local
    if (value == null || local == null) {
        report(pattern.span, "formula_when_needs_subject", "`in` needs a `when` with a subject")
        return CheckedPattern.Test(Invalid(ERROR, pattern.span))
    }
    val element = CallArgument.Given(LocalRead(local, value.type, pattern.span))
    return CheckedPattern.Test(
        callNamed("contains", synthOnce(pattern.value, scope), listOf(element), BOOLEAN, pattern.span, scope, operator = "in"),
    )
}

private fun Checker.valuePattern(
    pattern: WhenPattern.Value,
    subject: Subject,
    scope: Scope,
): CheckedPattern {
    val subjectValue = subject.value
    val local = subject.local
    if (subjectValue == null || local == null) return CheckedPattern.Test(condition(pattern.value, scope))
    val value = infer(pattern.value, subjectValue.type.takeUnless { it == ERROR }?.orNull(), scope)
    if (!comparable(subjectValue.type, value.type)) {
        report(pattern.span, "formula_type_mismatch", "A ${shown(subjectValue.type)} is never equal to a ${shown(value.type)}")
    }
    return CheckedPattern.Test(Equals(LocalRead(local, subjectValue.type, pattern.span), value, false, BOOLEAN, pattern.span))
}

/** Without `else`, every case of a closed subject needs an unguarded arm; any other subject needs `else`. */
private fun Checker.exhaustive(
    node: WhenNode,
    subject: TypeUse?,
    coverage: Coverage,
) {
    if (subject == ERROR) return
    if (subject == null) {
        report(node.span, "formula_when_needs_else", "This `when` needs an `else`, since the formula needs a value either way")
        return
    }

    fun covered(type: TypeUse): Boolean =
        coverage.types.any { fits(type, it) } || closedCasesOf(type)?.let { it.isNotEmpty() && it.all(::covered) } == true
    val base = subject.nonNull()
    val cases = closedCasesOf(base)
    if (cases == null && !covered(base)) {
        report(node.span, "formula_when_needs_else", "A ${shown(base)} can be more than these arms name, so this `when` needs an `else`")
        return
    }
    val missingCases = if (covered(base)) emptyList() else cases.orEmpty().filterNot(::covered).map(::shown)
    val missing = missingCases + listOfNotNull("null".takeIf { subject.isNullable && !coverage.nullCovered })
    if (missing.isNotEmpty()) {
        report(node.span, "formula_when_not_exhaustive", "This `when` does not handle ${missing.joinToString(", ")}")
    }
}
