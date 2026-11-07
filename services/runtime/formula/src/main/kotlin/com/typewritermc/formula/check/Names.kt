package com.typewritermc.formula.check

import com.typewritermc.formula.FormulaFunction
import com.typewritermc.formula.syntax.Name
import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.TypeUse

// Lookup order: lambda and block levels, the function's own context and parameters, then names the source stores
// references for, cases of the expected union, provider functions, and catalog types.

/** One value a scope level binds. A local function still being checked without a result type has a null [type]. */
internal data class Bound(
    val name: String,
    val type: TypeUse?,
    val meaning: NameMeaning,
    val isContext: Boolean = false,
)

/** A level of names. Levels never change, so a `let` opens a new level and a later `let` of the same name shadows it. */
internal class Scope private constructor(
    private val parent: Scope?,
    private val bound: Map<String, Bound>,
    private val narrowed: Map<String, TypeUse>,
) {
    fun with(vararg values: Bound): Scope = Scope(this, values.associateBy(Bound::name), emptyMap())

    fun with(values: List<Bound>): Scope = Scope(this, values.associateBy(Bound::name), emptyMap())

    /** A level where [name] is known to hold a [type], as inside an `is` arm. */
    fun narrowing(
        name: String,
        type: TypeUse,
    ): Scope = Scope(this, emptyMap(), mapOf(name to type))

    /** The innermost binding of [name], at its narrowed type when a narrowing is nearer than the binding. */
    fun find(name: String): Found {
        var narrowedType: TypeUse? = null
        var level: Scope? = this
        while (level != null) {
            if (narrowedType == null) narrowedType = level.narrowed[name]
            level.bound[name]?.let { return Found(it, narrowedType) }
            level = level.parent
        }
        return Found(null, narrowedType)
    }

    /** Each level's bindings whose type [accepts], innermost level first, skipping levels with none. */
    fun levelsMatching(accepts: (TypeUse) -> Boolean): List<List<Bound>> {
        val levels = mutableListOf<List<Bound>>()
        val hidden = mutableSetOf<String>()
        var level: Scope? = this
        while (level != null) {
            val matching = level.bound.values.filter { it.name !in hidden && it.type != null && accepts(it.type) }
            if (matching.isNotEmpty()) levels += matching
            hidden += level.bound.keys
            level = level.parent
        }
        return levels
    }

    data class Found(
        val bound: Bound?,
        val narrowed: TypeUse?,
    )

    companion object {
        fun root(
            context: List<FunctionParameterUse>,
            parameters: List<FunctionParameterUse>,
        ): Scope {
            val contextLevel = context.map { Bound(it.name, it.type, NameMeaning.Parameter, isContext = true) }
            val parameterLevel = parameters.map { Bound(it.name, it.type, NameMeaning.Parameter) }
            return Scope(null, contextLevel.associateBy(Bound::name), emptyMap()).with(parameterLevel)
        }
    }
}

/** What a name in an expression position turned out to be. */
internal sealed interface Named {
    /** A value: a local, a parameter or a resource, with the node that reads it. */
    data class Value(
        val node: CheckedExpression,
    ) : Named

    data class Case(
        val type: TypeUse,
    ) : Named

    data class Functions(
        val functions: List<FormulaFunction>,
    ) : Named

    /** A type: a catalog type, or a `Definition<Type>` resource holding one. */
    data class Type(
        val type: TypeUse,
    ) : Named

    /** Nothing to check further: an unknown name, an emptied reference, or a type that is no plain type. */
    data object Nothing : Named
}

/** Looks [name] up for an expression position. [expected] offers its union's cases. */
internal fun Checker.lookup(
    name: Name,
    expected: TypeUse?,
    scope: Scope,
): Named {
    val found = scope.find(name.text)
    found.bound?.let { bound -> return local(name, bound, found.narrowed) }
    referenceAt[name.span]?.let { stored -> return stored.target?.let { resource(name, it, found.narrowed) } ?: emptied(name) }
    val candidates = environment.inScope(name.text)
    caseNamed(name.text, expected)?.let { case ->
        answer(name, NameMeaning.Case, candidates)
        return Named.Case(case)
    }
    val functions = environment.functions(name.text)
    if (functions.isNotEmpty()) {
        answer(name, NameMeaning.Provider, candidates)
        return Named.Functions(functions)
    }
    builtinType(name.text)?.let { type ->
        answer(name, NameMeaning.CatalogType, candidates)
        return Named.Type(type)
    }
    val types = environment.catalogTypeNamed(name.text)
    if (types.isNotEmpty()) {
        answer(name, NameMeaning.CatalogType, candidates)
        if (types.size > 1) {
            report(name.span, "formula_ambiguous_type", "Several types are named `${name.text}`; qualify it by its extension")
            return Named.Nothing
        }
        return Named.Type(types.single())
    }
    answer(name, NameMeaning.Unknown, candidates)
    unknown(name, candidates)
    return Named.Nothing
}

private fun Checker.local(
    name: Name,
    bound: Bound,
    narrowed: TypeUse?,
): Named {
    answer(name, bound.meaning, emptyList())
    if (bound.isContext) trace.context += bound.name
    val type = bound.type
    if (type == null) {
        report(
            name.span,
            "formula_recursive_needs_result",
            "`${name.text}` calls itself, so it needs its result type, as in `let ${name.text}(...): Int = ...`",
        )
        return Named.Nothing
    }
    return Named.Value(LocalRead(bound.name, narrowed ?: type, name.span))
}

private fun Checker.resource(
    name: Name,
    target: ResourceId,
    narrowed: TypeUse?,
): Named {
    answer(name, NameMeaning.Resource(target), emptyList())
    // A target that gives no type has its own finding, as a missing type does.
    val naming = environment.reference(target)?.let(::normalize) ?: return Named.Nothing
    if (naming == TYPE_VALUE) {
        val held = environment.typeValue(target)?.let(::normalize)
        if (held == null) {
            report(name.span, "formula_type_not_plain", "`${name.text}` holds a formula, not a plain type, so it cannot be used as a type")
            return Named.Nothing
        }
        return Named.Type(held)
    }
    return Named.Value(ResourceRead(target, narrowed ?: naming, name.span))
}

/**
 * A name whose stored reference a delete emptied: silent, since the reference has its own finding, and offering what
 * scope has for its text, so a commit can bind it again.
 */
internal fun Checker.emptied(name: Name): Named {
    answer(name, NameMeaning.Deleted(name.text), environment.inScope(name.text))
    return Named.Nothing
}

internal fun Checker.unknown(
    name: Name,
    candidates: List<ResourceId>,
) {
    if (candidates.size > 1) {
        report(name.span, "formula_ambiguous_name", "Several things are named `${name.text}` here; qualify which one")
    } else {
        report(name.span, "formula_unknown_name", "`${name.text}` is unknown")
    }
}

internal fun Checker.answer(
    name: Name,
    meaning: NameMeaning,
    candidates: List<ResourceId>,
) {
    trace.names += NameAnswer(name.span, meaning, candidates)
}
