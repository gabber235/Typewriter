@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.PortableValue
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.ConfigurationCollectionScope
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.Integer
import com.typewritermc.configuration.NestedConfigurationScope
import com.typewritermc.configuration.NullableField
import com.typewritermc.configuration.Text
import com.typewritermc.configuration.field
import com.typewritermc.configuration.name
import com.typewritermc.configuration.root
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.EvaluationBudget
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.PortableExpressionLimits
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.expression.testInput
import com.typewritermc.expression.testLiteral
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.of
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.GeneratedScalarNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.of
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import kotlin.reflect.KClass

val SdkRuntimeConformanceTest by testSuite {
    test("unannotated relation endpoints clear links") {
        com.typewritermc.library.BookTags.contract.first.onDelete shouldBe RelationDeletePolicy.CLEAR
        com.typewritermc.library.BookTags.contract.second.onDelete shouldBe RelationDeletePolicy.CLEAR
        com.typewritermc.library.TagParents.contract.first.onDelete shouldBe RelationDeletePolicy.CLEAR
        com.typewritermc.library.TagParents.contract.second.onDelete shouldBe RelationDeletePolicy.CLEAR
    }

    test("generated resource selection compiles typed predicates and evaluates configured value reads") {
        val selection =
            com.typewritermc.library.BookDraftType
                .where { title eq literal("Requested") }
        val predicate = requireNotNull(selection.predicate)
        val location =
            ValueLocation.of(
                ResourceId("book:requested"),
                ValuePath.root,
            )
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { DataValue.StringValueWrapper("Requested").available() })

        with(EmptyReads) {
            evaluator.evaluate(
                predicate,
                ExpressionBindings(mapOf(ExpressionBindingId("configured_value") to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        }
    }

    fun localNode(path: ValuePath) =
        ExpressionNode.createLocal(
            depth = 0,
            slot = 0,
            path =
            path,
        )

    test("portable evaluation short circuits fallback and preserves named scalar semantics") {
        val location = ValueLocation.of(ResourceId("expression:test"))
        val binding = ExpressionBindingId("value")
        var reads = 0
        var result: Availability<DataValue> = Availability.Unavailable(listOf(location))
        val evaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader {
                    reads += 1
                    result
                },
            )
        val bindings = ExpressionBindings(mapOf(binding to location))
        val budget = EvaluationBudget(100, 100)
        val read = testInput(binding, ValuePath.root)

        with(EmptyReads) {
            evaluator.evaluate(
                ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(false)), right = read),
                bindings,
                budget,
            ) shouldBe
                Availability.Available(DataValue.BooleanWrapper(false))
            reads shouldBe 0
            evaluator.evaluate(
                ExpressionNode.createOrElse(input = read, fallback = testLiteral(DataValue.StringValueWrapper("fallback"))),
                bindings,
                budget,
            ) shouldBe Availability.Available(DataValue.StringValueWrapper("fallback"))
            result = DataValue.named(TEST_CODE_USE, DataValue.StringValueWrapper("chapter")).available()
            evaluator.evaluate(
                ExpressionNode.createRuleUnary(operation = skirout.editor.v1.expression.RuleUnaryOperation.NON_BLANK, source = read),
                bindings,
                budget,
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
            result = Availability.Failed(EvaluationDiagnostic("read_failed", "broken", listOf(location)))
            evaluator.evaluate(
                ExpressionNode.createOrElse(input = read, fallback = testLiteral(DataValue.StringValueWrapper("hidden"))),
                bindings,
                budget,
            ) shouldBe result
        }
    }

    test("portable evaluation bounds expression depth without evaluating a short circuited branch") {
        var nested: ExpressionNode = testLiteral(DataValue.BooleanWrapper(true))
        repeat(PortableExpressionLimits.MAX_DEPTH + 1) {
            nested = ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(true)), right = nested)
        }
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })
        with(EmptyReads) {
            val failed = evaluator.evaluate(nested, ExpressionBindings(emptyMap()), EvaluationBudget(100_000, 100))
            (failed as Availability.Failed).diagnostic.code shouldBe "expression_depth_limit"
            evaluator.evaluate(
                ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(false)), right = nested),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(100_000, 100),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
        }
    }

    test("portable whitespace includes Unicode whitespace and BOM but excludes information separator") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        fun nonBlank(value: String) =
            ExpressionNode.createRuleUnary(
                operation = skirout.editor.v1.expression.RuleUnaryOperation.NON_BLANK,
                source = testLiteral(DataValue.StringValueWrapper(value)),
            )

        fun trim(value: String) =
            ExpressionNode.createTextUnary(
                operation = skirout.editor.v1.expression.TextUnaryOperation.TRIM,
                source = testLiteral(DataValue.StringValueWrapper(value)),
            )

        with(EmptyReads) {
            listOf("\uFEFF", "\u0085", "\u00A0", "\u2007").forEach { whitespace ->
                evaluator.evaluate(
                    nonBlank(whitespace),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(10, 0),
                ) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
            }
            evaluator.evaluate(
                nonBlank("\u001C"),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(10, 0),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
            evaluator.evaluate(
                trim("\uFEFF value \u0085"),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(10, 0),
            ) shouldBe Availability.Available(DataValue.StringValueWrapper("value"))
        }
    }

    test("portable regular expressions reject host specific and unsafe declaration syntax") {
        val scope = DefaultConfigurationCollectionScope(TEST_CODE_ID)
        textField(scope, RelativeFieldPattern.root, ScalarKind.TEXT.template).regex("[a-z]+:[a-z]+")

        listOf(
            "\\Qliteral\\E",
            "a++",
            "[a-z&&[^b]]",
            "(a+)+",
            "(a)\\1",
            "(?=a)a",
            "a+a+",
            "\\v",
            "[\\v]",
            "[\\S]",
            "a^*",
            "a$*",
        ).forEach { pattern ->
            shouldThrow<IllegalArgumentException> {
                textField(DefaultConfigurationCollectionScope(TEST_CODE_ID), RelativeFieldPattern.root, ScalarKind.TEXT.template)
                    .regex(pattern)
            }
        }
    }

    test("portable regular expressions normalize whitespace and Unicode dot semantics") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        fun fullMatch(
            value: String,
            pattern: String,
        ) = ExpressionNode.createRegexTest(
            mode = skirout.editor.v1.expression.RegexMatchMode.FULL_MATCH,
            source = testLiteral(DataValue.StringValueWrapper(value)),
            pattern = testLiteral(DataValue.StringValueWrapper(pattern)),
        )

        with(EmptyReads) {
            evaluator.evaluate(fullMatch("\u00A0", "\\s"), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.BooleanWrapper(true))
            evaluator.evaluate(fullMatch("\u00A0", "[\\s]"), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.BooleanWrapper(true))
            evaluator.evaluate(fullMatch("😀", "."), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.BooleanWrapper(true))
            evaluator.evaluate(fullMatch("\u0085", "."), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.BooleanWrapper(true))
            evaluator.evaluate(fullMatch("\n", "."), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.BooleanWrapper(false))
        }
    }

    test("portable regular expressions charge search and replacement output to the step budget") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        fun search(
            source: String,
            pattern: String,
        ) = ExpressionNode.createRegexTest(
            mode = skirout.editor.v1.expression.RegexMatchMode.SEARCH,
            source = testLiteral(DataValue.StringValueWrapper(source)),
            pattern = testLiteral(DataValue.StringValueWrapper(pattern)),
        )

        fun replace(
            source: String,
            pattern: String,
            replacement: String,
        ) = ExpressionNode.createRegexReplace(
            source = testLiteral(DataValue.StringValueWrapper(source)),
            pattern = testLiteral(DataValue.StringValueWrapper(pattern)),
            replacement = testLiteral(DataValue.StringValueWrapper(replacement)),
        )

        with(EmptyReads) {
            val anchorSearch =
                evaluator.evaluate(
                    search("x".repeat(200), "^$"),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(50, 0),
                )
            (anchorSearch as Availability.Failed).diagnostic.code shouldBe "expression_step_limit"

            val replacementOutput =
                evaluator.evaluate(
                    replace("", "", "replacement".repeat(20)),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(30, 0),
                )
            (replacementOutput as Availability.Failed).diagnostic.code shouldBe "expression_step_limit"
        }
    }

    test("portable text expansion uses character boundaries and evaluator budgets") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        context(reads: AuthoredReads)
        fun replace(
            values: List<DataValue>,
            budget: EvaluationBudget = EvaluationBudget(100, 100),
        ): Availability<DataValue> =
            evaluator.evaluate(
                ExpressionNode.createTextReplace(
                    source = testLiteral(values[0]),
                    target = testLiteral(values[1]),
                    replacement = testLiteral(values[2]),
                ),
                ExpressionBindings(emptyMap()),
                budget,
            )

        context(reads: AuthoredReads)
        fun split(
            values: List<DataValue>,
            budget: EvaluationBudget = EvaluationBudget(100, 100),
        ): Availability<DataValue> =
            evaluator.evaluate(
                ExpressionNode.createTextSplit(source = testLiteral(values[0]), separator = testLiteral(values[1])),
                ExpressionBindings(emptyMap()),
                budget,
            )

        context(reads: AuthoredReads)
        fun join(
            values: List<DataValue>,
            budget: EvaluationBudget = EvaluationBudget(100, 100),
        ): Availability<DataValue> =
            evaluator.evaluate(
                ExpressionNode.createTextJoin(source = testLiteral(values[0]), separator = testLiteral(values[1])),
                ExpressionBindings(emptyMap()),
                budget,
            )

        context(reads: AuthoredReads)
        fun interpolate(
            values: List<DataValue>,
            budget: EvaluationBudget = EvaluationBudget(100, 100),
        ): Availability<DataValue> =
            evaluator.evaluate(
                ExpressionNode.createTextInterpolate(parts = values.map(::testLiteral)),
                ExpressionBindings(emptyMap()),
                budget,
            )

        with(EmptyReads) {
            replace(
                listOf(DataValue.StringValueWrapper("😀"), DataValue.StringValueWrapper(""), DataValue.StringValueWrapper("_")),
            ) shouldBe Availability.Available(DataValue.StringValueWrapper("_😀_"))

            split(
                listOf(DataValue.StringValueWrapper("😀x"), DataValue.StringValueWrapper("")),
            ) shouldBe
                Availability.Available(
                    DataValue.listValue(
                        listOf(
                            skirout.editor.v1.type_catalog.ListItem(
                                id =
                                    skirout.editor.v1.type_catalog
                                        .ItemId(value = "split.0"),
                                value = DataValue.StringValueWrapper("😀"),
                            ),
                            skirout.editor.v1.type_catalog.ListItem(
                                id =
                                    skirout.editor.v1.type_catalog
                                        .ItemId(value = "split.1"),
                                value = DataValue.StringValueWrapper("x"),
                            ),
                        ),
                    ),
                )
            split(
                listOf(DataValue.StringValueWrapper(""), DataValue.StringValueWrapper("")),
            ) shouldBe Availability.Available(DataValue.listValue(emptyList()))

            val large = DataValue.StringValueWrapper("value".repeat(20))
            listOf(
                replace(
                    listOf(DataValue.StringValueWrapper("a"), DataValue.StringValueWrapper(""), large),
                    EvaluationBudget(30, 100),
                ),
                join(
                    listOf(
                        DataValue.listValue(
                            listOf(
                                skirout.editor.v1.type_catalog.ListItem(
                                    id =
                                        skirout.editor.v1.type_catalog
                                            .ItemId(value = "only"),
                                    value = large,
                                ),
                            ),
                        ),
                        DataValue.StringValueWrapper(""),
                    ),
                    EvaluationBudget(30, 100),
                ),
                interpolate(
                    listOf(large),
                    EvaluationBudget(30, 100),
                ),
            ).forEach { result ->
                (result as Availability.Failed).diagnostic.code shouldBe "expression_step_limit"
            }

            val splitLimit =
                split(
                    listOf(DataValue.StringValueWrapper("😀x"), DataValue.StringValueWrapper("")),
                    EvaluationBudget(100, 1),
                )
            (splitLimit as Availability.Failed).diagnostic.code shouldBe "expression_collection_limit"
        }
    }

    test("collection evaluation uses semantic equality propagates unfinished members and counts visited items") {
        val location = ValueLocation.of(ResourceId("collection:test"))
        val binding = ExpressionBindingId("items")
        val item = ExpressionBindingId("item")
        var value: DataValue =
            DataValue.listValue(
                listOf(
                    skirout.editor.v1.type_catalog.ListItem(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "first"),
                        value = DataValue.StringValueWrapper("same"),
                    ),
                    skirout.editor.v1.type_catalog.ListItem(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "second"),
                        value = DataValue.StringValueWrapper("same"),
                    ),
                ),
            )
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { value.available() })
        val bindings = ExpressionBindings(mapOf(binding to location))
        val input = testInput(binding, ValuePath.root)
        with(EmptyReads) {
            evaluator.evaluate(
                ExpressionNode.createRuleUnary(operation = skirout.editor.v1.expression.RuleUnaryOperation.UNIQUE, source = input),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
            value =
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "unfinished"),
                            value = DataValue.record(mapOf("valid" to DataValue.UNFILLED)),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.createUniqueBy(source = input, body = localNode(ValuePath.root)),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe
                Availability.Unavailable(
                    listOf(
                        location.copy(
                            path =
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createItem(
                                                id =
                                                    skirout.editor.v1.type_catalog
                                                        .ItemId(value = "unfinished"),
                                            ),
                                        ),
                                ),
                        ),
                    ),
                )

            value =
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "known one"),
                            value = DataValue.StringValueWrapper("same"),
                        ),
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "known two"),
                            value = DataValue.StringValueWrapper("same"),
                        ),
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "unfinished"),
                            value = DataValue.record(mapOf("valid" to DataValue.UNFILLED)),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.CollectionSizeWrapper(input),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe Availability.Available(DataValue.integer(3.toBigInteger()))
            evaluator.evaluate(
                ExpressionNode.createRuleUnary(operation = skirout.editor.v1.expression.RuleUnaryOperation.UNIQUE, source = input),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
            value =
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "unfinished"),
                            value = DataValue.record(mapOf("valid" to DataValue.UNFILLED)),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.createAny(
                    source = input,
                    body =
                        localNode(
                            ValuePath(
                                segments =
                                    listOf(
                                        PathSegment.createField(name = "valid"),
                                    ),
                            ),
                        ),
                ),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe
                Availability.Unavailable(
                    listOf(
                        location.copy(
                            path =
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createItem(
                                                id =
                                                    skirout.editor.v1.type_catalog
                                                        .ItemId(value = "unfinished"),
                                            ),
                                            PathSegment.createField(name = "valid"),
                                        ),
                                ),
                        ),
                    ),
                )

            value =
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "yes"),
                            value = DataValue.BooleanWrapper(true),
                        ),
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "no"),
                            value = DataValue.BooleanWrapper(false),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.createAny(source = input, body = localNode(ValuePath.root)),
                bindings,
                EvaluationBudget(100, 1),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        }
    }

    test("map access preserves named key identity and retains unfinished key uncertainty") {
        val location = ValueLocation.of(ResourceId("map:test"))
        val binding = ExpressionBindingId("map")
        var value: DataValue = DataValue.mapValue(emptyList())
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { value.available() })
        val input = testInput(binding, ValuePath.root)

        fun access(key: DataValue) = ExpressionNode.createCollectionAccess(source = input, index = testLiteral(key))

        value =
            DataValue.mapValue(
                listOf(
                    skirout.editor.v1.type_catalog.MapRow(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "target"),
                        key = DataValue.StringValueWrapper("target"),
                        value = DataValue.StringValueWrapper("available"),
                    ),
                    skirout.editor.v1.type_catalog.MapRow(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "duplicate one"),
                        key = DataValue.StringValueWrapper("duplicate"),
                        value = DataValue.StringValueWrapper("one"),
                    ),
                    skirout.editor.v1.type_catalog.MapRow(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "duplicate two"),
                        key = DataValue.StringValueWrapper("duplicate"),
                        value = DataValue.StringValueWrapper("two"),
                    ),
                    skirout.editor.v1.type_catalog.MapRow(
                        id =
                            skirout.editor.v1.type_catalog
                                .ItemId(value = "unfinished"),
                        key = DataValue.UNFILLED,
                        value = DataValue.UNFILLED,
                    ),
                ),
            )
        with(EmptyReads) {
            evaluator.evaluate(
                access(DataValue.StringValueWrapper("target")),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe
                Availability.Unavailable(
                    listOf(
                        location.copy(
                            path =
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createItem(
                                                id =
                                                    skirout.editor.v1.type_catalog
                                                        .ItemId(value = "target"),
                                            ),
                                            PathSegment.MAP_VALUE,
                                        ),
                                ),
                        ),
                        location.copy(
                            path =
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createItem(
                                                id =
                                                    skirout.editor.v1.type_catalog
                                                        .ItemId(value = "unfinished"),
                                            ),
                                            PathSegment.MAP_KEY,
                                        ),
                                ),
                        ),
                    ),
                )

            value =
                DataValue.mapValue(
                    (value as DataValue.MapValueWrapper).rows.map { row ->
                        if (row.id.value == "unfinished") row.copy(key = DataValue.StringValueWrapper("other")) else row
                    },
                )
            evaluator.evaluate(
                access(DataValue.StringValueWrapper("target")),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.StringValueWrapper("available"))

            val namedKey = DataValue.named(TEST_CODE_USE, DataValue.StringValueWrapper("wrapped"))
            value =
                DataValue.mapValue(
                    listOf(
                        skirout.editor.v1.type_catalog.MapRow(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "named"),
                            key = namedKey,
                            value = DataValue.StringValueWrapper("named value"),
                        ),
                    ),
                )
            evaluator.evaluate(
                access(namedKey),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.StringValueWrapper("named value"))

            value =
                DataValue.mapValue(
                    listOf(
                        skirout.editor.v1.type_catalog.MapRow(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "first"),
                            key = DataValue.StringValueWrapper("same"),
                            value = DataValue.StringValueWrapper("one"),
                        ),
                        skirout.editor.v1.type_catalog.MapRow(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "second"),
                            key = DataValue.StringValueWrapper("same"),
                            value = DataValue.StringValueWrapper("two"),
                        ),
                    ),
                )
            evaluator.evaluate(
                access(DataValue.StringValueWrapper("same")),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe
                Availability.Unavailable(
                    listOf("first", "second").map { id ->
                        location.copy(
                            path =
                                ValuePath(
                                    segments =
                                        listOf(
                                            PathSegment.createItem(
                                                id =
                                                    skirout.editor.v1.type_catalog
                                                        .ItemId(value = id),
                                            ),
                                            PathSegment.MAP_VALUE,
                                        ),
                                ),
                        )
                    },
                )
        }
    }

    test("portable helpers execute and native checks receive exact primitive and named scalar receivers") {
        val origin = providerOrigin("typed_checks")
        val counter = recordDefinition("Counter", "count", INT)
        val counterProvider =
            object : ConfigurationProvider {
                override fun collect(scope: ConfigurationCollectionScope): com.typewritermc.configuration.CollectedConfiguration {
                    integerField(scope, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count"))))
                        .check { it > 0 }
                        .error("positive count")
                    return scope.collected()
                }
            }
        val chapterProvider =
            object : ConfigurationProvider {
                override fun collect(scope: ConfigurationCollectionScope): com.typewritermc.configuration.CollectedConfiguration {
                    textField(scope, RelativeFieldPattern.root, ScalarKind.TEXT.template)
                        .check { it.isNotBlank() }
                        .error("nonblank code")
                    return scope.collected()
                }
            }
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin, counter),
                        OwnedTypeDeclaration(origin, TEST_CODE_DEFINITION),
                    ),
                configurations =
                    listOf(
                        OwnedConfiguration(origin, counter.id, counterProvider),
                        OwnedConfiguration(origin, TEST_CODE_ID, chapterProvider),
                    ),
                nativeBindings = listOf(OwnedNativeBinding(origin, TestCodeNativeBindingFactory)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "typed checks")))
        val integer =
            assembly.checked
                .resolve(INT_USE)
                .ready()
                .complete(DataValue.integer(5.toBigInteger()))
                .complete()
        val chapterUse = TEST_CODE_USE
        val chapter =
            assembly.checked
                .resolve(chapterUse.use)
                .ready()
                .complete(DataValue.named(chapterUse, DataValue.StringValueWrapper("chapter")))
                .complete()

        assembly.checks
            .single { it.recipe.owner.owner == counter.id }
            .recipe.predicate
            .invoke(listOf(integer)) shouldBe true
        val chapterCheck = assembly.checks.single { it.recipe.owner.owner == TEST_CODE_ID }.recipe
        chapterCheck.inputs.single().expected shouldBe ScalarKind.TEXT.template
        chapterCheck.predicate.invoke(listOf(chapter)) shouldBe true

        val helpers = DefaultConfigurationCollectionScope(counter.id)
        integerField(helpers, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count")))).minimum(3)
        val rule =
            helpers
                .collected()
                .recipes
                .single()
                .rules
                .single()
                .descriptor.predicate
        val configured = ExpressionBindingId("configured_value")
        val location = ValueLocation.of(ResourceId("counter:1"))
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { DataValue.integer(5.toBigInteger()).available() })
        with(EmptyReads) {
            evaluator.evaluate(rule, ExpressionBindings(mapOf(configured to location)), EvaluationBudget(100, 100)) shouldBe
                Availability.Available(DataValue.BooleanWrapper(true))
        }

        val unsigned = DefaultConfigurationCollectionScope(counter.id)
        unsignedIntegerField(unsigned, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count"))))
            .minimum(ULong.MAX_VALUE - 1uL)
        val unsignedRule =
            unsigned
                .collected()
                .recipes
                .single()
                .rules
                .single()
                .descriptor.predicate
        val unsignedEvaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader { DataValue.integer(ULong.MAX_VALUE.toString().toBigInteger()).available() },
            )
        with(EmptyReads) {
            unsignedEvaluator.evaluate(
                unsignedRule,
                ExpressionBindings(mapOf(configured to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        }
    }

    test("nullable scalar and nested record configuration retain physical authored paths") {
        val owner = definitionId("Nullable")
        val scalar = DefaultConfigurationCollectionScope(owner)
        nullableTextField(scalar, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("text")))).whenPresent {
            nonBlank()
            check { it.isNotBlank() }.error("present text is nonblank")
        }
        val scalarConfiguration = scalar.collected()
        scalarConfiguration.recipes
            .single()
            .relativePath.segments shouldBe listOf(FieldPatternSegment.field("text"))
        scalarConfiguration.checks
            .single()
            .inputs
            .single()
            .skipNull shouldBe true

        val nested = DefaultConfigurationCollectionScope(owner)
        integerField(
            nested.nested(RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("style")))),
            RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("repetitions"))),
        ).check { it > 0 }.error("present repetitions are positive")
        nested
            .collected()
            .checks
            .single()
            .inputs
            .single()
            .path.segments shouldBe
            listOf(FieldPatternSegment.field("style"), FieldPatternSegment.field("repetitions"))
    }

    test("abstract native fields collections and nullable values dispatch by concrete type tag") {
        val origin = providerOrigin("polymorphic_native")
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin, TEST_MESSAGE_DEFINITION),
                        OwnedTypeDeclaration(origin, TEST_TEXT_MESSAGE_DEFINITION),
                        OwnedTypeDeclaration(origin, TEST_TRANSLATION_MESSAGE_DEFINITION),
                        OwnedTypeDeclaration(origin, TEST_MESSAGE_ACTION_DEFINITION),
                        OwnedTypeDeclaration(origin, TEST_TREE_DEFINITION),
                    ),
                nativeBindings =
                    listOf(
                        OwnedNativeBinding(origin, TestTextMessageNativeBindingFactory),
                        OwnedNativeBinding(origin, TestTranslationMessageNativeBindingFactory),
                        OwnedNativeBinding(origin, TestMessageActionNativeBindingFactory),
                        OwnedNativeBinding(origin, TestTreeNativeBindingFactory),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "polymorphic native")))
        val checked = assembly.checked.resolve(TEST_MESSAGE_ACTION_USE).ready()
        val binding = assembly.bindings.bind(checked)
        val original =
            TestMessageAction(
                message = TestTextMessage("hello"),
                messages = listOf(TestTextMessage("one"), TestTranslationMessage("dialogue.greeting")),
                optional = TestTranslationMessage("dialogue.optional"),
            )

        @Suppress("UNCHECKED_CAST")
        val encoded = (binding as NativeBinding<TestMessageAction>).encode(original)
        val complete = checked.complete(encoded).complete()
        binding.decode(complete) shouldBe original

        val treeChecked = assembly.checked.resolve(TEST_TEXT_TREE_USE).ready()
        val treeBinding = assembly.bindings.bind(treeChecked)
        val tree = TestTree("root", listOf(TestTree("leaf", emptyList())))

        @Suppress("UNCHECKED_CAST")
        val encodedTree = (treeBinding as NativeBinding<TestTree<String>>).encode(tree)
        treeBinding.decode(treeChecked.complete(encodedTree).complete()) shouldBe tree
    }

    test("native binding registry rejects checked handles from another catalog generation") {
        val origin = providerOrigin("catalog_generation")
        val contributions =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin, TEST_MESSAGE_DEFINITION),
                        OwnedTypeDeclaration(origin, TEST_TEXT_MESSAGE_DEFINITION),
                    ),
                nativeBindings = listOf(OwnedNativeBinding(origin, TestTextMessageNativeBindingFactory)),
            )
        val first = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "first generation")))
        val second = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "second generation")))
        val stale = first.checked.resolve(TEST_TEXT_MESSAGE_ID.use()).ready()

        shouldThrow<NativeBindingException> { second.bindings.bind(stale) }.code shouldBe "catalog_generation_mismatch"
    }

    test("portable bindings preserve opaque records through generic containers") {
        val origin = providerOrigin("portable_bindings")
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, TEST_PORTABLE_RECORD_DEFINITION)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "portable bindings")))
        val payload = DataValue.record(mapOf("label" to DataValue.StringValueWrapper("opaque")))
        val value = DataValue.named(TEST_PORTABLE_RECORD_USE, payload)
        val checked = assembly.checked.resolve(TEST_PORTABLE_RECORD_USE.use).ready()

        @Suppress("UNCHECKED_CAST")
        val binding = assembly.bindings.bind(checked) as NativeBinding<PortableValue>
        val decoded = binding.decode(checked.complete(value).complete())
        decoded shouldBe PortableValue(TEST_PORTABLE_RECORD_USE.use, payload)
        binding.encode(decoded) shouldBe value

        val listChecked = assembly.checked.resolve(TEST_PORTABLE_RECORD_LIST_USE.use).ready()
        val authoredList =
            DataValue.named(
                TEST_PORTABLE_RECORD_LIST_USE,
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "opaque"),
                            value = value,
                        ),
                    ),
                ),
            )

        @Suppress("UNCHECKED_CAST")
        val listBinding = assembly.bindings.bind(listChecked) as NativeBinding<List<PortableValue>>
        val portableList = listBinding.decode(listChecked.complete(authoredList).complete())
        portableList shouldBe listOf(PortableValue(TEST_PORTABLE_RECORD_USE.use, payload))
        listBinding.encode(portableList) shouldBe
            DataValue.named(
                TEST_PORTABLE_RECORD_LIST_USE,
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "native:0"),
                            value = value,
                        ),
                    ),
                ),
            )

        shouldThrow<NativeBindingException> {
            binding.encode(PortableValue(TEST_CODE_USE.use, payload))
        }.code shouldBe "wrong_portable_actual_type"
        val invalid = checked.complete(DataValue.named(TEST_PORTABLE_RECORD_USE, DataValue.record(emptyMap())))
        (invalid as CompletenessResult.Invalid).problems.single().code shouldBe "missing_field"
    }

    test("native set and map reject canonical duplicate non data record values") {
        val origin = providerOrigin("canonical_native_duplicates")
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, TEST_IDENTITY_KEY_DEFINITION)),
                nativeBindings = listOf(OwnedNativeBinding(origin, TestIdentityKeyNativeBindingFactory)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "canonical native duplicates")))
        val first =
            DataValue.named(
                TEST_IDENTITY_KEY_USE,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("same"))),
            )
        val second =
            DataValue.named(
                TEST_IDENTITY_KEY_USE,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("same"))),
            )

        val setChecked = assembly.checked.resolve(TEST_IDENTITY_KEY_SET_USE.use).ready()
        val setValue =
            DataValue.named(
                TEST_IDENTITY_KEY_SET_USE,
                DataValue.setValue(
                    listOf(
                        skirout.editor.v1.type_catalog
                            .ListItem(
                                id =
                                    skirout.editor.v1.type_catalog
                                        .ItemId(value = "first"),
                                value = first,
                            ),
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "second"),
                            value = second,
                        ),
                    ),
                ),
            )
        val setBinding = assembly.bindings.bind(setChecked)
        shouldThrow<NativeBindingException> {
            setBinding.decode(setChecked.complete(setValue).complete())
        }.code shouldBe "duplicate_set_value"

        val mapChecked = assembly.checked.resolve(TEST_IDENTITY_KEY_MAP_USE.use).ready()
        val mapValue =
            DataValue.named(
                TEST_IDENTITY_KEY_MAP_USE,
                DataValue.mapValue(
                    listOf(
                        skirout.editor.v1.type_catalog.MapRow(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "first"),
                            key = first,
                            value = DataValue.StringValueWrapper("one"),
                        ),
                        skirout.editor.v1.type_catalog.MapRow(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "second"),
                            key = second,
                            value = DataValue.StringValueWrapper("two"),
                        ),
                    ),
                ),
            )
        val mapBinding = assembly.bindings.bind(mapChecked)
        shouldThrow<NativeBindingException> {
            mapBinding.decode(mapChecked.complete(mapValue).complete())
        }.code shouldBe "duplicate_map_key"
    }

    test("float32 native binding preserves exact width and rejects precision loss") {
        val assembly =
            CatalogContributions(declarations = emptyList()).assemble(
                CatalogAssemblyContext(CatalogGeneration(value = "float32 native width")),
            )
        val use = floatScalar(FloatWidth.THIRTY_TWO).use
        val checked = assembly.checked.resolve(use).ready()

        @Suppress("UNCHECKED_CAST")
        val binding = assembly.bindings.bind(checked) as NativeBinding<Float>
        val original = 1.25f
        val encoded = binding.encode(original)
        encoded shouldBe DataValue.FloatWrapper(original.toDouble())
        binding.decode(checked.complete(encoded).complete()) shouldBe original

        val imprecise = checked.complete(DataValue.FloatWrapper(0.1)) as CompletenessResult.Invalid
        imprecise.problems.single().code shouldBe "float32_precision_loss"
    }

    test("catalog assembly isolates duplicate declarations and incompatible inherited fields") {
        val origin = providerOrigin("catalog_conflicts")
        val left = recordDefinition("Left", "value", ScalarKind.TEXT.template)
        val right = recordDefinition("Right", "value", INT)
        val childId = definitionId("Child")
        val child =
            TypeDefinition.partial(
                id = childId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(left.id.namedTemplate(), right.id.namedTemplate()),
            )
        val duplicate = recordDefinition("Duplicate", "value", ScalarKind.TEXT.template)
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin, left),
                        OwnedTypeDeclaration(origin, right),
                        OwnedTypeDeclaration(origin, child),
                        OwnedTypeDeclaration(origin, duplicate),
                        OwnedTypeDeclaration(providerOrigin("duplicate_owner"), duplicate),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "catalog conflicts")))

        assembly.editorCatalog.types
            .single { it.definition.id == childId }
            .status shouldBe
            DeclarationStatus.UnavailableWrapper(
                listOf(
                    skirout.editor.v1.diagnostic.DeclarationDiagnostic.of(
                        childId,
                        "ambiguous_inherited_field",
                        field = RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("value"))),
                    ),
                ),
            )
        assembly.editorCatalog.types.count { it.definition.id == duplicate.id } shouldBe 1
        (
            assembly.editorCatalog.types
                .single { it.definition.id == duplicate.id }
                .status is skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper
        ) shouldBe true
    }

    test("catalog assembly retains competing field defaults without invalidating their types") {
        val origin = providerOrigin("field_presentation_conflicts")
        val root = recordDefinition("PresentationRoot", "value", ScalarKind.TEXT.template)
        val textNamed =
            TypeDefinition.partial(
                id = definitionId("TextNamed"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(root.id.namedTemplate()),
            )
        val choiceNamed =
            TypeDefinition.partial(
                id = definitionId("ChoiceNamed"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(root.id.namedTemplate()),
            )
        val conflicted =
            TypeDefinition.partial(
                id = definitionId("ConflictedPresentationChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(textNamed.id.namedTemplate(), choiceNamed.id.namedTemplate()),
            )
        val resolved =
            TypeDefinition.partial(
                id = definitionId("ResolvedPresentationChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(textNamed.id.namedTemplate(), choiceNamed.id.namedTemplate()),
            )
        val unrelated =
            TypeDefinition.partial(
                id = definitionId("UnrelatedPresentationChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(root.id.namedTemplate()),
            )
        val textProvider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "text named")
        val choiceProvider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "choice named")
        val resolvedProvider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "resolved child")
        val textEditor =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "text editor")
        val choiceEditor =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "choice editor")
        val resolvedEditor =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "resolved editor")
        val textTarget = PresentationTarget.NamedWrapper(textNamed.id.namedTemplate())
        val choiceTarget = PresentationTarget.NamedWrapper(choiceNamed.id.namedTemplate())
        val resolvedTarget = PresentationTarget.NamedWrapper(resolved.id.namedTemplate())
        val materials =
            listOf(
                fieldPresentationMaterial(textProvider, textTarget, textEditor),
                fieldPresentationMaterial(choiceProvider, choiceTarget, choiceEditor),
                fieldPresentationMaterial(resolvedProvider, resolvedTarget, resolvedEditor),
            )
        val descriptors =
            listOf(
                ownedPresentation(origin, textProvider, textTarget, materials[0]),
                ownedPresentation(origin, choiceProvider, choiceTarget, materials[1]),
                ownedPresentation(origin, resolvedProvider, resolvedTarget, materials[2]),
            )
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(root, textNamed, choiceNamed, conflicted, resolved, unrelated).map { definition ->
                        OwnedTypeDeclaration(origin, definition)
                    },
                presentations = descriptors,
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "field presentation conflicts")))

        assembly.editorCatalog.types
            .filter { it.definition.id in setOf(conflicted.id, resolved.id, unrelated.id) }
            .forEach { it.status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY }
        assembly.editorCatalog.presentationMaterials.forEach { material ->
            material.inheritableNodes shouldBe listOf("field choice")
        }
        assembly.editorCatalog.diagnostics.none { it.code == "conflicting_field_presentation" } shouldBe true
    }

    test("catalog assembly rejects an inferred control outside its owning record") {
        val origin = providerOrigin("invalid_field_presentation")
        val definition = recordDefinition("InvalidPresentationField", "actual", ScalarKind.TEXT.template)
        val provider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "invalid field")
        val target = PresentationTarget.NamedWrapper(definition.id.namedTemplate())
        val material =
            fieldPresentationMaterial(
                provider,
                target,
                skirout.editor.v1.type_catalog
                    .PresentationId(namespace = "test", name = "text"),
            )
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                presentations = listOf(ownedPresentation(origin, provider, target, material)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "invalid field")))
        val status =
            assembly.editorCatalog.types
                .single { it.definition.id == definition.id }
                .status as skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper
        status.value.map { it.code } shouldBe listOf("presentation_material_build_failed")
    }

    test("catalog assembly admits bounded atomic parts and rejects foreign owners or owner remainders") {
        val origin = providerOrigin("atomic_parts")
        val definition = recordDefinition("PartOwner", "value", ScalarKind.TEXT.template)
        val foreign = recordDefinition("ForeignPartOwner", "value", ScalarKind.TEXT.template)
        val provider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "atomic part")
        val target = PresentationTarget.NamedWrapper(definition.id.namedTemplate())
        val base =
            fieldPresentationMaterial(
                provider,
                target,
                skirout.editor.v1.type_catalog
                    .PresentationId(namespace = "test", name = "text"),
            )
        val ownKey =
            skirout.editor.v1.presentation.PresentationPartId(
                owner =
                    definition.id,
                name = "details",
            )
        val part =
            skirout.editor.v1.presentation.PresentationNode.partial(
                nodeId = "part",
                element =
                    skirout.editor.v1.presentation.PresentationElement
                        .createPart(key = ownKey, body = base.layout),
            )
        val variants =
            listOf(
                part to true,
                part.copy(
                    element =
                        skirout.editor.v1.presentation.PresentationElement.createPart(
                            key =
                                ownKey.copy(
                                    owner =
                                        foreign.id,
                                ),
                            body = base.layout,
                        ),
                ) to false,
                part.copy(
                    element =
                        skirout.editor.v1.presentation.PresentationElement.createPart(
                            key = ownKey,
                            body =
                                skirout.editor.v1.presentation.PresentationNode.partial(
                                    nodeId = "owner remainder",
                                    element =
                                        skirout.editor.v1.presentation.PresentationElement.createRemainingFields(
                                            excluded = emptyList(),
                                            excludedParts = emptyList(),
                                        ),
                                ),
                        ),
                ) to false,
            )
        variants.forEach { (layout, admitted) ->
            val assembly =
                CatalogContributions(
                    declarations = listOf(OwnedTypeDeclaration(origin, definition), OwnedTypeDeclaration(origin, foreign)),
                    presentations = listOf(ownedPresentation(origin, provider, target, base.copy(layout = layout))),
                ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "atomic parts")))
            val status =
                assembly.editorCatalog.types
                    .single { it.definition.id == definition.id }
                    .status
            if (admitted) {
                status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
                assembly.editorCatalog.presentationMaterials
                    .single()
                    .inheritableNodes shouldBe listOf("part")
            } else {
                (status as skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper).value.map { it.code } shouldBe
                    listOf("presentation_material_build_failed")
            }
        }
    }

    test("published materials own immutable inferred references") {
        val references = mutableListOf("node")
        val published =
            fieldPresentationMaterial(
                skirout.editor.v1.type_catalog
                    .PresentationId(namespace = "test", name = "immutable fields"),
                PresentationTarget.NamedWrapper(definitionId("ImmutablePresentation").namedTemplate()),
                skirout.editor.v1.type_catalog
                    .PresentationId(namespace = "test", name = "text"),
            ).copy(inheritableNodes = references)
        references.clear()
        published.inheritableNodes shouldBe listOf("node")
    }

    test("catalog assembly owns one immutable published catalog graph") {
        val id = definitionId("ImmutableSnapshot")
        val argumentList = mutableListOf<TypeTemplate>(ScalarKind.TEXT.template)
        val fieldList =
            mutableListOf(
                FieldDeclaration.partial(
                    owner = FieldOwner(definition = id, name = "items"),
                    type = StandardTypes.list.template(argumentList),
                ),
            )
        val definition =
            TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = fieldList, abstract_ = false))
        val fallbackParents =
            mutableListOf<skirout.editor.v1.catalog.PresentationRole>(skirout.editor.v1.catalog.PresentationRole.WORKSPACE)
        val endpointPath = mutableListOf<skirout.editor.v1.type_catalog.FieldPatternSegment>(FieldPatternSegment.field("items"))
        val rules =
            mutableListOf(
                skirout.editor.v1.catalog.OwnedRule(
                    id = RuleId(origin = RuleOrigin(owner = id, ordinal = 0), localIndex = 0),
                    descriptor =
                        skirout.editor.v1.catalog
                            .RuleDescriptor(predicate = testLiteral(DataValue.BooleanWrapper(true))),
                    diagnostic =
                        skirout.editor.v1.diagnostic.DiagnosticTemplate(
                            code = "valid",
                            message = "valid",
                            severity = DiagnosticSeverity.ERROR,
                            targets = mutableListOf(RelativeFieldPattern.root),
                        ),
                ),
            )
        val recipe =
            skirout.editor.v1.catalog.ConfigurationRecipe(
                origin = RuleOrigin(owner = id, ordinal = 0),
                relativePath = RelativeFieldPattern.root,
                representationCondition = RepresentationKind.RECORD,
                rules = rules,
            )
        val origin = providerOrigin("immutable_snapshot")
        val configuration =
            object : ConfigurationProvider {
                override fun collect(scope: ConfigurationCollectionScope) =
                    com.typewritermc.configuration.CollectedConfiguration(mutableListOf(recipe), emptyList())
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                configurations = listOf(OwnedConfiguration(origin, id, configuration)),
            ).assemble(
                CatalogAssemblyContext(
                    generation = CatalogGeneration(value = "immutable snapshot"),
                    endpointBindings =
                        mutableListOf(
                            skirout.editor.v1.catalog.EndpointBindingTemplate(
                                endpoint = EndpointId(value = "immutable:endpoint"),
                                containingResource = id.namedTemplate(),
                                valueOwner = id,
                                relativePath = RelativeFieldPattern(segments = endpointPath),
                                target = StandardTypes.list.template(argumentList),
                                containsCollection = true,
                            ),
                        ),
                    roleFallbacks =
                        mutableListOf(
                            skirout.editor.v1.catalog.RoleFallback(
                                role = skirout.editor.v1.catalog.PresentationRole.INSPECTOR,
                                parents = fallbackParents,
                            ),
                        ),
                ),
            )

        fieldList +=
            FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "late"), type = ScalarKind.TEXT.template)
        argumentList[0] = INT
        fallbackParents += skirout.editor.v1.catalog.PresentationRole.RESOURCE_SEARCH_RESULT
        endpointPath += FieldPatternSegment.ITEMS
        rules.clear()

        val published = assembly.editorCatalog.types.single { it.definition.id == id }
        val publishedField = (published.definition.representation as RepresentationTemplate.RecordWrapper).value.fields.single()
        (publishedField.type as TypeTemplate.NamedWrapper).value.arguments shouldBe listOf(ScalarKind.TEXT.template)
        assembly.configuration
            .single()
            .rules.size shouldBe 1
        assembly.endpointBindings
            .single()
            .relativePath.segments shouldBe
            listOf(FieldPatternSegment.field("items"))
        assembly.editorCatalog.roleFallbacks
            .single()
            .parents shouldBe
            listOf(skirout.editor.v1.catalog.PresentationRole.WORKSPACE)
        val checked = assembly.checked.resolve(id.use()).ready()
        (checked.schema.representation as ResolvedRepresentation.RecordWrapper).value.fields.size shouldBe 1
    }

    test("catalog assembly reasons across inherited mandatory rules") {
        val parent = recordDefinition("BoundedParent", "value", INT)
        val child =
            TypeDefinition.partial(
                id = definitionId("BoundedChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                parents = listOf(parent.id.namedTemplate()),
            )
        val origin = providerOrigin("inherited_rules")
        val minimum =
            configurationProvider { scope ->
                integerField(scope, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("value")))).minimum(10)
            }
        val maximum =
            configurationProvider { scope ->
                integerField(scope, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("value")))).maximum(5)
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, parent), OwnedTypeDeclaration(origin, child)),
                configurations =
                    listOf(
                        OwnedConfiguration(origin, parent.id, minimum),
                        OwnedConfiguration(providerOrigin("child_rules"), child.id, maximum),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "inherited rules")))

        assembly.editorCatalog.types
            .single { it.definition.id == parent.id }
            .status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
        val childStatus =
            assembly.editorCatalog.types
                .single { it.definition.id == child.id }
                .status as skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper
        childStatus.value.map { it.code } shouldBe listOf("contradictory_configuration_rules")
    }

    test("generic representation rules receive semantic validation") {
        val genericId = definitionId("GenericTextRule")
        val parameter = ParameterKey(owner = genericId, index = 0)
        val generic =
            TypeDefinition.partial(
                id = genericId,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = genericId, name = "value"),
                                    type = parameter.template,
                                ),
                            ),
                        abstract_ = false,
                    ),
            )
        val origin = providerOrigin("generic_rules")
        val rules =
            configurationProvider { scope ->
                textField(
                    scope,
                    RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("value"))),
                    ScalarKind.TEXT.template,
                ).apply {
                    minimumLength(10)
                    maximumLength(5)
                }
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, generic)),
                configurations = listOf(OwnedConfiguration(origin, generic.id, rules)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "generic rules")))

        val status =
            assembly.editorCatalog.types
                .single { it.definition.id == generic.id }
                .status as skirout.editor.v1.catalog.DeclarationStatus.UnavailableWrapper
        status.value.map { it.code } shouldBe listOf("contradictory_configuration_rules")
    }
}

