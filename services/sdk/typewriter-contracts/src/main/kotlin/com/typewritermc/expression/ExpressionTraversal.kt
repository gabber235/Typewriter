package com.typewritermc.expression

import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionQuery
import skirout.editor.v1.expression.ResourceQuerySource

/** A child occurrence, with the lexical frame introduced only along this edge. */
data class ExpressionChild(
    val index: Int,
    val node: ExpressionNode,
    val frameArity: Int = 0,
)

/** Enumerates syntax children at stable ordinals. Absent optional children leave their ordinal unused. */
fun ExpressionNode.children(): List<ExpressionChild> =
    when (this) {
        is ExpressionNode.LiteralWrapper, is ExpressionNode.InputWrapper, is ExpressionNode.LocalWrapper -> {
            emptyList()
        }

        is ExpressionNode.FieldWrapper -> {
            listOf(ExpressionChild(0, value.source))
        }

        is ExpressionNode.EntryProjectionWrapper -> {
            listOf(ExpressionChild(0, value.source))
        }

        is ExpressionNode.AndWrapper -> {
            listOf(ExpressionChild(0, value.left), ExpressionChild(1, value.right))
        }

        is ExpressionNode.OrWrapper -> {
            listOf(ExpressionChild(0, value.left), ExpressionChild(1, value.right))
        }

        is ExpressionNode.ConditionalWrapper -> {
            listOf(
                ExpressionChild(0, value.test),
                ExpressionChild(1, value.yes),
                ExpressionChild(2, value.no),
            )
        }

        is ExpressionNode.OrElseWrapper -> {
            listOf(ExpressionChild(0, value.input), ExpressionChild(1, value.fallback))
        }

        is ExpressionNode.TextUnaryWrapper -> {
            listOf(ExpressionChild(0, value.source))
        }

        is ExpressionNode.TextCompareWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.other))
        }

        is ExpressionNode.TextLengthWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.TextHasLineBreakWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.TextReplaceWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.target),
                ExpressionChild(2, value.replacement),
            )
        }

        is ExpressionNode.TextSplitWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.separator))
        }

        is ExpressionNode.TextJoinWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.separator))
        }

        is ExpressionNode.RegexTestWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.pattern))
        }

        is ExpressionNode.RegexCaptureWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.pattern),
                ExpressionChild(2, value.group),
            )
        }

        is ExpressionNode.RegexReplaceWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.pattern),
                ExpressionChild(2, value.replacement),
            )
        }

        is ExpressionNode.ValueCompareWrapper -> {
            listOf(ExpressionChild(0, value.left), ExpressionChild(1, value.right))
        }

        is ExpressionNode.IsNullWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.LinkTargetWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.BooleanNotWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.NumberCompareWrapper -> {
            listOf(ExpressionChild(0, value.left), ExpressionChild(1, value.right))
        }

        is ExpressionNode.NumberNegateWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.NumberRoundWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.increment),
                ExpressionChild(2, value.rounding),
            )
        }

        is ExpressionNode.NumberFormatWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.fractionDigits),
                ExpressionChild(2, value.locale),
            )
        }

        is ExpressionNode.DurationFormatWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.units),
                ExpressionChild(2, value.fractionDigits),
            )
        }

        is ExpressionNode.TimestampFormatWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.pattern),
                ExpressionChild(2, value.zone),
                ExpressionChild(3, value.locale),
            )
        }

        is ExpressionNode.CollectionSizeWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.CollectionAccessWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.index))
        }

        is ExpressionNode.CollectionContainsWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.value))
        }

        is ExpressionNode.ColorParseWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.ColorWithAlphaWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.alpha))
        }

        is ExpressionNode.RuleUnaryWrapper -> {
            listOf(ExpressionChild(0, value.source))
        }

        is ExpressionNode.RuleSizeBoundWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.bound))
        }

        is ExpressionNode.RuleSizeRangeWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.minimum),
                ExpressionChild(2, value.maximum),
            )
        }

        is ExpressionNode.RuleNumericBoundWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.bound),
                ExpressionChild(2, value.inclusive),
            )
        }

        is ExpressionNode.RuleNumericRangeWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.minimum),
                ExpressionChild(2, value.maximum),
            )
        }

        is ExpressionNode.RuleMultipleOfWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.divisor))
        }

        is ExpressionNode.RuleMaximumScaleWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.scale))
        }

        is ExpressionNode.RuleTimestampBoundWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.bound))
        }

        is ExpressionNode.TakeWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.count))
        }

        is ExpressionNode.SkipWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.count))
        }

        is ExpressionNode.ReverseWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.DistinctWrapper -> {
            listOf(ExpressionChild(0, value))
        }

        is ExpressionNode.QueryWrapper -> {
            listOf(ExpressionChild(0, value.sourceExpression()))
        }

        is ExpressionNode.AnyWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.AllWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.NoneWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.MapWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.FilterWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.FindWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.FindLastWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.CountWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.DistinctByWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.GroupByWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.FlatMapWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.UniqueByWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 1))
        }

        is ExpressionNode.SortWithWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.comparator, 2))
        }

        is ExpressionNode.ReduceWrapper -> {
            listOf(ExpressionChild(0, value.source), ExpressionChild(1, value.body, 2))
        }

        is ExpressionNode.FoldWrapper -> {
            listOf(
                ExpressionChild(0, value.source),
                ExpressionChild(1, value.initial),
                ExpressionChild(2, value.body, 2),
            )
        }

        is ExpressionNode.SortByWrapper -> {
            listOfNotNull(
                ExpressionChild(0, value.source),
                value.descending?.let {
                    ExpressionChild(1, it)
                },
                ExpressionChild(2, value.key, 1),
            )
        }

        is ExpressionNode.TextSubstringWrapper -> {
            listOfNotNull(
                ExpressionChild(
                    0,
                    value.source,
                ),
                ExpressionChild(1, value.start),
                value.end?.let {
                    ExpressionChild(2, it)
                },
            )
        }

        is ExpressionNode.TextInterpolateWrapper -> {
            value.parts.mapIndexed { index, child -> ExpressionChild(index, child) }
        }

        is ExpressionNode.NumberArithmeticWrapper -> {
            (listOf(value.first, value.second) + value.remaining).mapIndexed {
                index,
                child,
                ->
                ExpressionChild(index, child)
            }
        }

        is ExpressionNode.RuleOneOfWrapper -> {
            (listOf(value.source, value.firstCandidate) + value.remainingCandidates).mapIndexed {
                index,
                child,
                ->
                ExpressionChild(index, child)
            }
        }

        else -> {
            throw IllegalArgumentException("Unknown expression variant")
        }
    }

