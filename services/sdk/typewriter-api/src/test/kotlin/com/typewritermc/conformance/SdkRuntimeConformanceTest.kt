package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PortableValue
import com.typewritermc.authoring.WorklistDefaultModeResolver
import com.typewritermc.authoring.complete
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.SnapshotId
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.ConfigurationCollectionScope
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.configuration.DefaultConfigurationCollectionScope
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.InitializationPreference
import com.typewritermc.configuration.InitializationRequirements
import com.typewritermc.configuration.Integer
import com.typewritermc.configuration.NestedConfigurationScope
import com.typewritermc.configuration.NullableField
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.configuration.Text
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.EvaluationBudget
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.PortableExpressionLimits
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.GeneratedScalarNativeBinding
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationStatus
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
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
            com.typewritermc.authoring.ValueLocation(
                ResourceId("book:requested"),
                com.typewritermc.authoring.ValuePath(),
            )
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { DataValue.StringValue("Requested").available() })

        with(EmptyReads) {
            evaluator.evaluate(
                predicate,
                ExpressionBindings(mapOf(ExpressionBindingId("configured_value") to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.Boolean(true))
        }
    }

    test("portable evaluation short circuits fallback and preserves named scalar semantics") {
        val location = com.typewritermc.authoring.ValueLocation(ResourceId("expression:test"), com.typewritermc.authoring.ValuePath())
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
        val read = ExpressionNode.Read(binding, com.typewritermc.authoring.ValuePath())

        with(EmptyReads) {
            evaluator.evaluate(ExpressionNode.And(ExpressionNode.Literal(DataValue.Boolean(false)), read), bindings, budget) shouldBe
                Availability.Available(DataValue.Boolean(false))
            reads shouldBe 0
            evaluator.evaluate(
                ExpressionNode.OrElse(read, ExpressionNode.Literal(DataValue.StringValue("fallback"))),
                bindings,
                budget,
            ) shouldBe Availability.Available(DataValue.StringValue("fallback"))
            result = DataValue.Named(TEST_CODE_USE, DataValue.StringValue("chapter")).available()
            evaluator.evaluate(
                ExpressionNode.Call(com.typewritermc.expression.OperationId("typewriter.rule.nonBlank"), listOf(read)),
                bindings,
                budget,
            ) shouldBe Availability.Available(DataValue.Boolean(true))
            result = Availability.Failed(EvaluationDiagnostic("read_failed", "broken", listOf(location)))
            evaluator.evaluate(
                ExpressionNode.OrElse(read, ExpressionNode.Literal(DataValue.StringValue("hidden"))),
                bindings,
                budget,
            ) shouldBe result
        }
    }

    test("portable evaluation bounds expression depth without evaluating a short circuited branch") {
        var nested: ExpressionNode = ExpressionNode.Literal(DataValue.Boolean(true))
        repeat(PortableExpressionLimits.MAX_DEPTH + 1) {
            nested = ExpressionNode.And(ExpressionNode.Literal(DataValue.Boolean(true)), nested)
        }
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })
        with(EmptyReads) {
            val failed = evaluator.evaluate(nested, ExpressionBindings(emptyMap()), EvaluationBudget(100_000, 100))
            (failed as Availability.Failed).diagnostic.code shouldBe "expression_depth_limit"
            evaluator.evaluate(
                ExpressionNode.And(ExpressionNode.Literal(DataValue.Boolean(false)), nested),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(100_000, 100),
            ) shouldBe Availability.Available(DataValue.Boolean(false))
        }
    }

    test("portable whitespace includes Unicode whitespace and BOM but excludes information separator") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        fun call(
            operation: String,
            value: String,
        ) = ExpressionNode.Call(
            com.typewritermc.expression.OperationId(operation),
            listOf(ExpressionNode.Literal(DataValue.StringValue(value))),
        )

        with(EmptyReads) {
            listOf("\uFEFF", "\u0085", "\u00A0", "\u2007").forEach { whitespace ->
                evaluator.evaluate(
                    call("typewriter.rule.nonBlank", whitespace),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(10, 0),
                ) shouldBe Availability.Available(DataValue.Boolean(false))
            }
            evaluator.evaluate(
                call("typewriter.rule.nonBlank", "\u001C"),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(10, 0),
            ) shouldBe Availability.Available(DataValue.Boolean(true))
            evaluator.evaluate(
                call("typewriter.text.trim", "\uFEFF value \u0085"),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(10, 0),
            ) shouldBe Availability.Available(DataValue.StringValue("value"))
        }
    }

    test("portable regular expressions reject host specific and unsafe declaration syntax") {
        val scope = DefaultConfigurationCollectionScope(TEST_CODE_ID)
        textField(scope, RelativeFieldPattern(), TypeTemplate.Scalar(ScalarKind.Text)).regex("[a-z]+:[a-z]+")

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
                textField(DefaultConfigurationCollectionScope(TEST_CODE_ID), RelativeFieldPattern(), TypeTemplate.Scalar(ScalarKind.Text))
                    .regex(pattern)
            }
        }
    }

    test("portable regular expressions normalize whitespace and Unicode dot semantics") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        fun fullMatch(
            value: String,
            pattern: String,
        ) = ExpressionNode.Call(
            com.typewritermc.expression.OperationId("typewriter.rule.regex"),
            listOf(ExpressionNode.Literal(DataValue.StringValue(value)), ExpressionNode.Literal(DataValue.StringValue(pattern))),
        )

        with(EmptyReads) {
            evaluator.evaluate(fullMatch("\u00A0", "\\s"), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.Boolean(true))
            evaluator.evaluate(fullMatch("\u00A0", "[\\s]"), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.Boolean(true))
            evaluator.evaluate(fullMatch("😀", "."), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.Boolean(true))
            evaluator.evaluate(fullMatch("\u0085", "."), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.Boolean(true))
            evaluator.evaluate(fullMatch("\n", "."), ExpressionBindings(emptyMap()), EvaluationBudget(10, 0)) shouldBe
                Availability.Available(DataValue.Boolean(false))
        }
    }

    test("portable regular expressions charge search and replacement output to the step budget") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        fun call(
            operation: String,
            vararg values: String,
        ) = ExpressionNode.Call(
            com.typewritermc.expression.OperationId(operation),
            values.map { ExpressionNode.Literal(DataValue.StringValue(it)) },
        )

        with(EmptyReads) {
            val anchorSearch =
                evaluator.evaluate(
                    call("typewriter.regex.matches", "x".repeat(200), "^$"),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(50, 0),
                )
            (anchorSearch as Availability.Failed).diagnostic.code shouldBe "expression_step_limit"

            val replacementOutput =
                evaluator.evaluate(
                    call("typewriter.regex.replace", "", "", "replacement".repeat(20)),
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(30, 0),
                )
            (replacementOutput as Availability.Failed).diagnostic.code shouldBe "expression_step_limit"
        }
    }

    test("portable text expansion uses character boundaries and evaluator budgets") {
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") })

        context(reads: AuthoredReads)
        fun call(
            operation: String,
            values: List<DataValue>,
            budget: EvaluationBudget = EvaluationBudget(100, 100),
        ): Availability<DataValue> =
            evaluator.evaluate(
                ExpressionNode.Call(
                    com.typewritermc.expression.OperationId(operation),
                    values.map(ExpressionNode::Literal),
                ),
                ExpressionBindings(emptyMap()),
                budget,
            )

        with(EmptyReads) {
            call(
                "typewriter.text.replace",
                listOf(DataValue.StringValue("😀"), DataValue.StringValue(""), DataValue.StringValue("_")),
            ) shouldBe Availability.Available(DataValue.StringValue("_😀_"))

            call(
                "typewriter.text.split",
                listOf(DataValue.StringValue("😀x"), DataValue.StringValue("")),
            ) shouldBe
                Availability.Available(
                    DataValue.ListValue(
                        listOf(
                            com.typewritermc.types.ListItem(
                                com.typewritermc.authoring.ItemId("split.0"),
                                DataValue.StringValue("😀"),
                            ),
                            com.typewritermc.types.ListItem(
                                com.typewritermc.authoring.ItemId("split.1"),
                                DataValue.StringValue("x"),
                            ),
                        ),
                    ),
                )
            call(
                "typewriter.text.split",
                listOf(DataValue.StringValue(""), DataValue.StringValue("")),
            ) shouldBe Availability.Available(DataValue.ListValue(emptyList()))

            val large = DataValue.StringValue("value".repeat(20))
            listOf(
                call(
                    "typewriter.text.replace",
                    listOf(DataValue.StringValue("a"), DataValue.StringValue(""), large),
                    EvaluationBudget(30, 100),
                ),
                call(
                    "typewriter.text.join",
                    listOf(
                        DataValue.ListValue(
                            listOf(com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("only"), large)),
                        ),
                        DataValue.StringValue(""),
                    ),
                    EvaluationBudget(30, 100),
                ),
                call(
                    "typewriter.text.interpolate",
                    listOf(large),
                    EvaluationBudget(30, 100),
                ),
            ).forEach { result ->
                (result as Availability.Failed).diagnostic.code shouldBe "expression_step_limit"
            }

            val splitLimit =
                call(
                    "typewriter.text.split",
                    listOf(DataValue.StringValue("😀x"), DataValue.StringValue("")),
                    EvaluationBudget(100, 1),
                )
            (splitLimit as Availability.Failed).diagnostic.code shouldBe "expression_collection_limit"
        }
    }

    test("collection evaluation uses semantic equality propagates unfinished members and counts visited items") {
        val location = com.typewritermc.authoring.ValueLocation(ResourceId("collection:test"), com.typewritermc.authoring.ValuePath())
        val binding = ExpressionBindingId("items")
        val item = ExpressionBindingId("item")
        var value: DataValue =
            DataValue.ListValue(
                listOf(
                    com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("first"), DataValue.StringValue("same")),
                    com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("second"), DataValue.StringValue("same")),
                ),
            )
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { value.available() })
        val bindings = ExpressionBindings(mapOf(binding to location))
        val input = ExpressionNode.Read(binding, com.typewritermc.authoring.ValuePath())
        with(EmptyReads) {
            evaluator.evaluate(
                ExpressionNode.Call(com.typewritermc.expression.OperationId("typewriter.rule.unique"), listOf(input)),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe Availability.Available(DataValue.Boolean(false))
            value =
                DataValue.ListValue(
                    listOf(
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("unfinished"),
                            DataValue.Record(mapOf("valid" to DataValue.Unfilled)),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.Collection(
                    com.typewritermc.expression.OperationId("typewriter.collection.unique_by"),
                    input,
                    listOf(item),
                    emptyList(),
                    ExpressionNode.Read(item, com.typewritermc.authoring.ValuePath()),
                ),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe
                Availability.Unavailable(
                    listOf(
                        location.copy(
                            path =
                                com.typewritermc.authoring.ValuePath(
                                    listOf(
                                        com.typewritermc.authoring.PathSegment
                                            .Item(com.typewritermc.authoring.ItemId("unfinished")),
                                    ),
                                ),
                        ),
                    ),
                )

            value =
                DataValue.ListValue(
                    listOf(
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("known one"),
                            DataValue.StringValue("same"),
                        ),
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("known two"),
                            DataValue.StringValue("same"),
                        ),
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("unfinished"),
                            DataValue.Record(mapOf("valid" to DataValue.Unfilled)),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.Call(com.typewritermc.expression.OperationId("typewriter.collection.size"), listOf(input)),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe Availability.Available(DataValue.Integer(3.toBigInteger()))
            evaluator.evaluate(
                ExpressionNode.Call(com.typewritermc.expression.OperationId("typewriter.rule.unique"), listOf(input)),
                bindings,
                EvaluationBudget(100, 10),
            ) shouldBe Availability.Available(DataValue.Boolean(false))
            value =
                DataValue.ListValue(
                    listOf(
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("unfinished"),
                            DataValue.Record(mapOf("valid" to DataValue.Unfilled)),
                        ),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.Collection(
                    com.typewritermc.expression.OperationId("typewriter.collection.any"),
                    input,
                    listOf(item),
                    emptyList(),
                    ExpressionNode.Read(
                        item,
                        com.typewritermc.authoring.ValuePath(
                            listOf(
                                com.typewritermc.authoring.PathSegment
                                    .Field("valid"),
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
                                com.typewritermc.authoring.ValuePath(
                                    listOf(
                                        com.typewritermc.authoring.PathSegment
                                            .Item(com.typewritermc.authoring.ItemId("unfinished")),
                                        com.typewritermc.authoring.PathSegment
                                            .Field("valid"),
                                    ),
                                ),
                        ),
                    ),
                )

            value =
                DataValue.ListValue(
                    listOf(
                        com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("yes"), DataValue.Boolean(true)),
                        com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("no"), DataValue.Boolean(false)),
                    ),
                )
            evaluator.evaluate(
                ExpressionNode.Collection(
                    com.typewritermc.expression.OperationId("typewriter.collection.any"),
                    input,
                    listOf(item),
                    emptyList(),
                    ExpressionNode.Read(item, com.typewritermc.authoring.ValuePath()),
                ),
                bindings,
                EvaluationBudget(100, 1),
            ) shouldBe Availability.Available(DataValue.Boolean(true))
        }
    }

    test("map access preserves named key identity and retains unfinished key uncertainty") {
        val location = com.typewritermc.authoring.ValueLocation(ResourceId("map:test"), com.typewritermc.authoring.ValuePath())
        val binding = ExpressionBindingId("map")
        var value: DataValue = DataValue.MapValue(emptyList())
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { value.available() })
        val input = ExpressionNode.Read(binding, com.typewritermc.authoring.ValuePath())

        fun access(key: DataValue) =
            ExpressionNode.Call(
                com.typewritermc.expression.OperationId("typewriter.collection.access"),
                listOf(input, ExpressionNode.Literal(key)),
            )

        value =
            DataValue.MapValue(
                listOf(
                    com.typewritermc.types.MapRow(
                        com.typewritermc.authoring.ItemId("target"),
                        DataValue.StringValue("target"),
                        DataValue.StringValue("available"),
                    ),
                    com.typewritermc.types.MapRow(
                        com.typewritermc.authoring.ItemId("duplicate one"),
                        DataValue.StringValue("duplicate"),
                        DataValue.StringValue("one"),
                    ),
                    com.typewritermc.types.MapRow(
                        com.typewritermc.authoring.ItemId("duplicate two"),
                        DataValue.StringValue("duplicate"),
                        DataValue.StringValue("two"),
                    ),
                    com.typewritermc.types.MapRow(
                        com.typewritermc.authoring.ItemId("unfinished"),
                        DataValue.Unfilled,
                        DataValue.Unfilled,
                    ),
                ),
            )
        with(EmptyReads) {
            evaluator.evaluate(
                access(DataValue.StringValue("target")),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe
                Availability.Unavailable(
                    listOf(
                        location.copy(
                            path =
                                com.typewritermc.authoring.ValuePath(
                                    listOf(
                                        com.typewritermc.authoring.PathSegment
                                            .Item(com.typewritermc.authoring.ItemId("target")),
                                        com.typewritermc.authoring.PathSegment.MapValue,
                                    ),
                                ),
                        ),
                        location.copy(
                            path =
                                com.typewritermc.authoring.ValuePath(
                                    listOf(
                                        com.typewritermc.authoring.PathSegment
                                            .Item(com.typewritermc.authoring.ItemId("unfinished")),
                                        com.typewritermc.authoring.PathSegment.MapKey,
                                    ),
                                ),
                        ),
                    ),
                )

            value =
                (value as DataValue.MapValue).copy(
                    rows =
                        (value as DataValue.MapValue).rows.map { row ->
                            if (row.id.value == "unfinished") row.copy(key = DataValue.StringValue("other")) else row
                        },
                )
            evaluator.evaluate(
                access(DataValue.StringValue("target")),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.StringValue("available"))

            val namedKey = DataValue.Named(TEST_CODE_USE, DataValue.StringValue("wrapped"))
            value =
                DataValue.MapValue(
                    listOf(
                        com.typewritermc.types.MapRow(
                            com.typewritermc.authoring.ItemId("named"),
                            namedKey,
                            DataValue.StringValue("named value"),
                        ),
                    ),
                )
            evaluator.evaluate(
                access(namedKey),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.StringValue("named value"))

            value =
                DataValue.MapValue(
                    listOf(
                        com.typewritermc.types.MapRow(
                            com.typewritermc.authoring.ItemId("first"),
                            DataValue.StringValue("same"),
                            DataValue.StringValue("one"),
                        ),
                        com.typewritermc.types.MapRow(
                            com.typewritermc.authoring.ItemId("second"),
                            DataValue.StringValue("same"),
                            DataValue.StringValue("two"),
                        ),
                    ),
                )
            evaluator.evaluate(
                access(DataValue.StringValue("same")),
                ExpressionBindings(mapOf(binding to location)),
                EvaluationBudget(100, 100),
            ) shouldBe
                Availability.Unavailable(
                    listOf("first", "second").map { id ->
                        location.copy(
                            path =
                                com.typewritermc.authoring.ValuePath(
                                    listOf(
                                        com.typewritermc.authoring.PathSegment
                                            .Item(com.typewritermc.authoring.ItemId(id)),
                                        com.typewritermc.authoring.PathSegment.MapValue,
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
                    integerField(scope, RelativeFieldPattern(listOf(FieldPatternSegment.Field("count"))))
                        .check { it > 0 }
                        .error("positive count")
                    return scope.collected()
                }
            }
        val chapterProvider =
            object : ConfigurationProvider {
                override fun collect(scope: ConfigurationCollectionScope): com.typewritermc.configuration.CollectedConfiguration {
                    textField(scope, RelativeFieldPattern(), TypeTemplate.Scalar(ScalarKind.Text))
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
            ).assemble(CatalogAssemblyContext(CatalogGeneration("typed checks")))
        val integer =
            assembly.checked
                .resolve(INT_USE)
                .ready()
                .complete(DataValue.Integer(5.toBigInteger()))
                .complete()
        val chapterUse = TEST_CODE_USE
        val chapter =
            assembly.checked
                .resolve(chapterUse)
                .ready()
                .complete(DataValue.Named(chapterUse, DataValue.StringValue("chapter")))
                .complete()

        assembly.checks
            .single { it.recipe.owner.owner == counter.id }
            .recipe.predicate
            .invoke(listOf(integer)) shouldBe true
        val chapterCheck = assembly.checks.single { it.recipe.owner.owner == TEST_CODE_ID }.recipe
        chapterCheck.inputs.single().expected shouldBe TypeTemplate.Scalar(ScalarKind.Text)
        chapterCheck.predicate.invoke(listOf(chapter)) shouldBe true

        val helpers = DefaultConfigurationCollectionScope(counter.id)
        integerField(helpers, RelativeFieldPattern(listOf(FieldPatternSegment.Field("count")))).minimum(3)
        val rule =
            helpers
                .collected()
                .recipes
                .single()
                .rules
                .single()
                .descriptor.predicate
        val configured = ExpressionBindingId("configured_value")
        val location = com.typewritermc.authoring.ValueLocation(ResourceId("counter:1"), com.typewritermc.authoring.ValuePath())
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { DataValue.Integer(5.toBigInteger()).available() })
        with(EmptyReads) {
            evaluator.evaluate(rule, ExpressionBindings(mapOf(configured to location)), EvaluationBudget(100, 100)) shouldBe
                Availability.Available(DataValue.Boolean(true))
        }

        val unsigned = DefaultConfigurationCollectionScope(counter.id)
        unsignedIntegerField(unsigned, RelativeFieldPattern(listOf(FieldPatternSegment.Field("count"))))
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
                ExpressionValueReader { DataValue.Integer(ULong.MAX_VALUE.toString().toBigInteger()).available() },
            )
        with(EmptyReads) {
            unsignedEvaluator.evaluate(
                unsignedRule,
                ExpressionBindings(mapOf(configured to location)),
                EvaluationBudget(100, 100),
            ) shouldBe Availability.Available(DataValue.Boolean(true))
        }
    }

    test("nullable scalar and nested record configuration retain physical authored paths") {
        val owner = definitionId("Nullable")
        val scalar = DefaultConfigurationCollectionScope(owner)
        nullableTextField(scalar, RelativeFieldPattern(listOf(FieldPatternSegment.Field("text")))).whenPresent {
            nonBlank()
            check { it.isNotBlank() }.error("present text is nonblank")
        }
        val scalarConfiguration = scalar.collected()
        scalarConfiguration.recipes
            .single()
            .relativePath.segments shouldBe listOf(FieldPatternSegment.Field("text"))
        scalarConfiguration.checks
            .single()
            .inputs
            .single()
            .skipNull shouldBe true

        val nested = DefaultConfigurationCollectionScope(owner)
        integerField(
            nested.nested(RelativeFieldPattern(listOf(FieldPatternSegment.Field("style")))),
            RelativeFieldPattern(listOf(FieldPatternSegment.Field("repetitions"))),
        ).check { it > 0 }.error("present repetitions are positive")
        nested
            .collected()
            .checks
            .single()
            .inputs
            .single()
            .path.segments shouldBe
            listOf(FieldPatternSegment.Field("style"), FieldPatternSegment.Field("repetitions"))
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
            ).assemble(CatalogAssemblyContext(CatalogGeneration("polymorphic native")))
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
        val first = contributions.assemble(CatalogAssemblyContext(CatalogGeneration("first generation")))
        val second = contributions.assemble(CatalogAssemblyContext(CatalogGeneration("second generation")))
        val stale = first.checked.resolve(TypeUse.Named(TEST_TEXT_MESSAGE_ID)).ready()

        shouldThrow<NativeBindingException> { second.bindings.bind(stale) }.code shouldBe "catalog_generation_mismatch"
    }

    test("portable bindings preserve opaque records through generic containers") {
        val origin = providerOrigin("portable_bindings")
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, TEST_PORTABLE_RECORD_DEFINITION)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("portable bindings")))
        val payload = DataValue.Record(mapOf("label" to DataValue.StringValue("opaque")))
        val value = DataValue.Named(TEST_PORTABLE_RECORD_USE, payload)
        val checked = assembly.checked.resolve(TEST_PORTABLE_RECORD_USE).ready()

        @Suppress("UNCHECKED_CAST")
        val binding = assembly.bindings.bind(checked) as NativeBinding<PortableValue>
        val decoded = binding.decode(checked.complete(value).complete())
        decoded shouldBe PortableValue(TEST_PORTABLE_RECORD_USE, payload)
        binding.encode(decoded) shouldBe value

        val listChecked = assembly.checked.resolve(TEST_PORTABLE_RECORD_LIST_USE).ready()
        val authoredList =
            DataValue.Named(
                TEST_PORTABLE_RECORD_LIST_USE,
                DataValue.ListValue(
                    listOf(
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("opaque"),
                            value,
                        ),
                    ),
                ),
            )

        @Suppress("UNCHECKED_CAST")
        val listBinding = assembly.bindings.bind(listChecked) as NativeBinding<List<PortableValue>>
        val portableList = listBinding.decode(listChecked.complete(authoredList).complete())
        portableList shouldBe listOf(PortableValue(TEST_PORTABLE_RECORD_USE, payload))
        listBinding.encode(portableList) shouldBe
            DataValue.Named(
                TEST_PORTABLE_RECORD_LIST_USE,
                DataValue.ListValue(
                    listOf(
                        com.typewritermc.types.ListItem(
                            com.typewritermc.authoring.ItemId("native:0"),
                            value,
                        ),
                    ),
                ),
            )

        shouldThrow<NativeBindingException> {
            binding.encode(PortableValue(TEST_CODE_USE, payload))
        }.code shouldBe "wrong_portable_actual_type"
        val invalid = checked.complete(DataValue.Named(TEST_PORTABLE_RECORD_USE, DataValue.Record(emptyMap())))
        (invalid as CompletenessResult.Invalid).problems.single().code shouldBe "missing_field"
    }

    test("native set and map reject canonical duplicate non data record values") {
        val origin = providerOrigin("canonical_native_duplicates")
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, TEST_IDENTITY_KEY_DEFINITION)),
                nativeBindings = listOf(OwnedNativeBinding(origin, TestIdentityKeyNativeBindingFactory)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("canonical native duplicates")))
        val first =
            DataValue.Named(
                TEST_IDENTITY_KEY_USE,
                DataValue.Record(mapOf("value" to DataValue.StringValue("same"))),
            )
        val second =
            DataValue.Named(
                TEST_IDENTITY_KEY_USE,
                DataValue.Record(mapOf("value" to DataValue.StringValue("same"))),
            )

        val setChecked = assembly.checked.resolve(TEST_IDENTITY_KEY_SET_USE).ready()
        val setValue =
            DataValue.Named(
                TEST_IDENTITY_KEY_SET_USE,
                DataValue.SetValue(
                    listOf(
                        com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("first"), first),
                        com.typewritermc.types.ListItem(com.typewritermc.authoring.ItemId("second"), second),
                    ),
                ),
            )
        val setBinding = assembly.bindings.bind(setChecked)
        shouldThrow<NativeBindingException> {
            setBinding.decode(setChecked.complete(setValue).complete())
        }.code shouldBe "duplicate_set_value"

        val mapChecked = assembly.checked.resolve(TEST_IDENTITY_KEY_MAP_USE).ready()
        val mapValue =
            DataValue.Named(
                TEST_IDENTITY_KEY_MAP_USE,
                DataValue.MapValue(
                    listOf(
                        com.typewritermc.types.MapRow(
                            com.typewritermc.authoring.ItemId("first"),
                            first,
                            DataValue.StringValue("one"),
                        ),
                        com.typewritermc.types.MapRow(
                            com.typewritermc.authoring.ItemId("second"),
                            second,
                            DataValue.StringValue("two"),
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
                CatalogAssemblyContext(CatalogGeneration("float32 native width")),
            )
        val use = TypeUse.Scalar(ScalarKind.Float(FloatWidth.FLOAT_32))
        val checked = assembly.checked.resolve(use).ready()

        @Suppress("UNCHECKED_CAST")
        val binding = assembly.bindings.bind(checked) as NativeBinding<Float>
        val original = 1.25f
        val encoded = binding.encode(original)
        encoded shouldBe DataValue.Float(original.toDouble())
        binding.decode(checked.complete(encoded).complete()) shouldBe original

        val imprecise = checked.complete(DataValue.Float(0.1)) as CompletenessResult.Invalid
        imprecise.problems.single().code shouldBe "float32_precision_loss"
    }

    test("catalog assembly isolates duplicate declarations and incompatible inherited fields") {
        val origin = providerOrigin("catalog_conflicts")
        val left = recordDefinition("Left", "value", TypeTemplate.Scalar(ScalarKind.Text))
        val right = recordDefinition("Right", "value", INT)
        val childId = definitionId("Child")
        val child =
            TypeDefinition(
                childId,
                representation = RepresentationTemplate.Record(emptyList(), abstract = false),
                parents = listOf(TypeTemplate.Named(left.id), TypeTemplate.Named(right.id)),
            )
        val duplicate = recordDefinition("Duplicate", "value", TypeTemplate.Scalar(ScalarKind.Text))
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
            ).assemble(CatalogAssemblyContext(CatalogGeneration("catalog conflicts")))

        assembly.snapshot.types
            .single { it.definition.id == childId }
            .status shouldBe
            DeclarationStatus.Unavailable(
                listOf(
                    com.typewritermc.types.catalog.DeclarationDiagnostic(
                        childId,
                        "ambiguous_inherited_field",
                        field = RelativeFieldPattern(listOf(FieldPatternSegment.Field("value"))),
                    ),
                ),
            )
        assembly.snapshot.types.count { it.definition.id == duplicate.id } shouldBe 1
        (
            assembly.snapshot.types
                .single { it.definition.id == duplicate.id }
                .status is DeclarationStatus.Unavailable
        ) shouldBe true
    }

    test("catalog assembly isolates inherited field presentation conflicts and accepts an explicit child choice") {
        val origin = providerOrigin("field_presentation_conflicts")
        val root = recordDefinition("PresentationRoot", "value", TypeTemplate.Scalar(ScalarKind.Text))
        val textNamed =
            TypeDefinition(
                definitionId("TextNamed"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(root.id)),
            )
        val choiceNamed =
            TypeDefinition(
                definitionId("ChoiceNamed"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(root.id)),
            )
        val conflicted =
            TypeDefinition(
                definitionId("ConflictedPresentationChild"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(textNamed.id), TypeTemplate.Named(choiceNamed.id)),
            )
        val resolved =
            TypeDefinition(
                definitionId("ResolvedPresentationChild"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(textNamed.id), TypeTemplate.Named(choiceNamed.id)),
            )
        val unrelated =
            TypeDefinition(
                definitionId("UnrelatedPresentationChild"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(root.id)),
            )
        val textProvider = com.typewritermc.types.PresentationId("test", "text named")
        val choiceProvider = com.typewritermc.types.PresentationId("test", "choice named")
        val resolvedProvider = com.typewritermc.types.PresentationId("test", "resolved child")
        val textEditor = com.typewritermc.types.PresentationId("test", "text editor")
        val choiceEditor = com.typewritermc.types.PresentationId("test", "choice editor")
        val resolvedEditor = com.typewritermc.types.PresentationId("test", "resolved editor")
        val textTarget = PresentationTarget.Named(TypeTemplate.Named(textNamed.id))
        val choiceTarget = PresentationTarget.Named(TypeTemplate.Named(choiceNamed.id))
        val resolvedTarget = PresentationTarget.Named(TypeTemplate.Named(resolved.id))
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
            ).assemble(CatalogAssemblyContext(CatalogGeneration("field presentation conflicts")))

        val conflictStatus =
            assembly.snapshot.types
                .single { it.definition.id == conflicted.id }
                .status
        (conflictStatus as DeclarationStatus.Unavailable).reasons.map { it.code } shouldBe
            listOf("conflicting_field_presentation")
        assembly.snapshot.types
            .single { it.definition.id == resolved.id }
            .status shouldBe DeclarationStatus.Ready
        assembly.snapshot.types
            .single { it.definition.id == unrelated.id }
            .status shouldBe DeclarationStatus.Ready
    }

    test("catalog assembly owns one immutable portable snapshot graph") {
        val id = definitionId("ImmutableSnapshot")
        val argumentList = mutableListOf<TypeTemplate>(TypeTemplate.Scalar(ScalarKind.Text))
        val fieldList =
            mutableListOf(
                FieldDeclaration(
                    FieldOwner(id, "items"),
                    TypeTemplate.Named(StandardTypes.list, argumentList),
                ),
            )
        val definition = TypeDefinition(id, representation = RepresentationTemplate.Record(fieldList))
        val bytes = mutableListOf<Byte>(1, 2)
        val fallbackParents = mutableListOf(com.typewritermc.types.PresentationRole.EDITOR)
        val endpointPath = mutableListOf<com.typewritermc.configuration.FieldPatternSegment>(FieldPatternSegment.Field("items"))
        val rules =
            mutableListOf(
                com.typewritermc.configuration.OwnedRule(
                    com.typewritermc.configuration.RuleId(com.typewritermc.configuration.RuleOrigin(id, 0), 0),
                    com.typewritermc.configuration.RuleDescriptor(ExpressionNode.Literal(DataValue.Boolean(true))),
                    com.typewritermc.checking.DiagnosticTemplate(
                        "valid",
                        "valid",
                        com.typewritermc.checking.DiagnosticSeverity.Error,
                        mutableListOf(RelativeFieldPattern()),
                    ),
                ),
            )
        val recipe =
            com.typewritermc.configuration.ConfigurationRecipe(
                com.typewritermc.configuration.RuleOrigin(id, 0),
                RelativeFieldPattern(),
                RepresentationKind.Record,
                rules,
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
                    generation = CatalogGeneration("immutable snapshot"),
                    initialization =
                        mutableListOf(
                            com.typewritermc.authoring.InitializationDescriptor(
                                id,
                                com.typewritermc.authoring.InitializationMode.Startup,
                                mutableListOf(
                                    com.typewritermc.configuration.CapturedDefault(
                                        FieldOwner(id, "items"),
                                        DataValue.Bytes(bytes),
                                    ),
                                ),
                                mutableListOf(),
                            ),
                        ),
                    endpointBindings =
                        mutableListOf(
                            com.typewritermc.types.EndpointBindingTemplate(
                                com.typewritermc.types.EndpointId("immutable:endpoint"),
                                TypeTemplate.Named(id),
                                id,
                                RelativeFieldPattern(endpointPath),
                                TypeTemplate.Named(StandardTypes.list, argumentList),
                                true,
                            ),
                        ),
                    roleFallbacks =
                        mutableListOf(
                            com.typewritermc.presentation.RoleFallback(
                                com.typewritermc.types.PresentationRole.INSPECTOR,
                                fallbackParents,
                            ),
                        ),
                ),
            )

        fieldList += FieldDeclaration(FieldOwner(id, "late"), TypeTemplate.Scalar(ScalarKind.Text))
        argumentList[0] = INT
        bytes[0] = 9
        fallbackParents += com.typewritermc.types.PresentationRole.CATALOG_OPTION
        endpointPath += FieldPatternSegment.Items
        rules.clear()

        val published = assembly.snapshot.types.single { it.definition.id == id }
        val publishedField = (published.definition.representation as RepresentationTemplate.Record).fields.single()
        (publishedField.type as TypeTemplate.Named).arguments shouldBe listOf(TypeTemplate.Scalar(ScalarKind.Text))
        assembly.snapshot.configuration
            .single()
            .rules.size shouldBe 1
        (
            assembly.snapshot.initialization
                .single { it.definition == id }
                .captured
                .single()
                .value as DataValue.Bytes
        ).value shouldBe
            listOf<Byte>(1, 2)
        assembly.snapshot.endpointBindings
            .single()
            .relativePath.segments shouldBe
            listOf(FieldPatternSegment.Field("items"))
        assembly.snapshot.roleFallbacks
            .single()
            .parents shouldBe
            listOf(com.typewritermc.types.PresentationRole.EDITOR)
        val checked = assembly.checked.resolve(TypeUse.Named(id)).ready()
        (checked.schema.representation as com.typewritermc.types.catalog.ResolvedRepresentation.Record).fields.size shouldBe 1
    }

    test("catalog assembly reasons across inherited mandatory rules") {
        val parent = recordDefinition("BoundedParent", "value", INT)
        val child =
            TypeDefinition(
                definitionId("BoundedChild"),
                representation = RepresentationTemplate.Record(emptyList()),
                parents = listOf(TypeTemplate.Named(parent.id)),
            )
        val origin = providerOrigin("inherited_rules")
        val minimum =
            configurationProvider { scope ->
                integerField(scope, RelativeFieldPattern(listOf(FieldPatternSegment.Field("value")))).minimum(10)
            }
        val maximum =
            configurationProvider { scope ->
                integerField(scope, RelativeFieldPattern(listOf(FieldPatternSegment.Field("value")))).maximum(5)
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, parent), OwnedTypeDeclaration(origin, child)),
                configurations =
                    listOf(
                        OwnedConfiguration(origin, parent.id, minimum),
                        OwnedConfiguration(providerOrigin("child_rules"), child.id, maximum),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("inherited rules")))

        assembly.snapshot.types
            .single { it.definition.id == parent.id }
            .status shouldBe DeclarationStatus.Ready
        val childStatus =
            assembly.snapshot.types
                .single { it.definition.id == child.id }
                .status as DeclarationStatus.Unavailable
        childStatus.reasons.map { it.code } shouldBe listOf("contradictory_configuration_rules")
    }

    test("generic representation rules receive semantic validation") {
        val genericId = definitionId("GenericTextRule")
        val parameter = com.typewritermc.types.ParameterKey(genericId, 0)
        val generic =
            TypeDefinition(
                genericId,
                parameters = listOf(com.typewritermc.types.TypeParameter(parameter, "T")),
                representation =
                    RepresentationTemplate.Record(
                        listOf(FieldDeclaration(FieldOwner(genericId, "value"), TypeTemplate.Parameter(parameter))),
                    ),
            )
        val origin = providerOrigin("generic_rules")
        val rules =
            configurationProvider { scope ->
                textField(
                    scope,
                    RelativeFieldPattern(listOf(FieldPatternSegment.Field("value"))),
                    TypeTemplate.Scalar(ScalarKind.Text),
                ).apply {
                    minimumLength(10)
                    maximumLength(5)
                }
            }
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, generic)),
                configurations = listOf(OwnedConfiguration(origin, generic.id, rules)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration("generic rules")))

        val status =
            assembly.snapshot.types
                .single { it.definition.id == generic.id }
                .status as DeclarationStatus.Unavailable
        status.reasons.map { it.code } shouldBe listOf("contradictory_configuration_rules")
    }

    test("forced creation propagates while explicit startup overrides inferred preference") {
        val dynamicChild = definitionId("dynamic child")
        val startupParent = definitionId("startup parent")
        val forcedChild = definitionId("forced child")
        val forcedParent = definitionId("forced parent")
        val result =
            WorklistDefaultModeResolver().resolveWithDiagnostics(
                mapOf(
                    dynamicChild to InitializationRequirements(false, InitializationPreference.Creation, emptySet()),
                    startupParent to InitializationRequirements(false, InitializationPreference.Startup, setOf(dynamicChild)),
                    forcedChild to InitializationRequirements(true, null, emptySet()),
                    forcedParent to InitializationRequirements(false, null, setOf(forcedChild)),
                ),
            )

        result.modes.getValue(startupParent) shouldBe com.typewritermc.authoring.InitializationMode.Startup
        result.modes.getValue(forcedChild) shouldBe com.typewritermc.authoring.InitializationMode.Creation
        result.modes.getValue(forcedParent) shouldBe com.typewritermc.authoring.InitializationMode.Creation
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
        RepresentationKind.Integer,
        INT,
        Integer::class as KClass<Integer<Int>>,
    )
}

