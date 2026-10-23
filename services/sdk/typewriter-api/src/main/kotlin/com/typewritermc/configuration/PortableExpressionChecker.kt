package com.typewritermc.configuration

import com.typewritermc.authoring.arguments
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.name
import com.typewritermc.authoring.type
import com.typewritermc.authoring.use
import com.typewritermc.expression.CanonicalReadModels
import com.typewritermc.expression.PortableExpressionLimits
import com.typewritermc.expression.children
import com.typewritermc.expression.descendants
import com.typewritermc.expression.entryExpressionType
import com.typewritermc.expression.listExpressionType
import com.typewritermc.expression.mapExpressionType
import com.typewritermc.expression.nominalExpressionType
import com.typewritermc.expression.nominalUseOrNull
import com.typewritermc.expression.operations.CheckFailure
import com.typewritermc.expression.operations.OperationProfile
import com.typewritermc.expression.operations.ParameterKind
import com.typewritermc.expression.operations.PortableOperation
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.operations.Signature
import com.typewritermc.expression.operations.TypeBound
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.isValid
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.portableOrNull
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import com.typewritermc.types.validOrNull
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.expression.CallExpression
import skirout.editor.v1.expression.ExpressionMappingType
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.ExpressionValueType
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import java.util.Collections
import java.util.IdentityHashMap

/** The inferred result type of an expression, or the check failures that leave it untyped. */
sealed interface ExpressionInference {
    data class Typed(
        val type: ExpressionType,
    ) : ExpressionInference

    data class Failed(
        val failures: List<FailureId>,
    ) : ExpressionInference
}

/** A checked expression retains the shared syntax and its declared result contract. */
data class CheckedExpression(
    val body: ExpressionNode,
    val result: ExpressionType,
)

/**
 * Checks the closed shared expression language with lexical frames scoped to one invocation.
 *
 * Structural forms have their own rules; every call is typed by one generic rule over the declared signature of its
 * operation in [PortableOperationCatalog]. Failures are the declared [CheckFailure] identities.
 */
