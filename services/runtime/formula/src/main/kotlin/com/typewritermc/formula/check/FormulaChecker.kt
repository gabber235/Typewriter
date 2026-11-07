package com.typewritermc.formula.check

import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.parseExpression
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.FunctionTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

/**
 * What the checker asks the world. In the realm each answer is a tracked query, so what a formula read is recorded
 * with no extra work. The checker asks about one name at a time, so a formula depends on the names it uses, not on a
 * whole scope. A name with a stored reference goes through its id and never consults scope; only local names,
 * provider functions and catalog types stay text.
 */
interface FormulaEnvironment {
    fun resolve(use: TypeUse): Resolution<CheckedType>

    /** [use] with every alias replaced by the type it names, all through the use. A use with no alias comes back as is. */
    fun expand(use: TypeUse): TypeUse

    /** The resources [name] means at the innermost scope level that has it. Two or more is an ambiguity. */
    fun inScope(name: String): List<ResourceId>

    /** Every formula function called [name]: providers and core functions. */
    fun functions(name: String): List<FormulaFunction>

    /** What naming [target] gives, or null when it gives no type, which its own finding reports. */
    fun reference(target: ResourceId): TypeUse?

    /** Code types with this display name. A content type's name is a reference to its Definition instead. */
    fun catalogTypeNamed(name: String): List<TypeUse>

    /** The type a `Definition<Type>` resource holds, or null when it holds no plain type. */
    fun typeValue(target: ResourceId): TypeUse?

    /** Whether [id] is a content type that is gone. The checker treats it as its error type, with no finding of its own. */
    fun isMissing(id: TypeDefinitionId): Boolean
}

/** One problem the checker found, at [span] of the source. */
data class FormulaProblem(
    val span: TextSpan,
    val code: String,
    val message: String,
)

/** The context parameters a formula reads and the functions it calls. A formula reading no context is pure. */
data class FormulaReads(
    val context: Set<String>,
    val providers: Set<String>,
) {
    val isPure: Boolean get() = context.isEmpty()

    companion object {
        val None: FormulaReads = FormulaReads(emptySet(), emptySet())
    }
}

/** What a name means, in the order the language looks it up. */
sealed interface NameMeaning {
    /** A `let`, a local function, or a lambda or local function parameter. */
    data object Local : NameMeaning

    /** A context parameter or parameter of the function the formula is the body of. */
    data object Parameter : NameMeaning

    /** A resource, through a stored reference; never through text. */
    data class Resource(
        val id: ResourceId,
    ) : NameMeaning

    /** A stored reference a delete emptied. Silent here: the reference has its own finding. */
    data class Deleted(
        val text: String,
    ) : NameMeaning

    /** A case of the expected closed record, or of a `when` subject's. */
    data object Case : NameMeaning

    data object Provider : NameMeaning

    data object CatalogType : NameMeaning

    data object Unknown : NameMeaning
}

/**
 * What one name in the source means. [candidates] are the resources scope offers for a name with no stored target,
 * unbound or emptied, which binding reads; they stay empty for a name with a filled reference or a local meaning.
 */
data class NameAnswer(
    val span: TextSpan,
    val meaning: NameMeaning,
    val candidates: List<ResourceId>,
)

/** A checked formula: the tree the interpreter runs, its type, its problems, what it reads and what its names mean. */
data class CheckedFormula(
    val tree: CheckedExpression,
    /** Null when the formula has an error. */
    val type: TypeUse?,
    val problems: List<FormulaProblem>,
    val reads: FormulaReads,
    val names: List<NameAnswer>,
)

/**
 * Checks this formula as the body of [expected], the lowered type of the Var it sits in: the function's context and
 * parameters are in scope, and the body checks against its result.
 */
context(environment: FormulaEnvironment)
fun StoredFormula.check(expected: FunctionTypeUse): CheckedFormula =
    checkFormula(this, expected.context, expected.parameters, expected.result)

/**
 * Checks [formula] with [context] and [parameters] in scope against [result], or infers its type when [result] is
 * null. Never throws: what does not check becomes a problem at its span, and the rest keeps checking.
 */
context(environment: FormulaEnvironment)
fun checkFormula(
    formula: StoredFormula,
    context: List<FunctionParameterUse>,
    parameters: List<FunctionParameterUse>,
    result: TypeUse?,
): CheckedFormula {
    val parsed = parseExpression(formula.source)
    return Checker(environment, formula.references, context, parameters).run(parsed, result)
}