private fun textField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern,
    expected: TypeTemplate,
): Text = scope.field(path, RepresentationKind.Text, expected, Text::class)

private fun unsignedIntegerField(
    scope: ConfigurationCollectionScope,
    path: RelativeFieldPattern,
): Integer<ULong> {
    @Suppress("UNCHECKED_CAST")
    return scope.field(
        path,
        RepresentationKind.Integer,
        TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.UNSIGNED_64)),
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
        RepresentationKind.Text,
        TypeTemplate.Nullable(TypeTemplate.Scalar(ScalarKind.Text)),
        NullableField::class as KClass<NullableField<String, Text>>,
        mapOf(
            FieldPatternSegment.Values to
                NestedConfigurationScope(RepresentationKind.Text, TypeTemplate.Scalar(ScalarKind.Text)) { nested ->
                    textField(nested, RelativeFieldPattern(), TypeTemplate.Scalar(ScalarKind.Text))
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
    return TypeDefinition(
        id,
        representation =
            RepresentationTemplate.Record(
                listOf(FieldDeclaration(FieldOwner(id, field), type)),
                abstract = false,
            ),
    )
}

private fun fieldPresentationMaterial(
    provider: com.typewritermc.types.PresentationId,
    target: PresentationTarget,
    selected: com.typewritermc.types.PresentationId,
): PresentationMaterial {
    val binding =
        skirout.editor.v1.binding.BindingRef(
            path =
                skirout.editor.v1.type_catalog.ValuePath(
                    segments =
                        listOf(
                            skirout.editor.v1.type_catalog.PathSegment.FieldWrapper(
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
                    binding = binding,
                    presentationId =
                        skirout.editor.v1.type_catalog.PresentationId(
                            namespace = selected.namespace,
                            name = selected.name,
                        ),
                ),
            header = null,
        )
    return PresentationMaterial(
        provider = provider,
        target = target,
        subject = (target as PresentationTarget.Named).type,
        role = com.typewritermc.types.PresentationRole.INSPECTOR,
        layout = layout,
        dependencies =
            skirout.editor.v1.presentation.PresentationDependencies
                .partial(),
    )
}

private fun ownedPresentation(
    origin: ProviderOrigin,
    id: com.typewritermc.types.PresentationId,
    target: PresentationTarget,
    material: PresentationMaterial,
): OwnedPresentation {
    val descriptor =
        PresentationDescriptor(
            id = id,
            owner = origin.owner,
            target = target,
            roles = setOf(com.typewritermc.types.PresentationRole.INSPECTOR),
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
    val key = ContributionKey(ContributionSourceId("test"), "main", ProducerId("sdk"), ContributionName(name))
    return ProviderOrigin(DeclarationOwner(key, name), ArtifactId("test:sdk"), "main")
}

private fun definitionId(name: String): TypeDefinitionId = TypeDefinitionId(TypeId.Qualified("test", name), 1)

private fun <T> com.typewritermc.types.catalog.Resolution<T>.ready(): T = (this as com.typewritermc.types.catalog.Resolution.Ready).value

private fun com.typewritermc.authoring.CompletenessResult.complete() = (this as CompletenessResult.Complete).value

private fun DataValue.available(): Availability<DataValue> = Availability.Available(this)

private object EmptyReads : AuthoredReads {
    override val snapshot: SnapshotId = SnapshotId("expression snapshot")
    override val catalog: CatalogGeneration = CatalogGeneration("expression catalog")
    override val readContext = com.typewritermc.authoring.ReadContext(snapshot, catalog)

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

    override fun members(path: BoundCollectionPath): List<com.typewritermc.authoring.ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Selections are not used in this fixture.")
}

@JvmInline
private value class TestCode(
    val value: String,
)

private object TestCodeNativeBindingFactory : NativeBindingFactory {
    override val definition: TypeDefinitionId = TEST_CODE_ID
    override val provider: NativeBindingId = NativeBindingId("test.code")

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
    override val provider = NativeBindingId("test.text_message")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.text_message",
            nativeClass = TestTextMessage::class,
            fields = listOf(GeneratedNativeField("text", arguments.resolver.bind(TEXT_USE), TestTextMessage::text)),
            construct = { TestTextMessage(it.getValue("text") as String) },
        )
}

private object TestTranslationMessageNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_TRANSLATION_MESSAGE_ID
    override val provider = NativeBindingId("test.translation_message")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.translation_message",
            nativeClass = TestTranslationMessage::class,
            fields = listOf(GeneratedNativeField("key", arguments.resolver.bind(TEXT_USE), TestTranslationMessage::key)),
            construct = { TestTranslationMessage(it.getValue("key") as String) },
        )
}

private object TestMessageActionNativeBindingFactory : NativeBindingFactory {
    override val definition = TEST_MESSAGE_ACTION_ID
    override val provider = NativeBindingId("test.message_action")

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
                    GeneratedNativeField("message", arguments.resolver.bind(TEST_MESSAGE_USE), TestMessageAction::message),
                    GeneratedNativeField("messages", arguments.resolver.bind(TEST_MESSAGE_LIST_USE), TestMessageAction::messages),
                    GeneratedNativeField("optional", arguments.resolver.bind(TEST_OPTIONAL_MESSAGE_USE), TestMessageAction::optional),
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
    override val provider = NativeBindingId("test.tree")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> {
        val treeUse = actual.use as TypeUse.Named
        val childrenUse = TypeUse.Named(StandardTypes.list, listOf(treeUse))
        return GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.tree",
            nativeClass = TestTree::class,
            fields =
                listOf(
                    GeneratedNativeField<TestTree<*>>("value", arguments.bindings.single()) { it.value },
                    GeneratedNativeField<TestTree<*>>("children", arguments.resolver.bind(childrenUse)) { it.children },
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
    override val provider = NativeBindingId("test.identity_key")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        GeneratedRecordNativeBinding(
            checked = actual,
            provider = provider,
            signature = "test.identity_key",
            nativeClass = TestIdentityKey::class,
            fields = listOf(GeneratedNativeField("value", arguments.resolver.bind(TEXT_USE), TestIdentityKey::value)),
            construct = { TestIdentityKey(it.getValue("value") as String) },
        )
}

private val INT = TypeTemplate.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
private val INT_USE = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
private val TEXT_USE = TypeUse.Scalar(ScalarKind.Text)
private val TEST_CODE_ID = definitionId("TestCode")
private val TEST_CODE_USE = TypeUse.Named(TEST_CODE_ID)
private val TEST_CODE_DEFINITION = TypeDefinition(TEST_CODE_ID, representation = RepresentationTemplate.Scalar(ScalarKind.Text))
private val TEST_MESSAGE_ID = definitionId("TestMessage")
private val TEST_TEXT_MESSAGE_ID = definitionId("TestTextMessage")
private val TEST_TRANSLATION_MESSAGE_ID = definitionId("TestTranslationMessage")
private val TEST_MESSAGE_ACTION_ID = definitionId("TestMessageAction")
private val TEST_TREE_ID = definitionId("TestTree")
private val TEST_IDENTITY_KEY_ID = definitionId("TestIdentityKey")
private val TEST_PORTABLE_RECORD_ID = definitionId("TestPortableRecord")
private val TEST_TREE_PARAMETER = com.typewritermc.types.ParameterKey(TEST_TREE_ID, 0)
private val TEST_MESSAGE_USE = TypeUse.Named(TEST_MESSAGE_ID)
private val TEST_MESSAGE_LIST_USE = TypeUse.Named(StandardTypes.list, listOf(TEST_MESSAGE_USE))
private val TEST_OPTIONAL_MESSAGE_USE = TypeUse.Nullable(TEST_MESSAGE_USE)
private val TEST_MESSAGE_ACTION_USE = TypeUse.Named(TEST_MESSAGE_ACTION_ID)
private val TEST_TEXT_TREE_USE = TypeUse.Named(TEST_TREE_ID, listOf(TEXT_USE))
private val TEST_IDENTITY_KEY_USE = TypeUse.Named(TEST_IDENTITY_KEY_ID)
private val TEST_IDENTITY_KEY_SET_USE = TypeUse.Named(StandardTypes.set, listOf(TEST_IDENTITY_KEY_USE))
private val TEST_IDENTITY_KEY_MAP_USE = TypeUse.Named(StandardTypes.map, listOf(TEST_IDENTITY_KEY_USE, TEXT_USE))
private val TEST_PORTABLE_RECORD_USE = TypeUse.Named(TEST_PORTABLE_RECORD_ID)
private val TEST_PORTABLE_RECORD_LIST_USE = TypeUse.Named(StandardTypes.list, listOf(TEST_PORTABLE_RECORD_USE))
private val TEST_PORTABLE_RECORD_DEFINITION =
    TypeDefinition(
        TEST_PORTABLE_RECORD_ID,
        representation =
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(
                        FieldOwner(TEST_PORTABLE_RECORD_ID, "label"),
                        TypeTemplate.Scalar(ScalarKind.Text),
                    ),
                ),
            ),
    )
private val TEST_IDENTITY_KEY_DEFINITION =
    TypeDefinition(
        TEST_IDENTITY_KEY_ID,
        representation =
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(
                        FieldOwner(TEST_IDENTITY_KEY_ID, "value"),
                        TypeTemplate.Scalar(ScalarKind.Text),
                    ),
                ),
            ),
    )