class PortableExpressionChecker(
    resolveType: (TypeUse) -> Resolution<CheckedType>,
    private val owner: TypeDefinitionId? = null,
    private val resolvePartial: ((TypeSelection) -> Resolution<PartialSchema>)? = null,
) {
    private val resolveType: (TypeUse) -> Resolution<CheckedType> = { use ->
        if (CanonicalReadModels.supports(use)) CanonicalReadModels.catalog.resolve(use) else resolveType(use)
    }

    /** Checks [body] against [expectedOutput]; failures become diagnostics of [affected]. */
    fun checkExpression(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
        expectedOutput: ExpressionType,
        affected: TypeDefinitionId,
        partialBindings: Map<ExpressionBindingId, TypeSelection> = emptyMap(),
    ): Resolution<CheckedExpression> {
        val failures = checkExpressionCodes(body, bindings, expectedOutput, partialBindings)
        return if (failures.isEmpty()) {
            Resolution.Ready(CheckedExpression(body, expectedOutput))
        } else {
            Resolution.Invalid(failures.map { DeclarationDiagnostic.of(affected, it.value) })
        }
    }

    /** The first failure of checking [body] against [expectedOutput], or nothing when it is well typed. */
    fun checkExpressionCodes(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
        expectedOutput: ExpressionType,
        partialBindings: Map<ExpressionBindingId, TypeSelection> = emptyMap(),
        onInferred: ((ExpressionType) -> Unit)? = null,
    ): List<FailureId> = Invocation(bindings, partialBindings).check(body, expectedOutput, onInferred)

    /** The result type of [body] over [bindings], for a result of any type such as a sort key or a repeated source. */
    fun inferExpression(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
    ): ExpressionInference = Invocation(bindings, emptyMap()).inferOnly(body)

    /** Checks only the syntax of [body]: bindings, local addresses, paths, operations, arities and lambda placement. */
    fun checkExpressionStructure(
        body: ExpressionNode,
        bindings: Set<ExpressionBindingId>,
    ): List<FailureId> =
        try {
            validateStructure(body, bindings)
            emptyList()
        } catch (failure: ExpressionCheckFailure) {
            listOf(failure.failure)
        }

    internal fun checkRule(
        body: ExpressionNode,
        subject: CheckedType,
    ): List<DeclarationDiagnostic> =
        (
            body.ruleProfileViolations() +
                checkExpressionCodes(
                    body,
                    mapOf(RULE_SUBJECT to nominalExpressionType(subject.use)),
                    nominalExpressionType(ScalarKind.BOOLEAN.use, true),
                )
        ).distinct().map { DeclarationDiagnostic.of(requireNotNull(owner), it.value) }

    internal fun checkRuleStructure(body: ExpressionNode): List<DeclarationDiagnostic> =
        checkExpressionStructure(body, setOf(RULE_SUBJECT)).map { DeclarationDiagnostic.of(requireNotNull(owner), it.value) }

    private fun validateStructure(
        root: ExpressionNode,
        bindings: Set<ExpressionBindingId>,
    ) {
        fun visit(
            node: ExpressionNode,
            arities: List<Int>,
            depth: Int,
            argument: Boolean,
        ) {
            demand(depth <= PortableExpressionLimits.MAX_DEPTH, CheckFailure.ExpressionDepthLimit)
            when (node) {
                is ExpressionNode.Unknown -> {
                    fail(CheckFailure.UnknownExpression)
                }

                is ExpressionNode.InputWrapper -> {
                    demand(ExpressionBindingId(value = node.value.binding.value) in bindings, CheckFailure.UnknownExpressionBinding)
                    decodePath(node.value.path)
                }

                is ExpressionNode.LocalWrapper -> {
                    demand(
                        node.value.depth >= 0 && node.value.slot >= 0 &&
                            arities.asReversed().getOrNull(node.value.depth)?.let { node.value.slot < it } == true,
                        CheckFailure.InvalidExpressionLocal,
                    )
                    decodePath(node.value.path)
                }

                is ExpressionNode.FieldWrapper -> {
                    decodePath(node.value.path)
                }

                is ExpressionNode.LambdaWrapper -> {
                    demand(argument, CheckFailure.InvalidLambda)
                }

                is ExpressionNode.CallWrapper -> {
                    validateCall(node.value)
                }

                else -> {
                    Unit
                }
            }
            node.children().forEach { child ->
                visit(
                    child.node,
                    if (child.frameArity == 0) arities else arities + child.frameArity,
                    depth + 1,
                    node is ExpressionNode.CallWrapper,
                )
            }
        }
        visit(root, emptyList(), 1, false)
    }

    /** The shape every call needs before typing: a declared operation, its arity, type argument count and lambdas. */
    private fun validateCall(call: CallExpression): PortableOperation {
        val declaration = PortableOperationCatalog.declaration(call.operation) ?: fail(CheckFailure.UnknownOperation)
        demand(declaration.accepts(call.arguments.size), CheckFailure.InvalidArgumentCount)
        demand(call.typeArguments.size == declaration.explicitTypeParameters.size, CheckFailure.InvalidTypeArgument)
        call.arguments.forEachIndexed { index, argument ->
            val arity = requireNotNull(declaration.parameterAt(index)).kind.lambdaArity
            val lambda = (argument as? ExpressionNode.LambdaWrapper)?.value
            demand(if (arity == null) lambda == null else lambda?.arity == arity, CheckFailure.InvalidLambda)
        }
        return declaration
    }

    private fun decodePath(path: ValuePath): ValuePath = path.validOrNull() ?: fail(CheckFailure.InvalidExpressionPath)

    private inner class Invocation(
        bindings: Map<ExpressionBindingId, ExpressionType>,
        partialBindings: Map<ExpressionBindingId, TypeSelection>,
    ) {
        private val partialBindings = partialBindings.toMap()
        private val bindings = bindings.toMap()

        /** Numeric literal types by identity; they adopt the width of a non literal operand of their family. */
        private val literalTypes = Collections.newSetFromMap(IdentityHashMap<ExpressionType, Boolean>())

        fun inferOnly(body: ExpressionNode): ExpressionInference =
            try {
                validateStructure(body, bindings.keys + partialBindings.keys)
                ExpressionInference.Typed(infer(body))
            } catch (failure: ExpressionCheckFailure) {
                ExpressionInference.Failed(listOf(failure.failure))
            }

        fun check(
            body: ExpressionNode,
            expected: ExpressionType,
            onInferred: ((ExpressionType) -> Unit)? = null,
        ): List<FailureId> =
            try {
                validateStructure(body, bindings.keys + partialBindings.keys)
                validateType(expected)
                val result = contextualEmpty(body, expected) ?: infer(body)
                onInferred?.invoke(result)
                demand(compatible(result, expected), CheckFailure.IncompatibleExpressionResultType)
                demand(!result.mayBeMissing || expected.mayBeMissing, CheckFailure.ExpressionResultMayBeMissing)
                emptyList()
            } catch (failure: ExpressionCheckFailure) {
                listOf(failure.failure)
            }

        private fun validateType(
            type: ExpressionType,
            depth: Int = 1,
        ) {
            demand(depth <= PortableExpressionLimits.MAX_DEPTH, CheckFailure.ExpressionDepthLimit)
            when (val shape = type.value) {
                is ExpressionValueType.NominalWrapper -> {
                    ready(type.nominalUseOrNull() ?: fail(CheckFailure.InvalidExpressionType))
                }

                is ExpressionValueType.ListWrapper -> {
                    validateType(shape.value, depth + 1)
                }

                is ExpressionValueType.MapWrapper -> {
                    validateType(shape.value.key, depth + 1)
                    validateType(shape.value.value, depth + 1)
                }

                is ExpressionValueType.EntryWrapper -> {
                    validateType(shape.value.key, depth + 1)
                    validateType(shape.value.value, depth + 1)
                }

                is ExpressionValueType.NullableWrapper -> {
                    validateType(shape.value, depth + 1)
                }

                ExpressionValueType.NULL_VALUE -> {
                    Unit
                }

                else -> {
                    fail(CheckFailure.InvalidExpressionType)
                }
            }
        }

        private fun withMissing(
            type: ExpressionType,
            missing: Boolean,
        ): ExpressionType {
            if (type.mayBeMissing == missing) return type
            return type.copy(mayBeMissing = missing).also { if (type in literalTypes) literalTypes += it }
        }

        private fun scalar(
            kind: ScalarKind,
            missing: Boolean = false,
        ) = nominalExpressionType(kind.use, missing)

        private fun boolean(missing: Boolean = false) = scalar(ScalarKind.BOOLEAN, missing)

        private fun text(missing: Boolean = false) = scalar(ScalarKind.TEXT, missing)

        /** Whether [actual] is a proper nominal subtype of [expected], such as an Iconify icon where an icon is expected. */
        private fun isNominalSubtype(
            actual: TypeUse?,
            expected: TypeUse?,
        ): Boolean {
            if (actual !is TypeUse.NamedWrapper || expected !is TypeUse.NamedWrapper || actual == expected) return false
            val resolved = resolveType(actual) as? Resolution.Ready ?: return false
            return expected.value in resolved.value.schema.ancestors
        }

        private fun ready(use: TypeUse): CheckedType =
            when (val result = resolveType(use)) {
                is Resolution.Ready -> result.value
                is Resolution.Invalid -> fail(CheckFailure.InvalidExpressionType)
            }

        private fun canonical(type: ExpressionType): ExpressionType {
            val use = type.nominalUseOrNull() ?: return type
            return when {
                use is TypeUse.NullableWrapper -> {
                    ExpressionType(
                        value = ExpressionValueType.NullableWrapper(nominalExpressionType(use.value.value)),
                        mayBeMissing = type.mayBeMissing,
                    )
                }

                use is TypeUse.NamedWrapper && use.value.definition == StandardTypes.list && use.value.arguments.size == 1 -> {
                    listExpressionType(nominalExpressionType(use.value.arguments.single()), type.mayBeMissing)
                }

                use is TypeUse.NamedWrapper && use.value.definition == StandardTypes.map && use.value.arguments.size == 2 -> {
                    mapExpressionType(
                        nominalExpressionType(use.value.arguments[0]),
                        nominalExpressionType(use.value.arguments[1]),
                        type.mayBeMissing,
                    )
                }

                else -> {
                    type
                }
            }
        }

        private fun scalarKind(type: ExpressionType): ScalarKind? {
            val use = type.nominalUseOrNull() ?: return null
            if (use is TypeUse.NullableWrapper) return null
            return (ready(use).schema.representation as? ResolvedRepresentation.ScalarWrapper)?.value?.kind
        }

        private fun numericFamily(type: ExpressionType): NumericFamily? =
            when (scalarKind(type)) {
                is ScalarKind.IntegerWrapper -> NumericFamily.INTEGER
                is ScalarKind.FloatWrapper -> NumericFamily.FLOAT
                ScalarKind.DECIMAL -> NumericFamily.DECIMAL
                else -> null
            }

        private fun compatible(
            actual: ExpressionType,
            expected: ExpressionType,
        ): Boolean {
            val a = canonical(actual)
            val e = canonical(expected)
            val av = a.value
            val ev = e.value
            if (av == ExpressionValueType.NULL_VALUE) {
                return ev == ExpressionValueType.NULL_VALUE || ev is ExpressionValueType.NullableWrapper
            }
            if (ev is ExpressionValueType.NullableWrapper) {
                return compatible(
                    if (av is ExpressionValueType.NullableWrapper) av.value else a,
                    ev.value,
                )
            }
            if (av is ExpressionValueType.NullableWrapper) return false
            return when {
                av is ExpressionValueType.ListWrapper && ev is ExpressionValueType.ListWrapper -> {
                    compatible(av.value, ev.value)
                }

                av is ExpressionValueType.MapWrapper && ev is ExpressionValueType.MapWrapper -> {
                    compatible(av.value.key, ev.value.key) && compatible(av.value.value, ev.value.value)
                }

                av is ExpressionValueType.EntryWrapper && ev is ExpressionValueType.EntryWrapper -> {
                    compatible(av.value.key, ev.value.key) && compatible(av.value.value, ev.value.value)
                }

                av is ExpressionValueType.NominalWrapper && ev is ExpressionValueType.NominalWrapper -> {
                    val au = a.nominalUseOrNull()
                    val eu = e.nominalUseOrNull()
                    au == eu || (scalarKind(a) != null && scalarKind(a) == scalarKind(e)) ||
                        ((a in literalTypes || e in literalTypes) && numericFamily(a) != null && numericFamily(a) == numericFamily(e)) ||
                        isNominalSubtype(au, eu)
                }

                else -> {
                    false
                }
            }
        }

        /** The common type of two branches; symmetric, so a literal or subtype on either side adopts the other. */
        private fun join(
            left: ExpressionType,
            right: ExpressionType,
            failure: FailureId = CheckFailure.IncompatibleExpressionTypes,
        ): ExpressionType {
            val a = canonical(left)
            val b = canonical(right)
            val missing = left.mayBeMissing || right.mayBeMissing
            if (a.value == ExpressionValueType.NULL_VALUE) return withMissing(nullable(b), missing)
            if (b.value == ExpressionValueType.NULL_VALUE) return withMissing(nullable(a), missing)
            val ac = (a.value as? ExpressionValueType.NullableWrapper)?.value ?: a
            val bc = (b.value as? ExpressionValueType.NullableWrapper)?.value ?: b
            demand(compatible(ac, bc) || compatible(bc, ac), failure)
            val av = ac.value
            val bv = bc.value
            var result =
                when {
                    av is ExpressionValueType.ListWrapper && bv is ExpressionValueType.ListWrapper -> {
                        listExpressionType(join(av.value, bv.value, failure))
                    }

                    av is ExpressionValueType.MapWrapper && bv is ExpressionValueType.MapWrapper -> {
                        mapExpressionType(join(av.value.key, bv.value.key, failure), join(av.value.value, bv.value.value, failure))
                    }

                    av is ExpressionValueType.EntryWrapper && bv is ExpressionValueType.EntryWrapper -> {
                        entryExpressionType(join(av.value.key, bv.value.key, failure), join(av.value.value, bv.value.value, failure))
                    }

                    ac in literalTypes && bc !in literalTypes -> {
                        bc
                    }

                    isNominalSubtype(ac.nominalUseOrNull(), bc.nominalUseOrNull()) -> {
                        bc
                    }

                    else -> {
                        ac
                    }
                }
            if (a.value is ExpressionValueType.NullableWrapper || b.value is ExpressionValueType.NullableWrapper) result = nullable(result)
            return withMissing(result, missing)
        }

        private fun nullable(type: ExpressionType): ExpressionType =
            when (type.value) {
                ExpressionValueType.NULL_VALUE, is ExpressionValueType.NullableWrapper -> {
                    type
                }

                else -> {
                    ExpressionType(
                        value = ExpressionValueType.NullableWrapper(withMissing(type, false)),
                        mayBeMissing = type.mayBeMissing,
                    )
                }
            }

        /** The item type of a list, set or declared sequence, or the entry type of a map or declared mapping. */
        private fun collectionItemOrNull(source: ExpressionType): ExpressionType? =
            when (val shape = canonical(source).value) {
                is ExpressionValueType.ListWrapper -> {
                    shape.value
                }

                is ExpressionValueType.MapWrapper -> {
                    entryExpressionType(shape.value.key, shape.value.value)
                }

                is ExpressionValueType.NominalWrapper -> {
                    when (val represented = representationOrNull(source)) {
                        is ResolvedRepresentation.SequenceWrapper -> {
                            nominalExpressionType(represented.value.item)
                        }

                        is ResolvedRepresentation.MappingWrapper -> {
                            entryExpressionType(
                                nominalExpressionType(represented.value.key),
                                nominalExpressionType(represented.value.value),
                            )
                        }

                        else -> {
                            null
                        }
                    }
                }

                else -> {
                    null
                }
            }

        /** The item type of a list: a structural list or a declared sequence of list kind. */
        private fun listItemOrNull(source: ExpressionType): ExpressionType? =
            when (val shape = canonical(source).value) {
                is ExpressionValueType.ListWrapper -> {
                    shape.value
                }

                is ExpressionValueType.NominalWrapper -> {
                    (representationOrNull(source) as? ResolvedRepresentation.SequenceWrapper)
                        ?.value
                        ?.takeIf { it.kind == CollectionKind.LIST }
                        ?.let { nominalExpressionType(it.item) }
                }

                else -> {
                    null
                }
            }

        /** The item type of a set: a declared sequence of set kind, such as the framework Set. */
        private fun setItemOrNull(source: ExpressionType): ExpressionType? =
            (representationOrNull(canonical(source)) as? ResolvedRepresentation.SequenceWrapper)
                ?.value
                ?.takeIf { it.kind == CollectionKind.SET }
                ?.let { nominalExpressionType(it.item) }

        private fun representationOrNull(type: ExpressionType): ResolvedRepresentation? {
            val use = type.nominalUseOrNull() ?: return null
            if (use is TypeUse.NullableWrapper) return null
            return ready(use).schema.representation
        }

        private fun mappingTypes(type: ExpressionType): ExpressionMappingType? =
            when (val shape = canonical(type).value) {
                is ExpressionValueType.MapWrapper -> {
                    shape.value
                }

                is ExpressionValueType.NominalWrapper -> {
                    (representationOrNull(type) as? ResolvedRepresentation.MappingWrapper)?.let {
                        ExpressionMappingType(key = nominalExpressionType(it.value.key), value = nominalExpressionType(it.value.value))
                    }
                }

                else -> {
                    null
                }
            }

        /** The catalog use of a type that has one; entries and the null literal have none. */
        private fun useOrNull(type: ExpressionType): TypeUse? =
            when (val shape = canonical(type).value) {
                is ExpressionValueType.NominalWrapper -> {
                    type.nominalUseOrNull()
                }

                is ExpressionValueType.ListWrapper -> {
                    useOrNull(shape.value)?.let { StandardTypes.list.use(listOf(it)) }
                }

                is ExpressionValueType.MapWrapper -> {
                    val key = useOrNull(shape.value.key)
                    val value = useOrNull(shape.value.value)
                    if (key != null && value != null) StandardTypes.map.use(listOf(key, value)) else null
                }

                is ExpressionValueType.NullableWrapper -> {
                    useOrNull(shape.value)?.nullable()
                }

                else -> {
                    null
                }
            }

        private fun project(
            source: ExpressionType,
            path: ValuePath,
        ): ExpressionType {
            var current = source
            var missing = source.mayBeMissing
            path.segments.forEach { segment ->
                current = canonical(current)
                val nullable = current.value as? ExpressionValueType.NullableWrapper
                if (nullable != null) {
                    current = nullable.value
                    missing = true
                }
                missing = missing || current.mayBeMissing
                current =
                    when (segment) {
                        is PathSegment.ItemWrapper -> {
                            missing = true
                            collectionItemOrNull(current) ?: fail(CheckFailure.InvalidExpressionPath)
                        }

                        PathSegment.MAP_KEY -> {
                            (canonical(current).value as? ExpressionValueType.EntryWrapper)?.value?.key
                                ?: fail(CheckFailure.InvalidExpressionPath)
                        }

                        PathSegment.MAP_VALUE -> {
                            (canonical(current).value as? ExpressionValueType.EntryWrapper)?.value?.value
                                ?: fail(CheckFailure.InvalidExpressionPath)
                        }

                        is PathSegment.FieldWrapper -> {
                            val use = current.nominalUseOrNull() ?: fail(CheckFailure.InvalidExpressionPath)
                            val checked = ready(use)
                            val field =
                                checked.schema.fields.singleOrNull { it.key == segment.name } ?: fail(CheckFailure.InvalidExpressionPath)
                            // A read model is a complete Skir value, so its fields are present whenever it is;
                            // an authored field may be unfilled.
                            nominalExpressionType(field.type, !CanonicalReadModels.supports(use))
                        }

                        else -> {
                            unknownVariant(segment)
                        }
                    }
            }
            return withMissing(current, missing || current.mayBeMissing)
        }

        private fun literal(value: DataValue): ExpressionType =
            when (value) {
                DataValue.NULL -> {
                    ExpressionType(value = ExpressionValueType.NULL_VALUE, mayBeMissing = false)
                }

                is DataValue.NamedWrapper -> {
                    nominalExpressionType(value.actualType.use)
                }

                is DataValue.BooleanWrapper -> {
                    boolean()
                }

                is DataValue.IntegerWrapper -> {
                    scalar(integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR)).also(literalTypes::add)
                }

                is DataValue.FloatWrapper -> {
                    scalar(floatScalar(FloatWidth.SIXTY_FOUR)).also(literalTypes::add)
                }

                is DataValue.DecimalWrapper -> {
                    scalar(ScalarKind.DECIMAL).also(literalTypes::add)
                }

                is DataValue.StringValueWrapper -> {
                    text()
                }

                is DataValue.BytesWrapper -> {
                    scalar(ScalarKind.BYTES)
                }

                is DataValue.TimestampWrapper -> {
                    scalar(ScalarKind.TIMESTAMP)
                }

                is DataValue.DurationWrapper -> {
                    scalar(ScalarKind.DURATION)
                }

                DataValue.UNIT -> {
                    scalar(ScalarKind.UNIT)
                }

                is DataValue.ListValueWrapper -> {
                    listExpressionType(literalItems(value.value.items.map { it.value }))
                }

                is DataValue.SetValueWrapper -> {
                    val item =
                        useOrNull(literalItems(value.value.items.map { it.value }))
                            ?: fail(CheckFailure.ExpressionTypeInferenceFailed)
                    nominalExpressionType(StandardTypes.set.use(listOf(item)))
                }

                is DataValue.MapValueWrapper -> {
                    demand(value.value.rows.isNotEmpty(), CheckFailure.ExpressionTypeInferenceFailed)
                    mapExpressionType(literalItems(value.value.rows.map { it.key }), literalItems(value.value.rows.map { it.value }))
                }

                else -> {
                    fail(CheckFailure.ExpressionTypeInferenceFailed)
                }
            }

        private fun literalItems(items: List<DataValue>): ExpressionType {
            val populated = items.filter { it != DataValue.UNFILLED }
            demand(populated.isNotEmpty(), CheckFailure.ExpressionTypeInferenceFailed)
            val inferred = populated.map(::literal).reduce { left, right -> join(left, right) }
            return withMissing(inferred, inferred.mayBeMissing || populated.size != items.size)
        }

        private fun frameValue(
            frames: List<List<ExpressionType>>,
            depth: Int,
            slot: Int,
        ): ExpressionType = frames.asReversed().getOrNull(depth)?.getOrNull(slot) ?: fail(CheckFailure.InvalidExpressionLocal)

        private fun infer(
            node: ExpressionNode,
            frames: List<List<ExpressionType>> = emptyList(),
        ): ExpressionType =
            when (node) {
                is ExpressionNode.LiteralWrapper -> {
                    literal(node.value.portableOrNull() ?: fail(CheckFailure.InvalidExpressionLiteral))
                }

                is ExpressionNode.InputWrapper -> {
                    inputType(node.value.binding.value, decodePath(node.value.path))
                }

                is ExpressionNode.LocalWrapper -> {
                    project(frameValue(frames, node.value.depth, node.value.slot), decodePath(node.value.path))
                }

                is ExpressionNode.FieldWrapper -> {
                    inferField(node.value.source, decodePath(node.value.path), frames)
                }

                is ExpressionNode.AndWrapper -> {
                    booleanResult(listOf(infer(node.value.left, frames), infer(node.value.right, frames)))
                }

                is ExpressionNode.OrWrapper -> {
                    booleanResult(listOf(infer(node.value.left, frames), infer(node.value.right, frames)))
                }

                is ExpressionNode.ConditionalWrapper -> {
                    val test = infer(node.value.test, frames)
                    requireKind(test, ScalarKind.BOOLEAN)
                    val then: ExpressionType
                    val otherwise: ExpressionType
                    if (isUntypedEmpty(node.value.then) && !isUntypedEmpty(node.value.otherwise)) {
                        otherwise = infer(node.value.otherwise, frames)
                        then = contextualEmpty(node.value.then, otherwise) ?: infer(node.value.then, frames)
                    } else {
                        then = infer(node.value.then, frames)
                        otherwise = contextualEmpty(node.value.otherwise, then) ?: infer(node.value.otherwise, frames)
                    }
                    withMissing(join(then, otherwise), test.mayBeMissing || then.mayBeMissing || otherwise.mayBeMissing)
                }

                is ExpressionNode.OrElseWrapper -> {
                    val value = infer(node.value.value, frames)
                    val fallback = contextualEmpty(node.value.fallback, value) ?: infer(node.value.fallback, frames)
                    val shape = canonical(value)
                    if (shape.value == ExpressionValueType.NULL_VALUE) {
                        fallback
                    } else {
                        val nonnull = (shape.value as? ExpressionValueType.NullableWrapper)?.value ?: shape
                        val joined = join(withMissing(nonnull, false), fallback)
                        if (value.mayBeMissing || shape.value is ExpressionValueType.NullableWrapper) {
                            withMissing(joined, fallback.mayBeMissing)
                        } else {
                            withMissing(value, false)
                        }
                    }
                }

                is ExpressionNode.CallWrapper -> {
                    inferCall(node.value, frames)
                }

                is ExpressionNode.LambdaWrapper -> {
                    fail(CheckFailure.InvalidLambda)
                }

                else -> {
                    fail(CheckFailure.UnknownExpression)
                }
            }

        /** A field projection; reads of an input keep one path so partially selected bindings resolve their fields. */
        private fun inferField(
            source: ExpressionNode,
            path: ValuePath,
            frames: List<List<ExpressionType>>,
        ): ExpressionType =
            when (source) {
                is ExpressionNode.InputWrapper -> {
                    inputType(source.value.binding.value, ValuePath(segments = decodePath(source.value.path).segments + path.segments))
                }

                is ExpressionNode.FieldWrapper -> {
                    inferField(source.value.source, ValuePath(segments = decodePath(source.value.path).segments + path.segments), frames)
                }

                else -> {
                    project(infer(source, frames), path)
                }
            }

        /** The one call rule: arguments unify with the declared signature, then the declared result resolves. */
        private fun inferCall(
            call: CallExpression,
            frames: List<List<ExpressionType>>,
        ): ExpressionType {
            val declaration = validateCall(call)
            val variables = TypeVariables(declaration, explicitTypeArguments(declaration, call.typeArguments))
            var missing = false
            val emptyLiterals = mutableListOf<Int>()
            val lambdas = mutableListOf<Int>()
            call.arguments.forEachIndexed { index, argument ->
                val parameter = requireNotNull(declaration.parameterAt(index))
                when {
                    parameter.kind.lambdaArity != null -> {
                        lambdas += index
                    }

                    isUntypedEmpty(argument) -> {
                        emptyLiterals += index
                    }

                    parameter.type is Signature.FieldOf -> {
                        variables.field(parameter.name, parameter.type, argument)
                    }

                    else -> {
                        val actual = infer(argument, frames)
                        variables.unify(parameter.type, withMissing(actual, false))
                        missing = missing || (actual.mayBeMissing && parameter.kind == ParameterKind.VALUE)
                    }
                }
            }
            emptyLiterals.forEach { index ->
                val parameter = requireNotNull(declaration.parameterAt(index))
                val context = variables.resolveOrNull(parameter.type) ?: fail(CheckFailure.ExpressionTypeInferenceFailed)
                variables.unify(parameter.type, contextualEmpty(call.arguments[index], context) ?: fail(CheckFailure.InvalidOperandType))
            }
            lambdas.forEach { index ->
                val type = requireNotNull(declaration.parameterAt(index)).type
                val argument = call.arguments[index]
                val body =
                    when (type) {
                        is Signature.Each -> {
                            lambdaBody(argument, frames, listOf(variables.resolve(type.item))).also {
                                variables.unify(type.result, withMissing(it, false))
                            }
                        }

                        is Signature.Step -> {
                            lambdaBody(argument, frames, listOf(variables.resolve(type.accumulator), variables.resolve(type.item))).also {
                                variables.unify(type.accumulator, withMissing(it, false))
                            }
                        }

                        is Signature.Comparator -> {
                            val item = variables.resolve(type.item)
                            lambdaBody(argument, frames, listOf(item, item)).also {
                                demand(scalarKind(it) is ScalarKind.IntegerWrapper, CheckFailure.InvalidOperandType)
                            }
                        }

                        is Signature.Apply -> {
                            lambdaBody(argument, frames, listOf(variables.resolve(type.input))).also {
                                variables.unify(type.result, withMissing(it, false))
                            }
                        }

                        else -> {
                            fail(CheckFailure.InvalidLambda)
                        }
                    }
                missing = missing || body.mayBeMissing
            }
            val result = variables.resolve(declaration.result)
            return withMissing(result, result.mayBeMissing || missing)
        }

        private fun lambdaBody(
            argument: ExpressionNode,
            frames: List<List<ExpressionType>>,
            locals: List<ExpressionType>,
        ): ExpressionType {
            val lambda = (argument as? ExpressionNode.LambdaWrapper)?.value ?: fail(CheckFailure.InvalidLambda)
            demand(lambda.arity == locals.size, CheckFailure.InvalidLambda)
            return infer(lambda.body, frames + listOf(locals.map { withMissing(it, false) }))
        }

        /** Closed, resolvable type arguments for the explicit type parameters, in declaration order. */
        private fun explicitTypeArguments(
            declaration: PortableOperation,
            templates: List<TypeTemplate>,
        ): Map<String, ExpressionType> {
            val parameters = declaration.explicitTypeParameters
            demand(templates.size == parameters.size, CheckFailure.InvalidTypeArgument)
            return parameters.zip(templates).associate { (parameter, template) ->
                demand(template.isValid, CheckFailure.InvalidTypeArgument)
                val use = (template.apply(emptyMap()) as? Resolution.Ready)?.value ?: fail(CheckFailure.InvalidTypeArgument)
                demand(resolveType(use) is Resolution.Ready, CheckFailure.InvalidTypeArgument)
                val type = canonical(nominalExpressionType(use))
                demand(satisfies(type, parameter.bound), CheckFailure.InvalidTypeArgument)
                parameter.name to type
            }
        }

        private fun satisfies(
            type: ExpressionType,
            bound: TypeBound,
        ): Boolean =
            when (bound) {
                TypeBound.ANY -> true
                TypeBound.NUMERIC -> numericFamily(type) != null
                TypeBound.INTEGER -> scalarKind(type) is ScalarKind.IntegerWrapper
                TypeBound.SIZED -> scalarKind(type) in SIZED_SCALARS || collectionItemOrNull(type) != null
                TypeBound.ORDERED -> numericFamily(type) != null || scalarKind(type) in ORDERED_SCALARS
            }

        /** Whether [type] fits a scalar parameter word; numeric words accept every width of their family. */
        private fun fitsScalar(
            type: ExpressionType,
            word: Signature.ScalarWord,
        ): Boolean {
            val kind = scalarKind(type)
            return when (word) {
                Signature.ScalarWord.TEXT -> kind == ScalarKind.TEXT
                Signature.ScalarWord.BOOLEAN -> kind == ScalarKind.BOOLEAN
                Signature.ScalarWord.BYTES -> kind == ScalarKind.BYTES
                Signature.ScalarWord.DURATION -> kind == ScalarKind.DURATION
                Signature.ScalarWord.TIMESTAMP -> kind == ScalarKind.TIMESTAMP
                Signature.ScalarWord.INT32, Signature.ScalarWord.INTEGER -> kind is ScalarKind.IntegerWrapper
                Signature.ScalarWord.FLOAT -> kind is ScalarKind.FloatWrapper
                Signature.ScalarWord.DECIMAL -> kind == ScalarKind.DECIMAL
                Signature.ScalarWord.RESOURCE_ID -> compatible(type, nominalExpressionType(ResourceIdDefinition.use.use))
            }
        }

        /** The payload type of a value of [type]: scalars, sequences and mappings expose their representation. */
        private fun representation(type: ExpressionType): ExpressionType =
            when (val represented = representationOrNull(type)) {
                is ResolvedRepresentation.ScalarWrapper -> {
                    scalar(represented.value.kind)
                }

                is ResolvedRepresentation.SequenceWrapper -> {
                    if (represented.value.kind == CollectionKind.SET) {
                        nominalExpressionType(StandardTypes.set.use(listOf(represented.value.item)))
                    } else {
                        listExpressionType(nominalExpressionType(represented.value.item))
                    }
                }

                is ResolvedRepresentation.MappingWrapper -> {
                    mapExpressionType(nominalExpressionType(represented.value.key), nominalExpressionType(represented.value.value))
                }

                else -> {
                    withMissing(type, false)
                }
            }

        /** The bindings of one call's type parameters, unified argument by argument. */
        private inner class TypeVariables(
            declaration: PortableOperation,
            private val explicit: Map<String, ExpressionType>,
        ) {
            private val bounds = declaration.typeParameters.associate { it.name to it.bound }
            private val bound = explicit.toMutableMap()
            private val fieldTypes = mutableMapOf<String, ExpressionType>()

            /** Binds the literal field name [argument] of a field_of parameter to the declared type of that field. */
            fun field(
                name: String,
                signature: Signature.FieldOf,
                argument: ExpressionNode,
            ) {
                val literal = (argument as? ExpressionNode.LiteralWrapper)?.value?.portableOrNull()?.unwrapNamed()
                val field = (literal as? DataValue.StringValueWrapper)?.value ?: fail(CheckFailure.LiteralRequired)
                val record = resolve(signature.record).nominalUseOrNull() ?: fail(CheckFailure.InvalidOperandType)
                val declared = ready(record).schema.fields.singleOrNull { it.key == field } ?: fail(CheckFailure.InvalidOperandType)
                fieldTypes[name] = nominalExpressionType(declared.type)
            }

            fun unify(
                expected: Signature,
                actual: ExpressionType,
            ) {
                when (expected) {
                    is Signature.Scalar -> {
                        demand(fitsScalar(actual, expected.word), CheckFailure.InvalidOperandType)
                    }

                    is Signature.Named -> {
                        demand(compatible(actual, nominalExpressionType(expected.use)), CheckFailure.InvalidOperandType)
                    }

                    is Signature.ReadModel -> {
                        demand(compatible(actual, readModel(expected)), CheckFailure.InvalidOperandType)
                    }

                    is Signature.Variable -> {
                        bind(expected.name, actual)
                    }

                    is Signature.Nullable -> {
                        val shape = canonical(actual)
                        when (val value = shape.value) {
                            ExpressionValueType.NULL_VALUE -> Unit
                            is ExpressionValueType.NullableWrapper -> unify(expected.value, value.value)
                            else -> unify(expected.value, actual)
                        }
                    }

                    is Signature.ListOf -> {
                        unify(expected.item, listItemOrNull(actual) ?: fail(CheckFailure.InvalidOperandType))
                    }

                    is Signature.SetOf -> {
                        unify(expected.item, setItemOrNull(actual) ?: fail(CheckFailure.InvalidOperandType))
                    }

                    is Signature.MapOf -> {
                        val mapping = mappingTypes(actual) ?: fail(CheckFailure.InvalidOperandType)
                        unify(expected.key, mapping.key)
                        unify(expected.value, mapping.value)
                    }

                    is Signature.EntryOf -> {
                        val entry =
                            (canonical(actual).value as? ExpressionValueType.EntryWrapper)?.value
                                ?: fail(CheckFailure.InvalidOperandType)
                        unify(expected.key, entry.key)
                        unify(expected.value, entry.value)
                    }

                    is Signature.Items -> {
                        unify(expected.item, collectionItemOrNull(actual) ?: fail(CheckFailure.InvalidOperandType))
                    }

                    is Signature.Link -> {
                        val link = representationOrNull(canonical(actual)) as? ResolvedRepresentation.LinkWrapper
                        unify(expected.target, nominalExpressionType(link?.value?.target ?: fail(CheckFailure.InvalidOperandType)))
                    }

                    is Signature.Partial -> {
                        unify(expected.value, actual)
                    }

                    is Signature.Located -> {
                        unify(expected.value, actual)
                    }

                    is Signature.FieldType -> {
                        val field = fieldTypes[expected.field] ?: fail(CheckFailure.InvalidOperandType)
                        demand(compatible(actual, field), CheckFailure.InvalidOperandType)
                    }

                    is Signature.Representation -> {
                        demand(compatible(actual, representation(resolve(expected.named))), CheckFailure.InvalidOperandType)
                    }

                    is Signature.Maybe, is Signature.Each, is Signature.Step, is Signature.Comparator, is Signature.Apply,
                    is Signature.FieldOf,
                    -> {
                        fail(CheckFailure.InvalidOperandType)
                    }
                }
            }

            fun resolveOrNull(signature: Signature): ExpressionType? =
                try {
                    resolve(signature)
                } catch (_: ExpressionCheckFailure) {
                    null
                }

            fun resolve(signature: Signature): ExpressionType =
                when (signature) {
                    is Signature.Scalar -> {
                        signature.word.kind?.let { scalar(it) } ?: nominalExpressionType(ResourceIdDefinition.use.use)
                    }

                    is Signature.Named -> {
                        nominalExpressionType(signature.use)
                    }

                    is Signature.ReadModel -> {
                        readModel(signature)
                    }

                    is Signature.Variable -> {
                        bound[signature.name] ?: fail(CheckFailure.ExpressionTypeInferenceFailed)
                    }

                    is Signature.Nullable -> {
                        nullable(resolve(signature.value))
                    }

                    is Signature.ListOf -> {
                        listExpressionType(resolve(signature.item))
                    }

                    is Signature.SetOf -> {
                        val item = useOrNull(resolve(signature.item)) ?: fail(CheckFailure.ExpressionTypeInferenceFailed)
                        nominalExpressionType(StandardTypes.set.use(listOf(item)))
                    }

                    is Signature.MapOf -> {
                        mapExpressionType(resolve(signature.key), resolve(signature.value))
                    }

                    is Signature.EntryOf -> {
                        entryExpressionType(resolve(signature.key), resolve(signature.value))
                    }

                    is Signature.Maybe -> {
                        withMissing(resolve(signature.value), true)
                    }

                    is Signature.Partial -> {
                        resolve(signature.value)
                    }

                    is Signature.Located -> {
                        resolve(signature.value)
                    }

                    is Signature.Representation -> {
                        representation(resolve(signature.named))
                    }

                    is Signature.FieldType -> {
                        fieldTypes[signature.field] ?: fail(CheckFailure.ExpressionTypeInferenceFailed)
                    }

                    is Signature.Items, is Signature.Link, is Signature.Each, is Signature.Step, is Signature.Comparator,
                    is Signature.Apply, is Signature.FieldOf,
                    -> {
                        fail(CheckFailure.ExpressionTypeInferenceFailed)
                    }
                }

            /**
             * Binds a type variable. An explicit binding only admits compatible arguments. Numbers must share one family;
             * a literal adopts the width of a non literal operand, and otherwise the widest operand wins. Other types
             * join symmetrically.
             */
            private fun bind(
                name: String,
                actual: ExpressionType,
            ) {
                demand(satisfies(actual, bounds.getValue(name)), CheckFailure.InvalidOperandType)
                val existing = bound[name]
                bound[name] =
                    when {
                        existing == null -> actual
                        name in explicit -> existing.also { demand(compatible(actual, existing), CheckFailure.InvalidOperandType) }
                        else -> merge(existing, actual)
                    }
            }

            private fun merge(
                left: ExpressionType,
                right: ExpressionType,
            ): ExpressionType {
                val leftFamily = numericFamily(left)
                val rightFamily = numericFamily(right)
                if (leftFamily == null || rightFamily == null) return join(left, right, CheckFailure.InvalidOperandType)
                demand(leftFamily == rightFamily, CheckFailure.NumericFamilyMismatch)
                return when {
                    left in literalTypes && right !in literalTypes -> right
                    right in literalTypes && left !in literalTypes -> left
                    left.nominalUseOrNull() == right.nominalUseOrNull() -> left
                    width(right) > width(left) -> right
                    else -> left
                }
            }

            /** Orders numeric widths of one family: more bits first, then signed before unsigned. */
            private fun width(type: ExpressionType): Int =
                when (val kind = scalarKind(type)) {
                    is ScalarKind.IntegerWrapper -> {
                        when (kind.value.width) {
                            IntegerWidth.UNSIGNED_EIGHT -> 0
                            IntegerWidth.SIGNED_EIGHT -> 1
                            IntegerWidth.UNSIGNED_SIXTEEN -> 2
                            IntegerWidth.SIGNED_SIXTEEN -> 3
                            IntegerWidth.UNSIGNED_THIRTY_TWO -> 4
                            IntegerWidth.SIGNED_THIRTY_TWO -> 5
                            IntegerWidth.UNSIGNED_SIXTY_FOUR -> 6
                            else -> 7
                        }
                    }

                    is ScalarKind.FloatWrapper -> {
                        if (kind.value.width == FloatWidth.THIRTY_TWO) 0 else 1
                    }

                    else -> {
                        0
                    }
                }

            private fun readModel(signature: Signature.ReadModel): ExpressionType =
                nominalExpressionType(CanonicalReadModels.model(signature.serializer).use.use)
        }

        private fun untypedEmpty(node: ExpressionNode): DataValue? {
            val raw = (node as? ExpressionNode.LiteralWrapper)?.value ?: return null
            return when (val value = raw.portableOrNull() ?: return null) {
                is DataValue.ListValueWrapper -> value.takeIf { it.value.items.isEmpty() }
                is DataValue.SetValueWrapper -> value.takeIf { it.value.items.isEmpty() }
                is DataValue.MapValueWrapper -> value.takeIf { it.value.rows.isEmpty() }
                else -> null
            }
        }

        private fun isUntypedEmpty(node: ExpressionNode): Boolean = untypedEmpty(node) != null

        private fun contextualEmpty(
            node: ExpressionNode,
            hint: ExpressionType,
        ): ExpressionType? {
            val empty = untypedEmpty(node) ?: return null
            val normalized = canonical(hint)
            val known = (normalized.value as? ExpressionValueType.NullableWrapper)?.value ?: normalized
            val matches =
                when (empty) {
                    is DataValue.ListValueWrapper -> listItemOrNull(known) != null
                    is DataValue.MapValueWrapper -> mappingTypes(known) != null
                    is DataValue.SetValueWrapper -> setItemOrNull(known) != null
                    else -> false
                }
            return if (matches) withMissing(known, false) else null
        }

        private fun inputType(
            id: String,
            path: ValuePath,
        ): ExpressionType {
            val key = ExpressionBindingId(value = id)
            val selection = partialBindings[key]
            if (selection == null) {
                val input = bindings[key] ?: fail(CheckFailure.UnknownExpressionBinding)
                validateType(input)
                return project(input, path)
            }
            val missing = bindings[key]?.mayBeMissing ?: true
            if (selection is TypeSelection.CompleteWrapper) {
                ready(selection.use.use)
                return project(nominalExpressionType(selection.use.use, missing), path)
            }
            selection as TypeSelection.PendingWrapper
            val complete = selection.arguments.map { (it as? ArgumentSelection.ChosenWrapper)?.type }
            if (complete.all { it != null }) {
                val use = selection.definition.namedUse(complete.filterNotNull())
                ready(use.use)
                return project(nominalExpressionType(use.use, missing), path)
            }
            val field = path.segments.firstOrNull() as? PathSegment.FieldWrapper ?: fail(CheckFailure.InvalidExpressionPath)
            val schema =
                when (val resolved = resolvePartial?.invoke(selection)) {
                    is Resolution.Ready -> resolved.value
                    else -> fail(CheckFailure.InvalidExpressionPath)
                }
            val known = schema.knownFields.singleOrNull { it.key == field.name } ?: fail(CheckFailure.InvalidExpressionPath)
            return project(nominalExpressionType(known.type, missing), ValuePath(segments = path.segments.drop(1)))
        }

        private fun requireKind(
            type: ExpressionType,
            kind: ScalarKind,
        ) = demand(scalarKind(type) == kind, CheckFailure.InvalidOperandType)

        private fun booleanResult(values: List<ExpressionType>): ExpressionType {
            values.forEach { requireKind(it, ScalarKind.BOOLEAN) }
            return boolean(values.any { it.mayBeMissing })
        }
    }

    private companion object {
        val RULE_SUBJECT = ExpressionBindingId(value = "configured_value")
        val SIZED_SCALARS = setOf(ScalarKind.TEXT, ScalarKind.BYTES)
        val ORDERED_SCALARS = setOf(ScalarKind.TEXT, ScalarKind.BOOLEAN, ScalarKind.TIMESTAMP, ScalarKind.DURATION)
    }
}