private fun configurationProvider(configure: (ConfigurationCollectionScope) -> Unit): ConfigurationProvider =
    object : ConfigurationProvider {
        override fun collect(scope: ConfigurationCollectionScope): com.typewritermc.configuration.CollectedConfiguration {
            configure(scope)
            return scope.collected()
        }
    }

private fun integerField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern,
): Integer<Int> {
    @Suppress("UNCHECKED_CAST")
    return scope.field(
        path,
        RepresentationKind.INTEGER,
        INT,
        Integer::class as KClass<Integer<Int>>,
    )
}

private fun textField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern,
    expected: TypeTemplate,
): Text = scope.field(path, RepresentationKind.TEXT, expected, Text::class)

private fun unsignedIntegerField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern,
): Integer<ULong> {
    @Suppress("UNCHECKED_CAST")
    return scope.field(
        path,
        RepresentationKind.INTEGER,
        integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR).template,
        Integer::class as KClass<Integer<ULong>>,
    )
}

private fun nullableTextField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern,
): NullableField<String, Text> {
    @Suppress("UNCHECKED_CAST")
    return scope.field(
        path,
        RepresentationKind.TEXT,
        ScalarKind.TEXT.template.nullable(),
        NullableField::class as KClass<NullableField<String, Text>>,
        mapOf(
            FieldPatternSegment.VALUES to
                NestedConfigurationScope(
                    RepresentationKind.TEXT,
                    ScalarKind.TEXT.template,
                    Text::class,
                    com.typewritermc.configuration.TextExpressionsFactory,
                ) { nested ->
                    textField(nested, RelativeFieldPattern.root, ScalarKind.TEXT.template)
                },
        ),
    )
}