private val TEST_MESSAGE_DEFINITION =
    TypeDefinition(TEST_MESSAGE_ID, representation = RepresentationTemplate.Record(emptyList(), abstract = true))
private val TEST_TEXT_MESSAGE_DEFINITION =
    TypeDefinition(
        TEST_TEXT_MESSAGE_ID,
        representation =
            RepresentationTemplate.Record(
                listOf(FieldDeclaration(FieldOwner(TEST_TEXT_MESSAGE_ID, "text"), TypeTemplate.Scalar(ScalarKind.Text))),
            ),
        parents = listOf(TypeTemplate.Named(TEST_MESSAGE_ID)),
    )
private val TEST_TRANSLATION_MESSAGE_DEFINITION =
    TypeDefinition(
        TEST_TRANSLATION_MESSAGE_ID,
        representation =
            RepresentationTemplate.Record(
                listOf(FieldDeclaration(FieldOwner(TEST_TRANSLATION_MESSAGE_ID, "key"), TypeTemplate.Scalar(ScalarKind.Text))),
            ),
        parents = listOf(TypeTemplate.Named(TEST_MESSAGE_ID)),
    )
private val TEST_MESSAGE_ACTION_DEFINITION =
    TypeDefinition(
        TEST_MESSAGE_ACTION_ID,
        representation =
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(FieldOwner(TEST_MESSAGE_ACTION_ID, "message"), TypeTemplate.Named(TEST_MESSAGE_ID)),
                    FieldDeclaration(
                        FieldOwner(TEST_MESSAGE_ACTION_ID, "messages"),
                        TypeTemplate.Named(StandardTypes.list, listOf(TypeTemplate.Named(TEST_MESSAGE_ID))),
                    ),
                    FieldDeclaration(
                        FieldOwner(TEST_MESSAGE_ACTION_ID, "optional"),
                        TypeTemplate.Nullable(TypeTemplate.Named(TEST_MESSAGE_ID)),
                    ),
                ),
            ),
    )
private val TEST_TREE_DEFINITION =
    TypeDefinition(
        TEST_TREE_ID,
        parameters = listOf(com.typewritermc.types.TypeParameter(TEST_TREE_PARAMETER, "T")),
        representation =
            RepresentationTemplate.Record(
                listOf(
                    FieldDeclaration(FieldOwner(TEST_TREE_ID, "value"), TypeTemplate.Parameter(TEST_TREE_PARAMETER)),
                    FieldDeclaration(
                        FieldOwner(TEST_TREE_ID, "children"),
                        TypeTemplate.Named(
                            StandardTypes.list,
                            listOf(TypeTemplate.Named(TEST_TREE_ID, listOf(TypeTemplate.Parameter(TEST_TREE_PARAMETER)))),
                        ),
                    ),
                ),
            ),
    )
