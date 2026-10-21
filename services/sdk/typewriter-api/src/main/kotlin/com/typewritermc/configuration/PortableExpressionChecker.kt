package com.typewritermc.configuration

import com.typewritermc.authoring.PartialSchema
import com.typewritermc.authoring.arguments
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.name
import com.typewritermc.authoring.root
import com.typewritermc.authoring.type
import com.typewritermc.authoring.use
import com.typewritermc.expression.CanonicalReadModels
import com.typewritermc.expression.CheckedExpressionProgram
import com.typewritermc.expression.CheckedQueryCall
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionOccurrence
import com.typewritermc.expression.PortableExpressionLimits
import com.typewritermc.expression.children
import com.typewritermc.expression.entryExpressionType
import com.typewritermc.expression.listExpressionType
import com.typewritermc.expression.mapExpressionType
import com.typewritermc.expression.nominalExpressionType
import com.typewritermc.expression.nominalUseOrNull
import com.typewritermc.expression.resourceSourceOrNull
import com.typewritermc.expression.sourceExpression
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.fields
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.isValid
import com.typewritermc.types.items
import com.typewritermc.types.namedUse
import com.typewritermc.types.portableOrNull
import com.typewritermc.types.rows
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import com.typewritermc.types.validOrNull
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.expression.BoundDirection
import skirout.editor.v1.expression.EntryBranch
import skirout.editor.v1.expression.ExpressionMappingType
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionQuery
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.ExpressionValueType
import skirout.editor.v1.expression.NumberArithmeticOperation
import skirout.editor.v1.expression.NumberCompareOperation
import skirout.editor.v1.expression.RegexMatchMode
import skirout.editor.v1.expression.ResourceQuerySource
import skirout.editor.v1.expression.RuleUnaryOperation
import skirout.editor.v1.expression.SizeBoundMetric
import skirout.editor.v1.expression.SizeRangeMetric
import skirout.editor.v1.expression.TextCompareOperation
import skirout.editor.v1.expression.TextUnaryOperation
import skirout.editor.v1.expression.TimestampBoundDirection
import skirout.editor.v1.expression.ValueCompareOperation
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import java.util.Collections
import java.util.IdentityHashMap

/** A checked expression retains the shared syntax and its declared result contract. */
data class CheckedExpression(
    val body: ExpressionNode,
    val result: ExpressionType,
)