private fun recordDefinition(
    name: String,
    field: String,
    type: TypeTemplate,
): TypeDefinition {
    val id = definitionId(name)
    return TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = field), type = type),
                    ),
                abstract_ = false,
            ),
    )
}

private fun fieldPresentationMaterial(
    provider: skirout.editor.v1.type_catalog.PresentationId,
    target: PresentationTarget,
    selected: skirout.editor.v1.type_catalog.PresentationId,
): PresentationMaterial {
    val binding =
        skirout.editor.v1.binding.BindingRef(
            path =
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.FieldWrapper(
                                skirout.editor.v1.type_catalog
                                    .FieldPathSegment(name = "value"),
                            ),
                        ),
                ),
            bindingId =
                skirout.editor.v1.type_catalog
                    .ExpressionBindingId(value = "configured_value"),
        )
    val layout =
        skirout.editor.v1.presentation.PresentationNode(
            nodeId = "field choice",
            properties =
                skirout.editor.v1.presentation.PresentationProperties
                    .partial(),
            element =
                skirout.editor.v1.presentation.PresentationElement.createDefaultPresentation(
                    control =
                        skirout.editor.v1.presentation.BoundControl(
                            binding = binding,
                            label = null,
                            description = null,
                            prefix = null,
                            semanticLabel = null,
                        ),
                    presentationId =
                        skirout.editor.v1.type_catalog.PresentationId(
                            namespace = selected.namespace,
                            name = selected.name,
                        ),
                ),
            header = null,
        )
    return PresentationMaterial(
        provider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = provider.namespace, name = provider.name),
        target = target,
        role = skirout.editor.v1.catalog.PresentationRole.INSPECTOR,
        layout = layout,
        dependencies =
            skirout.editor.v1.presentation.PresentationDependencies
                .partial(),
        subject =
            (target as PresentationTarget.NamedWrapper).value.template,
        inheritableNodes = emptyList(),
    )
}

