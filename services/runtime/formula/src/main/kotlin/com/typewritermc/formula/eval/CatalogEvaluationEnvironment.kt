package com.typewritermc.formula.eval

import com.typewritermc.expression.operations.portableScalarText
import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.Deferred
import com.typewritermc.formula.FormulaFailure
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.check.shown
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.Type
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.contentOwner
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.isUnit
import com.typewritermc.types.memberName
import com.typewritermc.types.toResourceId
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigDecimal

/**
 * The part of evaluation every world shares: values over one checked [catalog] and its native [bindings]. A world adds
 * what only it knows: the value a [Deferred] stands for, the fields and exports of resources, and the names creators
 * read.
 */
abstract class CatalogEvaluationEnvironment(
    protected val catalog: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
) : EvaluationEnvironment {
    /** The value [value] stands for, evaluated now. Throws [FailedEvaluation] when it cannot be had. */
    abstract fun evaluateDeferred(value: Deferred): Any?

    /** The name creators read for the type [id], or null when the world has none for it. */
    abstract fun typeName(id: TypeDefinitionId): String?

    /** The name creators read for the resource [id]. */
    abstract fun resourceName(id: ResourceId): String

    override fun ensureCurrent() = Unit

    final override fun resolve(value: Any?): Any? = if (value is Deferred) evaluateDeferred(value) else value

    final override fun force(value: Any?): Any? =
        when (val resolved = resolve(value)) {
            is RecordValue -> resolved.copy(fields = resolved.fields.mapValues { (_, field) -> force(field) })
            is NamedValue -> resolved.copy(value = force(resolved.value))
            is List<*> -> resolved.map(::force)
            is Set<*> -> resolved.mapTo(LinkedHashSet(), ::force)
            is Map<*, *> -> resolved.entries.associateTo(LinkedHashMap()) { (key, item) -> force(key) to force(item) }
            else -> resolved
        }

    final override fun fail(message: String): Nothing = throw FailedEvaluation(FormulaFailure.ProviderThrew(message))

    override fun binding(type: TypeUse): NativeBinding<*> = bindings.bind(checked(type))

    override fun construct(
        type: TypeUse,
        fields: Map<String, Any?>,
    ): Any? {
        val expanded = catalog.expand(type)
        val checked = checked(expanded)
        return when {
            checked.schema.representation.isUnit -> NamedValue(expanded, Unit)
            expanded.definition?.contentOwner() != null -> RecordValue(expanded, fields)
            else -> bindings.construct(checked, fields, this)
        }
    }

    override fun isA(
        value: Any?,
        type: TypeUse,
    ): Boolean {
        val resolved = resolve(value) ?: return type is TypeUse.NullableWrapper
        val tested = (type as? TypeUse.NullableWrapper)?.value?.value ?: type
        if (tested is TypeUse.FunctionWrapper) return resolved is FunctionValue
        if (tested is TypeUse.ScalarWrapper) return scalarKindOf(resolved) == tested.value
        val expected = catalog.expand(tested).definition ?: return false
        val actual = definitionOf(resolved) ?: return false
        return catalog.isNominalSubtype(actual, expected)
    }

    /** The named definition [value] is a value of, or null for a scalar or a function. */
    private fun definitionOf(value: Any): TypeDefinitionId? =
        when (value) {
            is RecordValue -> catalog.expand(value.type).definition
            is NamedValue -> catalog.expand(value.type).definition
            is List<*> -> StandardTypes.list
            is Set<*> -> StandardTypes.set
            is Map<*, *> -> StandardTypes.map
            is Ref<*, *> -> ContentReferences.Source.Definition.id
            else -> null
        }

    override fun display(value: Any?): String =
        when (val forced = force(value)) {
            is RecordValue -> {
                "${typeText(forced.type)}(${forced.fields.entries.joinToString { (name, field) -> "$name = ${display(field)}" }})"
            }

            is NamedValue -> {
                if (forced.value == Unit) caseText(forced.type) else "${typeText(forced.type)}(${display(forced.value)})"
            }

            is Collection<*> -> {
                forced.joinToString(prefix = "[", postfix = "]") { display(it) }
            }

            is Map<*, *> -> {
                if (forced.isEmpty()) {
                    "[:]"
                } else {
                    forced.entries.joinToString(
                        prefix = "[",
                        postfix = "]",
                    ) { (key, item) -> "${display(key)}: ${display(item)}" }
                }
            }

            is Ref<*, *> -> {
                resourceName(forced.target)
            }

            is Type -> {
                shown(forced.use)
            }

            is FunctionValue -> {
                shown(forced.tree.type)
            }

            else -> {
                portableScalarText(forced)
            }
        }

    /** [use] resolved in this catalog. The checker resolved every type a checked formula names, so a failure here is a bug. */
    protected fun checked(use: TypeUse): CheckedType =
        when (val resolved = catalog.resolve(use)) {
            is Resolution.Ready -> resolved.value
            is Resolution.Invalid -> error("A checked formula names a type that does not resolve: ${resolved.diagnostics}")
        }

    private fun caseText(type: TypeUse): String = type.definition?.memberName ?: typeText(type)

    private fun typeText(type: TypeUse): String {
        val id = type.definition ?: return shown(type)
        return typeName(id)
            ?: id.contentOwner()?.let { resourceName(it.toResourceId()) }
            ?: id.memberName
            ?: (id.typeId as? TypeId.QualifiedWrapper)?.value?.name?.substringAfterLast('.')
            ?: shown(type)
    }

    private val TypeUse.definition: TypeDefinitionId? get() = (this as? TypeUse.NamedWrapper)?.value?.definition
}

/** The scalar kind of a Kotlin evaluation value, or null when it is not a scalar. */
private fun scalarKindOf(value: Any): ScalarKind? =
    when (value) {
        is Boolean -> ScalarKind.BOOLEAN
        is String -> ScalarKind.TEXT
        is Unit -> ScalarKind.UNIT
        is BigDecimal -> ScalarKind.DECIMAL
        is Int -> integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
        is Long -> integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR)
        is Float -> floatScalar(FloatWidth.THIRTY_TWO)
        is Double -> floatScalar(FloatWidth.SIXTY_FOUR)
        is kotlin.time.Instant -> ScalarKind.TIMESTAMP
        is kotlin.time.Duration -> ScalarKind.DURATION
        else -> null
    }