/** Calls to operations Realm cannot evaluate, read from their declarations. */
internal fun ExpressionNode.ruleProfileViolations(): List<FailureId> =
    descendants()
        .filterIsInstance<ExpressionNode.CallWrapper>()
        .filter { PortableOperationCatalog.declaration(it.value.operation)?.profile == OperationProfile.PANEL }
        .map { CheckFailure.OutsideRuleProfile }
        .distinct()
        .toList()

private enum class NumericFamily { INTEGER, FLOAT, DECIMAL }

/** The number of locals a lambda argument of this kind opens, or null for an evaluated argument. */
private val ParameterKind.lambdaArity: Int?
    get() =
        when (this) {
            ParameterKind.EACH, ParameterKind.APPLY -> 1
            ParameterKind.STEP, ParameterKind.COMPARATOR -> 2
            ParameterKind.VALUE, ParameterKind.PARTIAL, ParameterKind.LOCATED -> null
        }

/**
 * The catalog scalar a scalar word denotes as a result: integer results are 64 bit, int32 results 32 bit. A resource
 * identity is the named ResourceId, not a scalar.
 */
private val Signature.ScalarWord.kind: ScalarKind?
    get() =
        when (this) {
            Signature.ScalarWord.TEXT -> ScalarKind.TEXT
            Signature.ScalarWord.BOOLEAN -> ScalarKind.BOOLEAN
            Signature.ScalarWord.INT32 -> integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
            Signature.ScalarWord.INTEGER -> integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR)
            Signature.ScalarWord.FLOAT -> floatScalar(FloatWidth.SIXTY_FOUR)
            Signature.ScalarWord.DECIMAL -> ScalarKind.DECIMAL
            Signature.ScalarWord.BYTES -> ScalarKind.BYTES
            Signature.ScalarWord.DURATION -> ScalarKind.DURATION
            Signature.ScalarWord.TIMESTAMP -> ScalarKind.TIMESTAMP
            Signature.ScalarWord.RESOURCE_ID -> null
        }

private class ExpressionCheckFailure(
    val failure: FailureId,
) : RuntimeException(failure.value, null, false, false)

private fun demand(
    condition: Boolean,
    failure: FailureId,
) {
    if (!condition) fail(failure)
}

private fun fail(failure: FailureId): Nothing = throw ExpressionCheckFailure(failure)