private fun ownedPresentation(
    origin: ProviderOrigin,
    id: skirout.editor.v1.type_catalog.PresentationId,
    target: PresentationTarget,
    material: PresentationMaterial,
): OwnedPresentation {
    val descriptor =
        PresentationDescriptor.of(
            id = id,
            owner = origin.owner,
            target = target,
            roles = setOf(skirout.editor.v1.catalog.PresentationRole.INSPECTOR),
            priority = 0,
        )
    return OwnedPresentation(
        origin,
        descriptor,
        object : PresentationProvider {
            override fun build(binding: com.typewritermc.presentation.PresentationBuildBinding) =
                com.typewritermc.presentation.PresentationBuildResult(material.layout, material.dependencies)
        },
    )
}

private fun providerOrigin(name: String): ProviderOrigin {
    val key = contributionKey(ContributionSourceId("test"), "main", ProducerId("sdk"), ContributionName(name))
    return ProviderOrigin(DeclarationOwner(source = key, localIdentity = name), ArtifactId("test:sdk"), "main")
}

private fun definitionId(name: String): TypeDefinitionId = TypeDefinitionId.qualified("test", name)

private fun <T> com.typewritermc.types.catalog.Resolution<T>.ready(): T = (this as com.typewritermc.types.catalog.Resolution.Ready).value