/** Checks the closed shared expression language with lexical frames scoped to one invocation. */
class PortableExpressionChecker(
    resolveType: (TypeUse) -> Resolution<CheckedType>,
    private val owner: TypeDefinitionId? = null,
    private val resolvePartial: ((TypeSelection) -> Resolution<PartialSchema>)? = null,
) {
    private val resolveType: (TypeUse) -> Resolution<CheckedType> = { use ->
        if (CanonicalReadModels.supports(use)) CanonicalReadModels.catalog.resolve(use) else resolveType(use)
    }

    fun checkProgram(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
        expectedOutput: ExpressionType,
        affected: TypeDefinitionId,
        partialBindings: Map<ExpressionBindingId, TypeSelection> = emptyMap(),
    ): Resolution<CheckedExpressionProgram> {
        val invocation = Invocation(bindings, partialBindings)
        val codes = invocation.check(body, expectedOutput)
        return if (codes.isEmpty()) {
            Resolution.Ready(CheckedExpressionProgram(body, expectedOutput, invocation.queries.toMap()))
        } else {
            Resolution.Invalid(codes.map { DeclarationDiagnostic.of(affected, it) })
        }
    }

    fun checkExpression(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
        expectedOutput: ExpressionType,
        affected: TypeDefinitionId,
        partialBindings: Map<ExpressionBindingId, TypeSelection> = emptyMap(),
    ): Resolution<CheckedExpression> =
        when (val checked = checkProgram(body, bindings, expectedOutput, affected, partialBindings)) {
            is Resolution.Ready -> Resolution.Ready(CheckedExpression(body, expectedOutput))
            is Resolution.Invalid -> checked
        }

    fun checkExpressionCodes(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
        expectedOutput: ExpressionType,
        partialBindings: Map<ExpressionBindingId, TypeSelection> = emptyMap(),
        onInferred: ((ExpressionType) -> Unit)? = null,
    ): List<String> = Invocation(bindings, partialBindings).check(body, expectedOutput, onInferred)

    /** Checks [body] against [bindings] and infers its result, for a result of any type such as an order key. */
    fun checkAnyResultCodes(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, ExpressionType>,
    ): List<String> = Invocation(bindings, emptyMap()).inferOnly(body)

    fun checkExpressionStructure(
        body: ExpressionNode,
        bindings: Set<ExpressionBindingId>,
    ): List<String> =
        try {
            validateStructure(body, bindings)
            emptyList()
        } catch (failure: ExpressionCheckFailure) {
            listOf(failure.code)
        }

    internal fun checkRule(
        body: ExpressionNode,
        subject: CheckedType,
    ): List<DeclarationDiagnostic> =
        checkExpressionCodes(
            body,
            mapOf(ExpressionBindingId("configured_value") to nominalExpressionType(subject.use)),
            nominalExpressionType(ScalarKind.BOOLEAN.use, true),
        ).map { DeclarationDiagnostic.of(requireNotNull(owner), it) }

    internal fun checkRuleStructure(body: ExpressionNode): List<DeclarationDiagnostic> =
        checkExpressionStructure(
            body,
            setOf(ExpressionBindingId("configured_value")),
        ).map { DeclarationDiagnostic.of(requireNotNull(owner), it) }

    private fun validateStructure(
        root: ExpressionNode,
        bindings: Set<ExpressionBindingId>,
    ) {
        fun visit(
            node: ExpressionNode,
            arities: List<Int>,
            depth: Int,
        ) {
            demand(depth <= PortableExpressionLimits.MAX_DEPTH, "expression_depth_limit")
            when (node) {
                is ExpressionNode.InputWrapper -> {
                    demand(ExpressionBindingId(node.value.binding.value) in bindings, "unknown_expression_binding")
                    decodePath(node.value.path)
                }

                is ExpressionNode.LocalWrapper -> {
                    demand(
                        node.value.depth >= 0 && node.value.slot >= 0 &&
                            arities.asReversed().getOrNull(node.value.depth)?.let { node.value.slot < it } == true,
                        "invalid_expression_local",
                    )
                    decodePath(node.value.path)
                }

                else -> {
                    Unit
                }
            }
            validateOperations(node)
            val children =
                try {
                    node.children()
                } catch (_: IllegalArgumentException) {
                    fail("unknown_expression")
                }
            children.forEach { child -> visit(child.node, if (child.frameArity == 0) arities else arities + child.frameArity, depth + 1) }
        }
        visit(root, emptyList(), 1)
    }

    private fun validateOperations(node: ExpressionNode) {
        val known =
            when (node) {
                is ExpressionNode.EntryProjectionWrapper -> {
                    node.value.branch != EntryBranch.UNKNOWN
                }

                is ExpressionNode.TextUnaryWrapper -> {
                    node.value.operation != TextUnaryOperation.UNKNOWN
                }

                is ExpressionNode.TextCompareWrapper -> {
                    node.value.operation != TextCompareOperation.UNKNOWN
                }

                is ExpressionNode.RegexTestWrapper -> {
                    node.value.mode != RegexMatchMode.UNKNOWN
                }

                is ExpressionNode.ValueCompareWrapper -> {
                    node.value.operation != ValueCompareOperation.UNKNOWN
                }

                is ExpressionNode.NumberArithmeticWrapper -> {
                    node.value.operation != NumberArithmeticOperation.UNKNOWN
                }

                is ExpressionNode.NumberCompareWrapper -> {
                    node.value.operation != NumberCompareOperation.UNKNOWN
                }

                is ExpressionNode.RuleUnaryWrapper -> {
                    node.value.operation != RuleUnaryOperation.UNKNOWN
                }

                is ExpressionNode.RuleSizeBoundWrapper -> {
                    node.value.metric != SizeBoundMetric.UNKNOWN &&
                        node.value.direction != BoundDirection.UNKNOWN
                }

                is ExpressionNode.RuleSizeRangeWrapper -> {
                    node.value.metric != SizeRangeMetric.UNKNOWN
                }

                is ExpressionNode.RuleNumericBoundWrapper -> {
                    node.value.direction != BoundDirection.UNKNOWN
                }

                is ExpressionNode.RuleTimestampBoundWrapper -> {
                    node.value.direction != TimestampBoundDirection.UNKNOWN
                }

                else -> {
                    true
                }
            }
        demand(known, "unknown_expression_operation")
    }

    private fun decodePath(path: ValuePath): ValuePath = path.validOrNull() ?: fail("invalid_expression_path")

    private inner class Invocation(
        bindings: Map<ExpressionBindingId, ExpressionType>,
        partialBindings: Map<ExpressionBindingId, TypeSelection>,
    ) {
        private val partialBindings = partialBindings.toMap()
        private val bindings = bindings.toMap()
        private val literalTypes = Collections.newSetFromMap(IdentityHashMap<ExpressionType, Boolean>())
        val queries = linkedMapOf<ExpressionOccurrence, CheckedQueryCall>()

        fun inferOnly(body: ExpressionNode): List<String> =
            try {
                validateStructure(body, bindings.keys + partialBindings.keys)
                infer(body)
                emptyList()
            } catch (failure: ExpressionCheckFailure) {
                listOf(failure.code)
            }

        fun check(
            body: ExpressionNode,
            expected: ExpressionType,
            onInferred: ((ExpressionType) -> Unit)? = null,
        ): List<String> =
            try {
                validateStructure(body, bindings.keys + partialBindings.keys)
                validateType(expected)
                val result = contextualEmpty(body, expected) ?: infer(body)
                onInferred?.invoke(result)
                demand(compatible(result, expected), "incompatible_expression_result_type")
                demand(!result.mayBeMissing || expected.mayBeMissing, "expression_result_may_be_missing")
                emptyList()
            } catch (failure: ExpressionCheckFailure) {
                listOf(failure.code)
            }

        private fun validateType(
            type: ExpressionType,
            depth: Int = 1,
        ) {
            demand(depth <= PortableExpressionLimits.MAX_DEPTH, "expression_depth_limit")
            when (val shape = type.value) {
                is ExpressionValueType.NominalWrapper -> {
                    ready(type.nominalUseOrNull() ?: fail("invalid_expression_type"))
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
                    fail("invalid_expression_type")
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

        private fun integer(missing: Boolean = false) = scalar(integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR), missing)

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
                is Resolution.Invalid -> fail("invalid_expression_type")
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

        private fun numericFamily(type: ExpressionType): Int? =
            when (scalarKind(type)) {
                is ScalarKind.IntegerWrapper -> 0
                is ScalarKind.FloatWrapper -> 1
                ScalarKind.DECIMAL -> 2
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
            if (av ==
                ExpressionValueType.NULL_VALUE
            ) {
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
                    compatible(av.value.key, ev.value.key) &&
                        compatible(av.value.value, ev.value.value)
                }

                av is ExpressionValueType.EntryWrapper && ev is ExpressionValueType.EntryWrapper -> {
                    compatible(av.value.key, ev.value.key) &&
                        compatible(av.value.value, ev.value.value)
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

        private fun join(
            left: ExpressionType,
            right: ExpressionType,
        ): ExpressionType {
            val a = canonical(left)
            val b = canonical(right)
            val missing = left.mayBeMissing || right.mayBeMissing
            if (a.value == ExpressionValueType.NULL_VALUE) return withMissing(nullable(b), missing)
            if (b.value == ExpressionValueType.NULL_VALUE) return withMissing(nullable(a), missing)
            val ac = (a.value as? ExpressionValueType.NullableWrapper)?.value ?: a
            val bc = (b.value as? ExpressionValueType.NullableWrapper)?.value ?: b
            demand(compatible(ac, bc) || compatible(bc, ac), "incompatible_expression_types")
            val av = ac.value
            val bv = bc.value
            var result =
                when {
                    av is ExpressionValueType.ListWrapper && bv is ExpressionValueType.ListWrapper -> {
                        listExpressionType(
                            join(av.value, bv.value),
                        )
                    }

                    av is ExpressionValueType.MapWrapper && bv is ExpressionValueType.MapWrapper -> {
                        mapExpressionType(
                            join(av.value.key, bv.value.key),
                            join(av.value.value, bv.value.value),
                        )
                    }

                    av is ExpressionValueType.EntryWrapper && bv is ExpressionValueType.EntryWrapper -> {
                        entryExpressionType(
                            join(av.value.key, bv.value.key),
                            join(av.value.value, bv.value.value),
                        )
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

        private fun collectionItem(source: ExpressionType): ExpressionType =
            when (val shape = canonical(source).value) {
                is ExpressionValueType.ListWrapper -> {
                    shape.value
                }

                is ExpressionValueType.MapWrapper -> {
                    entryExpressionType(shape.value.key, shape.value.value)
                }

                is ExpressionValueType.NominalWrapper -> {
                    when (val represented = ready(requireNotNull(source.nominalUseOrNull())).schema.representation) {
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
                            fail("expression_collection_expected")
                        }
                    }
                }

                else -> {
                    fail("expression_collection_expected")
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
                            collectionItem(current)
                        }

                        PathSegment.MAP_KEY -> {
                            (canonical(current).value as? ExpressionValueType.EntryWrapper)?.value?.key
                                ?: fail("invalid_expression_path")
                        }

                        PathSegment.MAP_VALUE -> {
                            (canonical(current).value as? ExpressionValueType.EntryWrapper)?.value?.value
                                ?: fail("invalid_expression_path")
                        }

                        is PathSegment.FieldWrapper -> {
                            val checked = ready(current.nominalUseOrNull() ?: fail("invalid_expression_path"))
                            val field = checked.schema.fields.singleOrNull { it.key == segment.name } ?: fail("invalid_expression_path")
                            nominalExpressionType(field.type, true)
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
                    integer().also(literalTypes::add)
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
                    listExpressionType(literalItems(value.items.map { it.value }))
                }

                is DataValue.SetValueWrapper -> {
                    val item = literalItems(value.items.map { it.value }).nominalUseOrNull() ?: fail("expression_type_inference_failed")
                    nominalExpressionType(StandardTypes.set.use(listOf(item)))
                }

                is DataValue.MapValueWrapper -> {
                    demand(value.rows.isNotEmpty(), "expression_type_inference_failed")
                    mapExpressionType(literalItems(value.rows.map { it.key }), literalItems(value.rows.map { it.value }))
                }

                else -> {
                    fail("expression_type_inference_failed")
                }
            }

        private fun literalItems(items: List<DataValue>): ExpressionType {
            val populated = items.filter { it != DataValue.UNFILLED }
            demand(populated.isNotEmpty(), "expression_type_inference_failed")
            val inferred = populated.map(::literal).reduce(::join)
            return withMissing(inferred, inferred.mayBeMissing || populated.size != items.size)
        }

        private fun frameValue(
            frames: List<List<ExpressionType>>,
            depth: Int,
            slot: Int,
        ): ExpressionType = frames.asReversed().getOrNull(depth)?.getOrNull(slot) ?: fail("invalid_expression_local")

        private fun infer(
            node: ExpressionNode,
            frames: List<List<ExpressionType>> = emptyList(),
            occurrence: ExpressionOccurrence = ExpressionOccurrence(),
        ): ExpressionType {
            fun child(
                value: ExpressionNode,
                index: Int,
            ) = infer(value, frames, occurrence.child(index))

            fun unary(
                source: ExpressionNode,
                body: ExpressionNode,
                bodyIndex: Int = 1,
            ): Pair<ExpressionType, ExpressionType> {
                val input = child(source, 0)
                return input to infer(body, frames + listOf(listOf(collectionItem(input))), occurrence.child(bodyIndex))
            }
            return when (node) {
                is ExpressionNode.LiteralWrapper -> {
                    literal(
                        node.value.portableOrNull() ?: fail("invalid_expression_literal"),
                    )
                }

                is ExpressionNode.InputWrapper -> {
                    inputType(node.value.binding.value, decodePath(node.value.path))
                }

                is ExpressionNode.LocalWrapper -> {
                    project(frameValue(frames, node.value.depth, node.value.slot), decodePath(node.value.path))
                }

                is ExpressionNode.FieldWrapper, is ExpressionNode.EntryProjectionWrapper -> {
                    inferProjection(node, ValuePath.root, frames, occurrence)
                }

                is ExpressionNode.AndWrapper -> {
                    booleanResult(listOf(child(node.value.left, 0), child(node.value.right, 1)))
                }

                is ExpressionNode.OrWrapper -> {
                    booleanResult(listOf(child(node.value.left, 0), child(node.value.right, 1)))
                }

                is ExpressionNode.ConditionalWrapper -> {
                    val test = child(node.value.test, 0)
                    requireKind(test, ScalarKind.BOOLEAN)
                    val yes: ExpressionType
                    val no: ExpressionType
                    if (isUntypedEmpty(node.value.yes) && !isUntypedEmpty(node.value.no)) {
                        no = child(node.value.no, 2)
                        yes = contextualEmpty(node.value.yes, no) ?: child(node.value.yes, 1)
                    } else {
                        yes = child(node.value.yes, 1)
                        no = contextualEmpty(node.value.no, yes) ?: child(node.value.no, 2)
                    }
                    withMissing(join(yes, no), test.mayBeMissing || yes.mayBeMissing || no.mayBeMissing)
                }

                is ExpressionNode.OrElseWrapper -> {
                    val input = child(node.value.input, 0)
                    val fallback = contextualEmpty(node.value.fallback, input) ?: child(node.value.fallback, 1)
                    val shape = canonical(input)
                    if (shape.value == ExpressionValueType.NULL_VALUE) {
                        fallback
                    } else {
                        val nonnull = (shape.value as? ExpressionValueType.NullableWrapper)?.value ?: shape
                        val joined = join(withMissing(nonnull, false), fallback)
                        if (input.mayBeMissing ||
                            shape.value is ExpressionValueType.NullableWrapper
                        ) {
                            withMissing(joined, fallback.mayBeMissing)
                        } else {
                            withMissing(input, false)
                        }
                    }
                }

                is ExpressionNode.MapWrapper -> {
                    val (input, body) = unary(node.value.source, node.value.body)
                    listExpressionType(
                        body,
                        input.mayBeMissing || body.mayBeMissing,
                    )
                }

                is ExpressionNode.FlatMapWrapper -> {
                    val (input, body) = unary(node.value.source, node.value.body)
                    listExpressionType(
                        collectionItem(body),
                        input.mayBeMissing || body.mayBeMissing,
                    )
                }

                is ExpressionNode.GroupByWrapper -> {
                    val input = child(node.value.source, 0)
                    val item = collectionItem(input)
                    val key = infer(node.value.body, frames + listOf(listOf(item)), occurrence.child(1))
                    mapExpressionType(key, listExpressionType(item), input.mayBeMissing || key.mayBeMissing)
                }

                is ExpressionNode.FoldWrapper -> {
                    val input = child(node.value.source, 0)
                    val initial = child(node.value.initial, 1)
                    val body = infer(node.value.body, frames + listOf(listOf(initial, collectionItem(input))), occurrence.child(2))
                    demand(compatible(body, initial), "incompatible_expression_accumulator")
                    withMissing(join(initial, body), input.mayBeMissing || initial.mayBeMissing || body.mayBeMissing)
                }

                is ExpressionNode.ReduceWrapper -> {
                    val input = child(node.value.source, 0)
                    val item = collectionItem(input)
                    val body = infer(node.value.body, frames + listOf(listOf(item, item)), occurrence.child(1))
                    demand(compatible(body, item), "incompatible_expression_accumulator")
                    withMissing(nullable(join(item, body)), input.mayBeMissing || body.mayBeMissing)
                }

                is ExpressionNode.SortWithWrapper -> {
                    val input = child(node.value.source, 0)
                    val item = collectionItem(input)
                    val body = infer(node.value.comparator, frames + listOf(listOf(item, item)), occurrence.child(1))
                    requireNumber(body)
                    withMissing(input, input.mayBeMissing || body.mayBeMissing)
                }

                is ExpressionNode.SortByWrapper -> {
                    val input = child(node.value.source, 0)
                    val item = collectionItem(input)
                    val order = node.value.descending?.let { child(it, 1).also { requireKind(it, ScalarKind.BOOLEAN) } }
                    val key = infer(node.value.key, frames + listOf(listOf(item)), occurrence.child(2))
                    demand(scalarKind(key) is ScalarKind.TEXT || numericFamily(key) != null, "invalid_collection_sort_key")
                    withMissing(input, input.mayBeMissing || key.mayBeMissing || order?.mayBeMissing == true)
                }

                is ExpressionNode.QueryWrapper -> {
                    query(node.value, frames, occurrence)
                }

                else -> {
                    val children = node.children()
                    val bodyEdge = children.firstOrNull { it.frameArity == 1 }
                    if (bodyEdge != null) {
                        val input = child(children.first { it.index == 0 }.node, 0)
                        val item = collectionItem(input)
                        val body = infer(bodyEdge.node, frames + listOf(listOf(item)), occurrence.child(bodyEdge.index))
                        unaryResult(node, input, body)
                    } else {
                        scalarResult(node, children.map { child(it.node, it.index) })
                    }
                }
            }
        }

        private fun untypedEmpty(node: ExpressionNode): DataValue? {
            val raw = (node as? ExpressionNode.LiteralWrapper)?.value ?: return null
            val value = raw.portableOrNull() ?: return null
            return when (value) {
                is DataValue.ListValueWrapper -> value.takeIf { it.items.isEmpty() }
                is DataValue.SetValueWrapper -> value.takeIf { it.items.isEmpty() }
                is DataValue.MapValueWrapper -> value.takeIf { it.rows.isEmpty() }
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
            val use = known.nominalUseOrNull()
            val matches =
                when (empty) {
                    is DataValue.ListValueWrapper -> known.value is ExpressionValueType.ListWrapper
                    is DataValue.MapValueWrapper -> known.value is ExpressionValueType.MapWrapper
                    is DataValue.SetValueWrapper -> use is TypeUse.NamedWrapper && use.value.definition == StandardTypes.set
                    else -> false
                }
            return if (matches) withMissing(known, false) else null
        }

        private fun inputType(
            id: String,
            path: ValuePath,
        ): ExpressionType {
            val key = ExpressionBindingId(id)
            val selection = partialBindings[key]
            if (selection == null) {
                val input = bindings[key] ?: fail("unknown_expression_binding")
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
            val field = path.segments.firstOrNull() as? PathSegment.FieldWrapper ?: fail("invalid_expression_path")
            val schema =
                when (val resolved = resolvePartial?.invoke(selection)) {
                    is Resolution.Ready -> resolved.value
                    else -> fail("invalid_expression_path")
                }
            val known = schema.knownFields.singleOrNull { it.key == field.name } ?: fail("invalid_expression_path")
            return project(nominalExpressionType(known.type, missing), ValuePath(segments = path.segments.drop(1)))
        }

        private fun inferProjection(
            node: ExpressionNode,
            suffix: ValuePath,
            frames: List<List<ExpressionType>>,
            occurrence: ExpressionOccurrence,
        ): ExpressionType =
            when (node) {
                is ExpressionNode.FieldWrapper -> {
                    inferProjection(
                        node.value.source,
                        ValuePath(segments = listOf(PathSegment.createField(name = node.value.name)) + suffix.segments),
                        frames,
                        occurrence.child(0),
                    )
                }

                is ExpressionNode.EntryProjectionWrapper -> {
                    val segment =
                        when (node.value.branch) {
                            EntryBranch.KEY -> PathSegment.MAP_KEY
                            EntryBranch.VALUE -> PathSegment.MAP_VALUE
                            else -> fail("unknown_expression_operation")
                        }
                    inferProjection(node.value.source, ValuePath(segments = listOf(segment) + suffix.segments), frames, occurrence.child(0))
                }

                is ExpressionNode.InputWrapper -> {
                    inputType(
                        node.value.binding.value,
                        ValuePath(segments = decodePath(node.value.path).segments + suffix.segments),
                    )
                }

                is ExpressionNode.LocalWrapper -> {
                    project(
                        frameValue(frames, node.value.depth, node.value.slot),
                        ValuePath(segments = decodePath(node.value.path).segments + suffix.segments),
                    )
                }

                else -> {
                    project(infer(node, frames, occurrence), suffix)
                }
            }

        private fun unaryResult(
            node: ExpressionNode,
            input: ExpressionType,
            body: ExpressionType,
        ): ExpressionType {
            val missing = input.mayBeMissing || body.mayBeMissing
            return when (node) {
                is ExpressionNode.AnyWrapper, is ExpressionNode.AllWrapper, is ExpressionNode.NoneWrapper -> {
                    requireKind(body, ScalarKind.BOOLEAN)
                    boolean(missing)
                }

                is ExpressionNode.FilterWrapper -> {
                    requireKind(body, ScalarKind.BOOLEAN)
                    withMissing(input, missing)
                }

                is ExpressionNode.FindWrapper, is ExpressionNode.FindLastWrapper -> {
                    requireKind(body, ScalarKind.BOOLEAN)
                    withMissing(nullable(collectionItem(input)), missing)
                }

                is ExpressionNode.CountWrapper -> {
                    requireKind(body, ScalarKind.BOOLEAN)
                    integer(missing)
                }

                is ExpressionNode.UniqueByWrapper -> {
                    boolean(missing)
                }

                is ExpressionNode.DistinctByWrapper -> {
                    withMissing(input, missing)
                }

                else -> {
                    fail("unknown_expression_operation")
                }
            }
        }

        private fun requireKind(
            type: ExpressionType,
            kind: ScalarKind,
        ) {
            val actual = scalarKind(type)
            demand(
                if (kind is ScalarKind.IntegerWrapper) actual is ScalarKind.IntegerWrapper else actual == kind,
                "invalid_expression_operand_type",
            )
        }

        private fun requireNumber(type: ExpressionType) = demand(numericFamily(type) != null, "invalid_expression_operand_type")

        private fun booleanResult(values: List<ExpressionType>): ExpressionType {
            values.forEach { requireKind(it, ScalarKind.BOOLEAN) }
            return boolean(values.any { it.mayBeMissing })
        }

        private fun requireSized(type: ExpressionType) {
            if (scalarKind(type) in setOf(ScalarKind.TEXT, ScalarKind.BYTES)) return
            collectionItem(type)
        }

        private fun sameNumbers(values: List<ExpressionType>): ExpressionType {
            values.forEach(::requireNumber)
            demand(values.map(::numericFamily).distinct().size == 1, "numeric_family_mismatch")
            return values.reduce(::join)
        }

        private fun mappingTypes(type: ExpressionType): ExpressionMappingType? =
            when (val shape = canonical(type).value) {
                is ExpressionValueType.MapWrapper -> {
                    shape.value
                }

                is ExpressionValueType.NominalWrapper -> {
                    val use = type.nominalUseOrNull() ?: fail("invalid_expression_type")
                    val mapping = ready(use).schema.representation as? ResolvedRepresentation.MappingWrapper
                    mapping?.let {
                        ExpressionMappingType(
                            key = nominalExpressionType(it.value.key),
                            value = nominalExpressionType(it.value.value),
                        )
                    }
                }

                else -> {
                    null
                }
            }

        private fun scalarResult(
            node: ExpressionNode,
            args: List<ExpressionType>,
        ): ExpressionType {
            val missing = args.any { it.mayBeMissing }

            fun kinds(vararg kinds: ScalarKind) = kinds.forEachIndexed { index, kind -> requireKind(args[index], kind) }

            fun numbers() = sameNumbers(args)
            val integerKind = integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR)
            val result =
                when (node) {
                    is ExpressionNode.IsNullWrapper -> {
                        boolean()
                    }

                    is ExpressionNode.LinkTargetWrapper -> {
                        val use = args.single().nominalUseOrNull() ?: fail("invalid_expression_operand_type")
                        demand(ready(use).schema.representation is ResolvedRepresentation.LinkWrapper, "invalid_expression_operand_type")
                        nominalExpressionType(ResourceIdDefinition.use.use)
                    }

                    is ExpressionNode.BooleanNotWrapper -> {
                        kinds(ScalarKind.BOOLEAN)
                        boolean()
                    }

                    is ExpressionNode.ValueCompareWrapper -> {
                        demand(node.value.operation != ValueCompareOperation.UNKNOWN, "unknown_expression_operation")
                        join(args[0], args[1])
                        boolean()
                    }

                    is ExpressionNode.TextUnaryWrapper -> {
                        demand(node.value.operation != TextUnaryOperation.UNKNOWN, "unknown_expression_operation")
                        kinds(ScalarKind.TEXT)
                        text()
                    }

                    is ExpressionNode.TextCompareWrapper -> {
                        demand(node.value.operation != TextCompareOperation.UNKNOWN, "unknown_expression_operation")
                        kinds(ScalarKind.TEXT, ScalarKind.TEXT)
                        boolean()
                    }

                    is ExpressionNode.TextLengthWrapper -> {
                        kinds(ScalarKind.TEXT)
                        integer()
                    }

                    is ExpressionNode.TextHasLineBreakWrapper -> {
                        kinds(ScalarKind.TEXT)
                        boolean()
                    }

                    is ExpressionNode.TextReplaceWrapper, is ExpressionNode.RegexReplaceWrapper -> {
                        kinds(ScalarKind.TEXT, ScalarKind.TEXT, ScalarKind.TEXT)
                        text()
                    }

                    is ExpressionNode.TextSplitWrapper -> {
                        kinds(ScalarKind.TEXT, ScalarKind.TEXT)
                        listExpressionType(text())
                    }

                    is ExpressionNode.TextJoinWrapper -> {
                        requireKind(collectionItem(args[0]), ScalarKind.TEXT)
                        requireKind(args[1], ScalarKind.TEXT)
                        text()
                    }

                    is ExpressionNode.TextSubstringWrapper -> {
                        kinds(ScalarKind.TEXT, integerKind)
                        args.drop(2).forEach { requireKind(it, integerKind) }
                        text()
                    }

                    is ExpressionNode.TextInterpolateWrapper -> {
                        text()
                    }

                    is ExpressionNode.RegexTestWrapper -> {
                        demand(node.value.mode != RegexMatchMode.UNKNOWN, "unknown_expression_operation")
                        kinds(ScalarKind.TEXT, ScalarKind.TEXT)
                        boolean()
                    }

                    is ExpressionNode.RegexCaptureWrapper -> {
                        kinds(ScalarKind.TEXT, ScalarKind.TEXT, integerKind)
                        text()
                    }

                    is ExpressionNode.NumberArithmeticWrapper -> {
                        demand(node.value.operation != NumberArithmeticOperation.UNKNOWN, "unknown_expression_operation")
                        numbers()
                    }

                    is ExpressionNode.NumberCompareWrapper -> {
                        demand(node.value.operation != NumberCompareOperation.UNKNOWN, "unknown_expression_operation")
                        numbers()
                        boolean()
                    }

                    is ExpressionNode.NumberNegateWrapper -> {
                        requireNumber(args.single())
                        args.single()
                    }

                    is ExpressionNode.NumberRoundWrapper -> {
                        val type = sameNumbers(args.take(2))
                        requireKind(args[2], ScalarKind.TEXT)
                        type
                    }

                    is ExpressionNode.NumberFormatWrapper -> {
                        requireNumber(args[0])
                        requireKind(args[1], integerKind)
                        requireKind(args[2], ScalarKind.TEXT)
                        text()
                    }

                    is ExpressionNode.DurationFormatWrapper -> {
                        kinds(ScalarKind.DURATION, ScalarKind.TEXT, integerKind)
                        text()
                    }

                    is ExpressionNode.TimestampFormatWrapper -> {
                        kinds(ScalarKind.TIMESTAMP, ScalarKind.TEXT, ScalarKind.TEXT, ScalarKind.TEXT)
                        text()
                    }

                    is ExpressionNode.CollectionSizeWrapper -> {
                        collectionItem(args.single())
                        integer()
                    }

                    is ExpressionNode.CollectionAccessWrapper -> {
                        val mapping = mappingTypes(args[0])
                        if (mapping != null) {
                            demand(compatible(args[1], mapping.key), "invalid_expression_operand_type")
                            withMissing(mapping.value, true)
                        } else {
                            requireKind(args[1], integerKind)
                            withMissing(collectionItem(args[0]), true)
                        }
                    }

                    is ExpressionNode.CollectionContainsWrapper -> {
                        val expected = mappingTypes(args[0])?.key ?: collectionItem(args[0])
                        demand(compatible(args[1], expected), "invalid_expression_operand_type")
                        boolean()
                    }

                    is ExpressionNode.ColorWithAlphaWrapper -> {
                        kinds(integerKind, integerKind)
                        args.first()
                    }

                    is ExpressionNode.RuleOneOfWrapper -> {
                        args
                            .drop(
                                1,
                            ).forEach { demand(compatible(it, args[0]) || compatible(args[0], it), "invalid_expression_operand_type") }
                        boolean()
                    }

                    is ExpressionNode.RuleUnaryWrapper -> {
                        when (node.value.operation) {
                            RuleUnaryOperation.NON_EMPTY -> requireSized(args.single())
                            RuleUnaryOperation.NON_BLANK, RuleUnaryOperation.SINGLE_LINE -> kinds(ScalarKind.TEXT)
                            RuleUnaryOperation.POSITIVE, RuleUnaryOperation.NON_NEGATIVE -> requireNumber(args.single())
                            RuleUnaryOperation.UNIQUE -> collectionItem(args.single())
                            RuleUnaryOperation.OPAQUE -> kinds(integerKind)
                            RuleUnaryOperation.NOT_NULL -> Unit
                            else -> fail("unknown_expression_operation")
                        }
                        boolean()
                    }

                    is ExpressionNode.RuleSizeBoundWrapper -> {
                        demand(node.value.direction != BoundDirection.UNKNOWN, "unknown_expression_operation")
                        when (node.value.metric) {
                            SizeBoundMetric.TEXT_LENGTH -> requireSized(args[0])
                            SizeBoundMetric.TEXT_LINES -> requireKind(args[0], ScalarKind.TEXT)
                            SizeBoundMetric.COLLECTION_ITEMS -> collectionItem(args[0])
                            else -> fail("unknown_expression_operation")
                        }
                        requireKind(args[1], integerKind)
                        boolean()
                    }

                    is ExpressionNode.RuleSizeRangeWrapper -> {
                        when (node.value.metric) {
                            SizeRangeMetric.TEXT_LENGTH -> requireSized(args[0])
                            SizeRangeMetric.COLLECTION_ITEMS -> collectionItem(args[0])
                            else -> fail("unknown_expression_operation")
                        }
                        args.drop(1).forEach { requireKind(it, integerKind) }
                        boolean()
                    }

                    is ExpressionNode.RuleNumericBoundWrapper -> {
                        demand(node.value.direction != BoundDirection.UNKNOWN, "unknown_expression_operation")
                        sameNumbers(args.take(2))
                        requireKind(args[2], ScalarKind.BOOLEAN)
                        boolean()
                    }

                    is ExpressionNode.RuleNumericRangeWrapper -> {
                        numbers()
                        boolean()
                    }

                    is ExpressionNode.RuleMultipleOfWrapper -> {
                        numbers()
                        boolean()
                    }

                    is ExpressionNode.RuleMaximumScaleWrapper -> {
                        requireNumber(args[0])
                        requireKind(args[1], integerKind)
                        boolean()
                    }

                    is ExpressionNode.RuleTimestampBoundWrapper -> {
                        demand(node.value.direction != TimestampBoundDirection.UNKNOWN, "unknown_expression_operation")
                        kinds(ScalarKind.TIMESTAMP, ScalarKind.TIMESTAMP)
                        boolean()
                    }

                    is ExpressionNode.TakeWrapper, is ExpressionNode.SkipWrapper -> {
                        collectionItem(args[0])
                        requireKind(args[1], integerKind)
                        args[0]
                    }

                    is ExpressionNode.ReverseWrapper, is ExpressionNode.DistinctWrapper -> {
                        collectionItem(args[0])
                        args[0]
                    }

                    else -> {
                        fail("unknown_expression_operation")
                    }
                }
            return withMissing(result, result.mayBeMissing || missing)
        }

        private fun query(
            query: ExpressionQuery,
            frames: List<List<ExpressionType>>,
            occurrence: ExpressionOccurrence,
        ): ExpressionType {
            val source = infer(query.sourceExpression(), frames, occurrence.child(0))
            var target: TypeUse? = null
            var reference = false
            when (val resource = query.resourceSourceOrNull()) {
                is ResourceQuerySource.ReferenceWrapper -> {
                    val use = source.nominalUseOrNull() ?: fail("invalid_resource_reference_query")
                    val link =
                        ready(use).schema.representation as? ResolvedRepresentation.LinkWrapper ?: fail("invalid_resource_reference_query")
                    target = link.value.target
                    reference = true
                }

                is ResourceQuerySource.IdentityWrapper -> {
                    demand(source.nominalUseOrNull() == ResourceIdDefinition.use.use, "resource_query_requires_identity")
                    target =
                        resource.value.target.takeIf { it is TypeUse.NamedWrapper && it.isValid }
                            ?: fail("invalid_resource_query_witness")
                    ready(target)
                }

                null -> {
                    Unit
                }

                else -> {
                    fail("unknown_expression_operation")
                }
            }
            val output =
                when (query) {
                    is ExpressionQuery.ResourceIdentityWrapper -> {
                        ResourceIdDefinition.use.use
                    }

                    is ExpressionQuery.ResourceValueWrapper -> {
                        requireNotNull(target)
                    }

                    is ExpressionQuery.ResourceConfigurationWrapper, is ExpressionQuery.ValueConfigurationWrapper -> {
                        CanonicalReadModels.typeSelection.use.use
                    }

                    is ExpressionQuery.CatalogDeclarationWrapper -> {
                        demand(
                            compatible(source, nominalExpressionType(CanonicalReadModels.typeSelection.use.use)),
                            "catalog_query_requires_selection",
                        )
                        CanonicalReadModels.publishedType.use.use
                    }

                    else -> {
                        fail("unknown_expression_operation")
                    }
                }
            val result = nominalExpressionType(output, true)
            queries[occurrence] = CheckedQueryCall(query.kind, target, result, reference)
            return result
        }
    }
}

private class ExpressionCheckFailure(
    val code: String,
) : RuntimeException(code)

private fun demand(
    condition: Boolean,
    code: String,
) {
    if (!condition) fail(code)
}

private fun fail(code: String): Nothing = throw ExpressionCheckFailure(code)