fun ExpressionQuery.sourceExpression(): ExpressionNode =
    when (this) {
        is ExpressionQuery.ResourceIdentityWrapper -> value.expression()
        is ExpressionQuery.ResourceValueWrapper -> value.expression()
        is ExpressionQuery.ResourceConfigurationWrapper -> value.expression()
        is ExpressionQuery.ValueConfigurationWrapper -> value
        is ExpressionQuery.CatalogDeclarationWrapper -> value
        else -> throw IllegalArgumentException("Unknown expression query")
    }

fun ResourceQuerySource.expression(): ExpressionNode =
    when (this) {
        is ResourceQuerySource.ReferenceWrapper -> value
        is ResourceQuerySource.IdentityWrapper -> value.identity
        else -> throw IllegalArgumentException("Unknown resource query source")
    }

fun ExpressionQuery.resourceSourceOrNull(): ResourceQuerySource? =
    when (this) {
        is ExpressionQuery.ResourceIdentityWrapper -> value
        is ExpressionQuery.ResourceValueWrapper -> value
        is ExpressionQuery.ResourceConfigurationWrapper -> value
        is ExpressionQuery.ValueConfigurationWrapper, is ExpressionQuery.CatalogDeclarationWrapper -> null
        else -> throw IllegalArgumentException("Unknown expression query")
    }