private fun com.typewritermc.authoring.CompletenessResult.complete() = (this as CompletenessResult.Complete).value

private fun DataValue.available(): Availability<DataValue> = Availability.Available(this)

private object EmptyReads : AuthoredReads {
    override val catalog: CatalogGeneration = CatalogGeneration(value = "expression catalog")
    override val readContext = com.typewritermc.authoring.ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> = error("Portable reads use the expression reader in this fixture.")

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> = error("Portable reads use the expression reader in this fixture.")

    override fun presence(path: BoundPath<*>): Availability<Boolean> = error("Portable reads use the expression reader in this fixture.")

    override fun binding(path: BoundPath<*>): Availability<com.typewritermc.authoring.DraftBinding> =
        error("Portable reads use the expression reader in this fixture.")

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> =
        error("Portable reads use the expression reader in this fixture.")

    override fun members(path: BoundCollectionPath): List<skirout.editor.v1.type_catalog.ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Selections are not used in this fixture.")
}

@JvmInline
private value class TestCode(
    val value: String,
)

private object TestCodeNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = TEST_CODE_ID
    override val provider: NativeBindingId = NativeBindingId(value = "test.code")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedScalarNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.code",
            representation = arguments.resolver.bind(TEXT_USE),
            unwrap = TestCode::value,
            construct = { TestCode(it as String) },
        )
}

