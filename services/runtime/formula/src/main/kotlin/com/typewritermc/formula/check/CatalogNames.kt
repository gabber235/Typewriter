package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.Member
import com.typewritermc.formula.syntax.Name
import skirout.editor.v1.type_catalog.TypeUse

// Code types by source name. Two types with one name are told apart by the extension that declares each, written
// before the name: `conformanceBase.Npc`, or the full `typewritermc.conformanceBase.Npc`. A qualifier names the
// extensions whose qualified form ends with it; the full form is the extension's identity and never clashes.

/**
 * An extension as a formula qualifies it: each part of its artifact id in camel case, so `typewritermc:conformance-base`
 * is `typewritermc.conformanceBase`. Two artifact ids with one qualified form, such as `a:foo-bar` and `a:fooBar`, are
 * one extension to formulas, so their types of one name cannot be told apart.
 */
data class ExtensionName(
    val parts: List<String>,
) {
    /** Whether [qualifier], the parts written before a type name, names this extension: its last parts, or all of them. */
    fun answers(qualifier: List<String>): Boolean = qualifier.isNotEmpty() && parts.takeLast(qualifier.size) == qualifier

    override fun toString(): String = parts.joinToString(".")

    companion object {
        /** The qualified form of the extension with this artifact id. */
        fun of(artifactId: String): ExtensionName = ExtensionName(artifactId.split(':').map(::camelCase))

        /** `conformance-base` as `conformanceBase`: `-`, `_` and `.` break words. */
        private fun camelCase(part: String): String =
            part
                .split('-', '_', '.')
                .filter(String::isNotEmpty)
                .mapIndexed { index, word ->
                    if (index == 0) word.replaceFirstChar(Char::lowercaseChar) else word.replaceFirstChar(Char::uppercaseChar)
                }.joinToString("")
    }
}

/** A code type a formula names by its source name, with the extension that declares it. */
data class CatalogType(
    val type: TypeUse,
    val extension: ExtensionName,
)

/**
 * The code type [name] names after [qualifier], the parts written before it. Reports at [span] and gives the error type
 * when it names several, or when the qualifier names no extension, several extensions, or one without that type. Null
 * for a plain name no code type has, which each caller reports in its own way.
 */
internal fun Checker.catalogType(
    qualifier: List<String>,
    name: String,
    span: TextSpan,
): TypeUse? {
    val types = environment.catalogTypeNamed(name)
    if (qualifier.isEmpty()) {
        return when (types.size) {
            0 -> null
            1 -> types.single().type
            else -> ambiguousType(name, types.map { it.extension }, span)
        }
    }
    val written = qualifier.joinToString(".")
    val extensions = environment.extensions().filter { it.answers(qualifier) }
    if (extensions.isEmpty()) {
        report(span, "formula_unknown_extension", "There is no extension `$written`")
        return ERROR
    }
    if (extensions.size > 1) {
        val forms = extensions.map { "`$it.$name`" }.sorted()
        report(span, "formula_ambiguous_extension", "Several extensions are called `$written`; write ${forms.joinToString(" or ")}")
        return ERROR
    }
    val extension = extensions.single()
    val declared = types.filter { it.extension == extension }
    return when (declared.size) {
        0 -> {
            report(span, "formula_unknown_type", "There is no type `$name` in `$written`")
            ERROR
        }

        1 -> {
            declared.single().type
        }

        else -> {
            ambiguousType(name, declared.map { it.extension }, span)
        }
    }
}

/** Reports that several code types share [name], listing each by the shortest qualifier that names its extension alone. */
private fun Checker.ambiguousType(
    name: String,
    declaring: List<ExtensionName>,
    span: TextSpan,
): TypeUse {
    val every = environment.extensions()
    val forms = declaring.map { extension -> "${shortest(extension, every)}.$name" }.sorted()
    report(span, "formula_ambiguous_type", "Several types are named `$name` (${forms.joinToString()})")
    return ERROR
}

/** The fewest last parts of [extension] that no other of [every] ends with, or all of them. */
private fun shortest(
    extension: ExtensionName,
    every: Set<ExtensionName>,
): String {
    val size =
        (1..extension.parts.size).firstOrNull { size ->
            val qualifier = extension.parts.takeLast(size)
            every.count { it.answers(qualifier) } == 1
        } ?: extension.parts.size
    return extension.parts.takeLast(size).joinToString(".")
}

/**
 * `citizens.Npc` as an expression: [member] read as a code type qualified by its extension. Null when it is a plain
 * member read: its chain does not start at a name, or the first name means something in scope (a local, a parameter or
 * a stored reference, which a resource of that name in scope becomes at commit), or neither an extension nor a code
 * type answers the written parts. A resource of that name in scope is offered for binding, so scope hides the qualifier.
 */
internal fun Checker.qualifiedType(
    member: Member,
    scope: Scope,
): TypeUse? {
    val names = chain(member) ?: return null
    val root = names.first()
    if (scope.find(root.text).bound != null || root.span in referenceAt) return null
    val qualifier = names.dropLast(1).map { it.text }
    val name = names.last().text
    if (environment.extensions().none { it.answers(qualifier) } && environment.catalogTypeNamed(name).isEmpty()) return null
    answer(root, NameMeaning.CatalogType, environment.inScope(root.text))
    return catalogType(qualifier, name, member.span)
}

/** The names of `a.b.c`, or null when [expression] is anything else, such as a call or a `?.` read. */
private fun chain(expression: Expression): List<Name>? =
    when (expression) {
        is Name -> listOf(expression)
        is Member -> if (expression.safe) null else chain(expression.target)?.plus(expression.name)
        else -> null
    }

/** `citizens.Npc` as a value: the type it names, an error once reported, or null for a plain member read. */
internal fun Checker.qualifiedTypeValue(
    member: Member,
    scope: Scope,
): CheckedExpression? {
    val type = qualifiedType(member, scope) ?: return null
    return if (type == ERROR) Invalid(ERROR, member.span) else Constant(type, TYPE_VALUE, member.span)
}