private sealed interface TestMessage

private data class TestTextMessage(
    val text: String,
) : TestMessage

private data class TestTranslationMessage(
    val key: String,
) : TestMessage

private data class TestMessageAction(
    val message: TestMessage,
    val messages: List<TestMessage>,
    val optional: TestMessage?,
)

private data class TestTree<T>(
    val value: T,
    val children: List<TestTree<T>>,
)

private class TestIdentityKey(
    val value: String,
)

private object TestTextMessageNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TEXT_MESSAGE_ID
    override val provider = NativeBindingId(value = "test.text_message")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.text_message",
            nativeClass = TestTextMessage::class,
            fields = listOf(GeneratedNativeField("text", { arguments.resolver.bind(TEXT_USE) }, TestTextMessage::text)),
            construct = { TestTextMessage(it.getValue("text") as String) },
        )
}

private object TestTranslationMessageNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TRANSLATION_MESSAGE_ID
    override val provider = NativeBindingId(value = "test.translation_message")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.translation_message",
            nativeClass = TestTranslationMessage::class,
            fields = listOf(GeneratedNativeField("key", { arguments.resolver.bind(TEXT_USE) }, TestTranslationMessage::key)),
            construct = { TestTranslationMessage(it.getValue("key") as String) },
        )
}

private object TestMessageActionNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_MESSAGE_ACTION_ID
    override val provider = NativeBindingId(value = "test.message_action")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.message_action",
            nativeClass = TestMessageAction::class,
            fields =
                listOf(
                    GeneratedNativeField("message", { arguments.resolver.bind(TEST_MESSAGE_USE) }, TestMessageAction::message),
                    GeneratedNativeField("messages", { arguments.resolver.bind(TEST_MESSAGE_LIST_USE) }, TestMessageAction::messages),
                    GeneratedNativeField("optional", { arguments.resolver.bind(TEST_OPTIONAL_MESSAGE_USE) }, TestMessageAction::optional),
                ),
            construct =
                {
                    @Suppress("UNCHECKED_CAST")
                    TestMessageAction(
                        it.getValue("message") as TestMessage,
                        it.getValue("messages") as List<TestMessage>,
                        it.getValue("optional") as TestMessage?,
                    )
                },
        )
}

private object TestTreeNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TREE_ID
    override val provider = NativeBindingId(value = "test.tree")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> {
        val treeUse = actual.use as TypeUse.NamedWrapper
        val childrenUse = StandardTypes.list.use(listOf(treeUse))
        return GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.tree",
            nativeClass = TestTree::class,
            fields =
                listOf(
                    GeneratedNativeField<TestTree<*>>("value", { arguments.bindings.single() }) { it.value },
                    GeneratedNativeField<TestTree<*>>("children", { arguments.resolver.bind(childrenUse) }) { it.children },
                ),
            construct =
                {
                    @Suppress("UNCHECKED_CAST")
                    TestTree(
                        it.getValue("value"),
                        it.getValue("children") as List<TestTree<Any?>>,
                    )
                },
        )
    }
}

private object TestIdentityKeyNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_IDENTITY_KEY_ID
    override val provider = NativeBindingId(value = "test.identity_key")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.identity_key",
            nativeClass = TestIdentityKey::class,
            fields = listOf(GeneratedNativeField("value", { arguments.resolver.bind(TEXT_USE) }, TestIdentityKey::value)),
            construct = { TestIdentityKey(it.getValue("value") as String) },
        )
}

private val INT = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
private val INT_USE = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
private val TEXT_USE = ScalarKind.TEXT.use
private val TEST_CODE_ID = definitionId("TestCode")
private val TEST_CODE_USE = TEST_CODE_ID.namedUse()
private val TEST_CODE_DEFINITION =
    TypeDefinition.partial(id = TEST_CODE_ID, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
private val TEST_MESSAGE_ID = definitionId("TestMessage")
private val TEST_TEXT_MESSAGE_ID = definitionId("TestTextMessage")
private val TEST_TRANSLATION_MESSAGE_ID = definitionId("TestTranslationMessage")
private val TEST_MESSAGE_ACTION_ID = definitionId("TestMessageAction")
private val TEST_TREE_ID = definitionId("TestTree")
private val TEST_IDENTITY_KEY_ID = definitionId("TestIdentityKey")
private val TEST_PORTABLE_RECORD_ID = definitionId("TestPortableRecord")
private val TEST_TREE_PARAMETER = ParameterKey(owner = TEST_TREE_ID, index = 0)
private val TEST_MESSAGE_USE = TEST_MESSAGE_ID.use()
private val TEST_MESSAGE_LIST_USE = StandardTypes.list.use(listOf(TEST_MESSAGE_USE))
private val TEST_OPTIONAL_MESSAGE_USE = TEST_MESSAGE_USE.nullable()
private val TEST_MESSAGE_ACTION_USE = TEST_MESSAGE_ACTION_ID.use()
private val TEST_TEXT_TREE_USE = TEST_TREE_ID.use(listOf(TEXT_USE))
private val TEST_IDENTITY_KEY_USE = TEST_IDENTITY_KEY_ID.namedUse()
private val TEST_IDENTITY_KEY_SET_USE = StandardTypes.set.namedUse(listOf(TEST_IDENTITY_KEY_USE.use))
private val TEST_IDENTITY_KEY_MAP_USE = StandardTypes.map.namedUse(listOf(TEST_IDENTITY_KEY_USE.use, TEXT_USE))
private val TEST_PORTABLE_RECORD_USE = TEST_PORTABLE_RECORD_ID.namedUse()
private val TEST_PORTABLE_RECORD_LIST_USE = StandardTypes.list.namedUse(listOf(TEST_PORTABLE_RECORD_USE.use))
private val TEST_PORTABLE_RECORD_DEFINITION =
    TypeDefinition.partial(
        id = TEST_PORTABLE_RECORD_ID,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_PORTABLE_RECORD_ID, name = "label"),
                            type = ScalarKind.TEXT.template,
                        ),
                    ),
                abstract_ = false,
            ),
    )
private val TEST_IDENTITY_KEY_DEFINITION =
    TypeDefinition.partial(
        id = TEST_IDENTITY_KEY_ID,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_IDENTITY_KEY_ID, name = "value"),
                            type = ScalarKind.TEXT.template,
                        ),
                    ),
                abstract_ = false,
            ),
    )
private val TEST_MESSAGE_DEFINITION =
    TypeDefinition.partial(
        id = TEST_MESSAGE_ID,
        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
    )
private val TEST_TEXT_MESSAGE_DEFINITION =
    TypeDefinition.partial(
        id = TEST_TEXT_MESSAGE_ID,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TEXT_MESSAGE_ID, name = "text"),
                            type = ScalarKind.TEXT.template,
                        ),
                    ),
                abstract_ = false,
            ),
        parents = listOf(TEST_MESSAGE_ID.namedTemplate()),
    )
private val TEST_TRANSLATION_MESSAGE_DEFINITION =
    TypeDefinition.partial(
        id = TEST_TRANSLATION_MESSAGE_ID,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TRANSLATION_MESSAGE_ID, name = "key"),
                            type = ScalarKind.TEXT.template,
                        ),
                    ),
                abstract_ = false,
            ),
        parents = listOf(TEST_MESSAGE_ID.namedTemplate()),
    )
private val TEST_MESSAGE_ACTION_DEFINITION =
    TypeDefinition.partial(
        id = TEST_MESSAGE_ACTION_ID,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_MESSAGE_ACTION_ID, name = "message"),
                            type = TEST_MESSAGE_ID.template(),
                        ),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_MESSAGE_ACTION_ID, name = "messages"),
                            type = StandardTypes.list.template(listOf(TEST_MESSAGE_ID.template())),
                        ),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_MESSAGE_ACTION_ID, name = "optional"),
                            type = TEST_MESSAGE_ID.template().nullable(),
                        ),
                    ),
                abstract_ = false,
            ),
    )
private val TEST_TREE_DEFINITION =
    TypeDefinition.partial(
        id = TEST_TREE_ID,
        parameters = listOf(TypeParameter.partial(key = TEST_TREE_PARAMETER, name = "T")),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TREE_ID, name = "value"),
                            type = TEST_TREE_PARAMETER.template,
                        ),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = TEST_TREE_ID, name = "children"),
                            type = StandardTypes.list.template(listOf(TEST_TREE_ID.template(listOf(TEST_TREE_PARAMETER.template)))),
                        ),
                    ),
                abstract_ = false,
            ),
    )
