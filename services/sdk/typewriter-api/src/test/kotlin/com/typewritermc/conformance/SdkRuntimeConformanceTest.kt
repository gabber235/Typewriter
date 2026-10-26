@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.CheckInput
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
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
import com.typewritermc.expression.PortableExpressionLimits
import com.typewritermc.expression.eq
import com.typewritermc.expression.literal
import com.typewritermc.expression.operations.EvaluatorFailure
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.testInput
import com.typewritermc.expression.testLiteral
import com.typewritermc.expression.testPortableTypes
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
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.typed_value.PortableValue
import kotlin.reflect.KClass

val SdkRuntimeConformanceTest by testSuite {
    test("a generated resource selection matches exactly the resources whose configured field equals the value") {
        val predicate =
            requireNotNull(
                com.typewritermc.library.BookDraftType
                    .where { title eq literal("Requested") }
                    .predicate,
            )

        fun matches(title: String): Availability<DataValue> {
            val evaluator =
                DefaultExpressionEvaluator(ExpressionValueReader { DataValue.StringValueWrapper(title).available() }, testPortableTypes())
            return with(EmptyReads) {
                evaluator.evaluate(
                    predicate,
                    ExpressionBindings(
                        mapOf(
                            ExpressionBindingId(
                                value = "configured_value",
                            ) to ValueLocation.of(ResourceId("book:requested"), ValuePath.root),
                        ),
                    ),
                    EvaluationBudget(maxSteps = 100, maxCollectionItems = 100),
                )
            }
        }

        matches("Requested") shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        matches("Other") shouldBe Availability.Available(DataValue.BooleanWrapper(false))
    }

    val readLocation = ValueLocation.of(ResourceId("expression:test"))
    val read = testInput(ExpressionBindingId(value = "value"), ValuePath.root)

    /** What [expression] evaluates to when its one input read gives [result]; every read is recorded in [reads]. */
    fun evaluateReading(
        expression: ExpressionNode,
        result: Availability<DataValue>,
        reads: MutableList<ValueLocation> = mutableListOf(),
    ): Availability<DataValue> {
        val evaluator =
            DefaultExpressionEvaluator(
                ExpressionValueReader { location ->
                    reads += location
                    result
                },
                testPortableTypes(),
            )
        return with(EmptyReads) {
            evaluator.evaluate(
                expression,
                ExpressionBindings(mapOf(ExpressionBindingId(value = "value") to readLocation)),
                EvaluationBudget(maxSteps = 100, maxCollectionItems = 100),
            )
        }
    }

    test("portable and short circuits on a false left operand without reading the right") {
        val reads = mutableListOf<ValueLocation>()

        evaluateReading(
            ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(false)), right = read),
            DataValue.BooleanWrapper(true).available(),
            reads,
        ) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
        reads shouldBe emptyList()
    }

    test("portable or else falls back when its value is unavailable") {
        evaluateReading(
            ExpressionNode.createOrElse(value = read, fallback = testLiteral(DataValue.StringValueWrapper("fallback"))),
            Availability.Unavailable(listOf(readLocation)),
        ) shouldBe Availability.Available(DataValue.StringValueWrapper("fallback"))
    }

    test("portable or else keeps a failed read instead of falling back") {
        val failed =
            Availability.Failed(
                EvaluationDiagnostic(failure = FailureId(value = "read_failed"), message = "broken", locations = listOf(readLocation)),
            )

        evaluateReading(
            ExpressionNode.createOrElse(value = read, fallback = testLiteral(DataValue.StringValueWrapper("hidden"))),
            failed,
        ) shouldBe failed
    }

    test("portable operations read a named scalar through its representation") {
        evaluateReading(
            ExpressionNode.createCall(
                operation = PortableOperationCatalog.TEXT_LENGTH.id,
                typeArguments = emptyList(),
                arguments = listOf(read),
            ),
            DataValue.named(TEST_CODE_USE, DataValue.StringValueWrapper("chapter")).available(),
        ) shouldBe Availability.Available(DataValue.integer(7.toBigInteger()))
    }

    test("portable evaluation bounds expression depth without evaluating a short circuited branch") {
        var nested: ExpressionNode = testLiteral(DataValue.BooleanWrapper(true))
        repeat(PortableExpressionLimits.MAX_DEPTH + 1) {
            nested = ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(true)), right = nested)
        }
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") }, testPortableTypes())
        with(EmptyReads) {
            val failed =
                evaluator.evaluate(
                    nested,
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(maxSteps = 100_000, maxCollectionItems = 100),
                )
            (failed as Availability.Failed).diagnostic.failure shouldBe EvaluatorFailure.ExpressionDepthLimit
            evaluator.evaluate(
                ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(false)), right = nested),
                ExpressionBindings(emptyMap()),
                EvaluationBudget(maxSteps = 100_000, maxCollectionItems = 100),
            ) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
        }
    }

    val typedChecks =
        run {
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
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, counter), OwnedTypeDeclaration(origin, TEST_CODE_DEFINITION)),
                configurations =
                    listOf(
                        OwnedConfiguration(origin, counter.id, counterProvider),
                        OwnedConfiguration(origin, TEST_CODE_ID, chapterProvider),
                    ),
                nativeBindings = listOf(OwnedNativeBinding(origin, TestCodeNativeBindingFactory)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "typed checks")))
        }

    test("a native check on an integer field receives the exact integer") {
        val check =
            typedChecks.checks
                .single { it.recipe.owner.owner == definitionId("Counter") }
                .recipe.predicate

        fun passes(count: Int) =
            check.invoke(
                listOf(
                    typedChecks.checked
                        .resolve(INT_USE)
                        .ready()
                        .complete(DataValue.integer(count.toBigInteger()))
                        .complete(),
                ),
            )

        passes(5) shouldBe true
        passes(0) shouldBe false
    }

    test("a native check on a named scalar receives its text representation") {
        val check =
            typedChecks.checks
                .single { it.recipe.owner.owner == TEST_CODE_ID }
                .recipe.predicate

        fun passes(code: String) =
            check.invoke(
                listOf(
                    typedChecks.checked
                        .resolve(
                            TEST_CODE_USE.use,
                        ).ready()
                        .complete(DataValue.named(TEST_CODE_USE, DataValue.StringValueWrapper(code)))
                        .complete(),
                ),
            )

        passes("chapter") shouldBe true
        passes(" ") shouldBe false
    }

    /** What the one portable rule [helper] declares gives when its field holds [value]. */
    fun ruleOutcome(
        helper: DefaultConfigurationCollectionScope.() -> Unit,
        value: DataValue,
    ): Availability<DataValue> {
        val scope = DefaultConfigurationCollectionScope(definitionId("Counter"))
        scope.helper()
        val rule =
            scope
                .collected()
                .recipes
                .single()
                .rules
                .single()
                .descriptor.predicate
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { value.available() }, testPortableTypes())
        return with(EmptyReads) {
            evaluator.evaluate(
                rule,
                ExpressionBindings(mapOf(ExpressionBindingId(value = "configured_value") to ValueLocation.of(ResourceId("counter:1")))),
                EvaluationBudget(maxSteps = 100, maxCollectionItems = 100),
            )
        }
    }

    test("an integer minimum accepts its bound and refuses the value below it") {
        val minimumThree: DefaultConfigurationCollectionScope.() -> Unit = {
            integerField(this, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count")))).minimum(3)
        }

        ruleOutcome(minimumThree, DataValue.integer(3.toBigInteger())) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        ruleOutcome(minimumThree, DataValue.integer(2.toBigInteger())) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
    }

    test("an unsigned minimum compares values beyond the signed range exactly") {
        val bound = ULong.MAX_VALUE - 1uL
        val nearMaximum: DefaultConfigurationCollectionScope.() -> Unit = {
            unsignedIntegerField(this, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count")))).minimum(bound)
        }

        ruleOutcome(nearMaximum, DataValue.integer(ULong.MAX_VALUE.toString().toBigInteger())) shouldBe
            Availability.Available(DataValue.BooleanWrapper(true))
        ruleOutcome(nearMaximum, DataValue.integer((bound - 1uL).toString().toBigInteger())) shouldBe
            Availability.Available(DataValue.BooleanWrapper(false))
    }

    test("line count rules accept text within their bounds and refuse text outside them") {
        val atLeastTwoLines: DefaultConfigurationCollectionScope.() -> Unit = {
            textField(
                this,
                RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("text"))),
                ScalarKind.TEXT.template,
            ).minimumLines(2)
        }
        val atMostTwoLines: DefaultConfigurationCollectionScope.() -> Unit = {
            textField(
                this,
                RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("text"))),
                ScalarKind.TEXT.template,
            ).maximumLines(2)
        }

        listOf("one", "one\ntwo").map { ruleOutcome(atLeastTwoLines, DataValue.StringValueWrapper(it)) } shouldBe
            listOf(Availability.Available(DataValue.BooleanWrapper(false)), Availability.Available(DataValue.BooleanWrapper(true)))
        listOf("one\ntwo", "one\ntwo\nthree").map { ruleOutcome(atMostTwoLines, DataValue.StringValueWrapper(it)) } shouldBe
            listOf(Availability.Available(DataValue.BooleanWrapper(true)), Availability.Available(DataValue.BooleanWrapper(false)))
    }

    test("a rule declared when a nullable field is present accepts a missing value and judges a present one") {
        val nonBlankWhenPresent: DefaultConfigurationCollectionScope.() -> Unit = {
            nullableTextField(this, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("text")))).whenPresent { nonBlank() }
        }

        ruleOutcome(nonBlankWhenPresent, DataValue.NULL) shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        ruleOutcome(nonBlankWhenPresent, DataValue.StringValueWrapper("")) shouldBe Availability.Available(DataValue.BooleanWrapper(false))
        ruleOutcome(nonBlankWhenPresent, DataValue.StringValueWrapper("text")) shouldBe
            Availability.Available(DataValue.BooleanWrapper(true))
    }

    test("a check declared when a nullable field is present asks the realm to skip a missing value") {
        val owner = definitionId("Nullable")
        checkInputs(owner) {
            nullableTextField(this, fieldPattern("text")).whenPresent { check { it.isNotBlank() }.error("present text is nonblank") }
        } shouldBe listOf(CheckInput(owner, fieldPattern("text"), ScalarKind.TEXT.template, skipNull = true))
    }

    test("a check declared inside a nested record reads the field through the record that holds it") {
        val owner = definitionId("Nested")
        checkInputs(owner) {
            integerField(
                nested(fieldPattern("style")),
                fieldPattern("repetitions"),
            ).check { it > 0 }.error("present repetitions are positive")
        } shouldBe listOf(CheckInput(owner, fieldPattern("style", "repetitions"), INT))
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

    val polymorphic =
        CatalogContributions(
            declarations =
                listOf(
                    TEST_CODE_DEFINITION,
                    TEST_MESSAGE_DEFINITION,
                    TEST_TEXT_MESSAGE_DEFINITION,
                    TEST_TRANSLATION_MESSAGE_DEFINITION,
                    TEST_MESSAGE_ACTION_DEFINITION,
                    TEST_TREE_DEFINITION,
                ).map { OwnedTypeDeclaration(providerOrigin("binding_misuse"), it) },
            nativeBindings =
                listOf(
                    TestCodeNativeBindingFactory,
                    TestTextMessageNativeBindingFactory,
                    TestTranslationMessageNativeBindingFactory,
                    TestMessageActionNativeBindingFactory,
                    TestTreeNativeBindingFactory,
                ).map { OwnedNativeBinding(providerOrigin("binding_misuse"), it) },
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "binding misuse")))

    /** The complete value [value] admitted as [use], for decoding through a binding of another type. */
    fun admitted(
        use: TypeUse,
        value: DataValue,
    ) = polymorphic.checked
        .resolve(use)
        .ready()
        .complete(value)
        .complete()

    fun bindingOf(use: TypeUse) = polymorphic.bindings.bind(polymorphic.checked.resolve(use).ready())

    mapOf(
        "a polymorphic binding given a value without a concrete type" to
            Triple(TEST_MESSAGE_USE, admitted(TEXT_USE, DataValue.StringValueWrapper("hello")), "missing_polymorphic_type_tag"),
        "a polymorphic binding given a concrete type it cannot read" to
            Triple(
                TEST_MESSAGE_USE,
                admitted(TEST_CODE_USE.use, DataValue.named(TEST_CODE_USE, DataValue.StringValueWrapper("code"))),
                "unreadable_polymorphic_type",
            ),
        "a generated record binding given a record without one of its native fields" to
            Triple(
                TEST_TEXT_MESSAGE_ID.use(),
                admitted(
                    TEST_TRANSLATION_MESSAGE_ID.use(),
                    DataValue.named(
                        TEST_TRANSLATION_MESSAGE_ID.namedUse(),
                        DataValue.record(
                            mapOf("key" to DataValue.StringValueWrapper("k")),
                        ),
                    ),
                ),
                "missing_native_field",
            ),
        "a float32 binding given a float64 beyond the Float range" to
            Triple(
                floatScalar(FloatWidth.THIRTY_TWO).use,
                admitted(floatScalar(FloatWidth.SIXTY_FOUR).use, DataValue.FloatWrapper(1e300)),
                "float32_out_of_range",
            ),
        "a float32 binding given a float64 it cannot represent exactly" to
            Triple(
                floatScalar(FloatWidth.THIRTY_TWO).use,
                admitted(floatScalar(FloatWidth.SIXTY_FOUR).use, DataValue.FloatWrapper(0.1)),
                "float32_precision_loss",
            ),
    ).forEach { (case, misuse) ->
        test("$case refuses to decode it") {
            shouldThrow<NativeBindingException> { bindingOf(misuse.first).decode(misuse.second) }.code shouldBe misuse.third
        }
    }

    test("a link binding refuses to decode a link authored through another endpoint") {
        val resource = definitionId("LinkedResource")
        val links =
            listOf("first", "second").map { endpoint ->
                TypeDefinition.partial(
                    id = definitionId("Link_$endpoint"),
                    representation =
                        RepresentationTemplate.createLink(
                            endpoint =
                                skirout.editor.v1.type_catalog
                                    .EndpointId(value = "link.$endpoint"),
                            target = resource.template(),
                        ),
                )
            }
        val catalog =
            com.typewritermc.types.catalog.DefaultCheckedCatalog(
                CatalogGeneration(value = "link endpoints"),
                listOf(
                    TypeDefinition.partial(
                        id = resource,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ) +
                    links,
            )
        val second = links[1].id.namedUse()
        val authored =
            catalog
                .resolve(second.use)
                .ready()
                .complete(
                    DataValue.named(
                        second,
                        DataValue.createLink(
                            endpoint =
                                skirout.editor.v1.type_catalog
                                    .EndpointId(value = "link.second"),
                            target =
                                skirout.editor.v1.type_catalog.LinkTarget(
                                    resource = ResourceId("resource:1").toSkir(),
                                    opposite = null,
                                ),
                        ),
                    ),
                ).complete()
        val firstBinding =
            com.typewritermc.types
                .FactoryNativeBindingRegistry(
                    catalog,
                    emptyList(),
                ).bind(catalog.resolve(links[0].id.use()).ready())

        shouldThrow<NativeBindingException> { firstBinding.decode(authored) }.code shouldBe "wrong_link_endpoint"
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

    val portableBindings =
        CatalogContributions(
            declarations = listOf(OwnedTypeDeclaration(providerOrigin("portable_bindings"), TEST_PORTABLE_RECORD_DEFINITION)),
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "portable bindings")))
    val opaquePayload = DataValue.record(mapOf("label" to DataValue.StringValueWrapper("opaque")))
    val opaqueRecord = DataValue.named(TEST_PORTABLE_RECORD_USE, opaquePayload)

    @Suppress("UNCHECKED_CAST")
    fun <T> portableBinding(use: NamedTypeUse) =
        portableBindings.bindings.bind(portableBindings.checked.resolve(use.use).ready()) as NativeBinding<T>

    test("a portable binding decodes an opaque record to its actual type and payload and encodes it back unchanged") {
        val binding = portableBinding<PortableValue>(TEST_PORTABLE_RECORD_USE)
        val decoded =
            binding.decode(
                portableBindings.checked
                    .resolve(TEST_PORTABLE_RECORD_USE.use)
                    .ready()
                    .complete(opaqueRecord)
                    .complete(),
            )

        decoded shouldBe PortableValue(actualType = TEST_PORTABLE_RECORD_USE.use, payload = opaquePayload)
        binding.encode(decoded) shouldBe opaqueRecord
    }

    test("a portable binding carries opaque records through a list") {
        val binding = portableBinding<List<PortableValue>>(TEST_PORTABLE_RECORD_LIST_USE)
        val authored =
            DataValue.named(
                TEST_PORTABLE_RECORD_LIST_USE,
                DataValue.listValue(
                    listOf(
                        skirout.editor.v1.type_catalog.ListItem(
                            id =
                                skirout.editor.v1.type_catalog
                                    .ItemId(value = "opaque"),
                            value = opaqueRecord,
                        ),
                    ),
                ),
            )
        val decoded =
            binding.decode(
                portableBindings.checked
                    .resolve(TEST_PORTABLE_RECORD_LIST_USE.use)
                    .ready()
                    .complete(authored)
                    .complete(),
            )
        val encoded = binding.encode(decoded) as DataValue.NamedWrapper

        decoded shouldBe listOf(PortableValue(actualType = TEST_PORTABLE_RECORD_USE.use, payload = opaquePayload))
        (encoded.value.payload as DataValue.ListValueWrapper).value.items.map { it.value } shouldBe listOf(opaqueRecord)
    }

    test("a portable binding refuses to encode a value whose actual type is not its own") {
        shouldThrow<NativeBindingException> {
            portableBinding<PortableValue>(
                TEST_PORTABLE_RECORD_USE,
            ).encode(PortableValue(actualType = TEST_CODE_USE.use, payload = opaquePayload))
        }.code shouldBe "wrong_portable_actual_type"
    }

    test("an opaque record without its required field is incomplete") {
        val invalid =
            portableBindings.checked
                .resolve(TEST_PORTABLE_RECORD_USE.use)
                .ready()
                .complete(DataValue.named(TEST_PORTABLE_RECORD_USE, DataValue.record(emptyMap())))

        (invalid as CompletenessResult.Invalid).problems.map { it.code } shouldBe listOf("missing_field")
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

    test("a float32 value beyond the Float range is refused") {
        val assembly =
            CatalogContributions(
                declarations = emptyList(),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "float32 range")))
        val checked = assembly.checked.resolve(floatScalar(FloatWidth.THIRTY_TWO).use).ready()

        (checked.complete(DataValue.FloatWrapper(1e300)) as CompletenessResult.Invalid).problems.map { it.code } shouldBe
            listOf("float32_precision_loss")
    }

    test("catalog assembly marks a child unavailable when two parents declare the same field with different types") {
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
        val assembly =
            CatalogContributions(
                declarations = listOf(left, right, child).map { OwnedTypeDeclaration(origin, it) },
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
    }

    test("catalog assembly keeps one entry for a type two owners declare and marks it unavailable") {
        val duplicate = recordDefinition("Duplicate", "value", ScalarKind.TEXT.template)
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(providerOrigin("catalog_conflicts"), duplicate),
                        OwnedTypeDeclaration(providerOrigin("duplicate_owner"), duplicate),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "catalog conflicts")))

        assembly.editorCatalog.types
            .single { it.definition.id == duplicate.id }
            .status
            .let {
                (it as DeclarationStatus.UnavailableWrapper).value.map { diagnostic ->
                    Triple(diagnostic.affected, diagnostic.code, diagnostic.origins)
                }
            } shouldBe
            listOf(
                Triple(
                    duplicate.id,
                    "duplicate_definition",
                    listOf(
                        skirout.editor.v1.diagnostic
                            .DeclarationOrigin(owner = providerOrigin("catalog_conflicts").owner),
                        skirout.editor.v1.diagnostic
                            .DeclarationOrigin(owner = providerOrigin("duplicate_owner").owner),
                    ),
                ),
            )
    }

    test("catalog assembly quarantines a declaration in the opaque parameter namespace") {
        val reserved =
            TypeDefinition.partial(
                id = TypeDefinitionId.qualified("typewriter.parameter", "Reserved"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(providerOrigin("reserved"), reserved)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "reserved")))

        assembly.editorCatalog.types
            .single { it.definition.id == reserved.id }
            .status
            .let { (it as DeclarationStatus.UnavailableWrapper).value.map { diagnostic -> diagnostic.code } } shouldBe
            listOf("reserved_intrinsic_type_identity")
    }

    test("catalog assembly marks a type unavailable when a presentation targets it with the wrong number of type arguments") {
        val subject = recordDefinition("PresentedSubject", "value", ScalarKind.TEXT.template)
        val provider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "orphan")
        val target = PresentationTarget.NamedWrapper(subject.id.namedTemplate(listOf(INT)))
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(providerOrigin("orphan"), subject)),
                presentations =
                    listOf(
                        ownedPresentation(
                            providerOrigin("orphan"),
                            provider,
                            target,
                            fieldPresentationMaterial(
                                provider,
                                target,
                                skirout.editor.v1.type_catalog
                                    .PresentationId(namespace = "test", name = "text"),
                            ),
                        ),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "orphan")))

        assembly.editorCatalog.types
            .single { it.definition.id == subject.id }
            .status
            .let { (it as DeclarationStatus.UnavailableWrapper).value.map { diagnostic -> diagnostic.code } } shouldBe
            listOf("invalid_presentation_target")
        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
    }

    test("a provider lease can only be retained for an origin that owns a provider") {
        val assembly =
            CatalogContributions(
                declarations = emptyList(),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "no providers")))

        shouldThrow<IllegalArgumentException> { assembly.providers.retain(providerOrigin("nobody")) }.message shouldBe
            "Unknown provider origin ${providerOrigin("nobody")}."
    }

    test("competing inherited field presentations keep every child type ready and raise no conflict") {
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
        assembly.editorCatalog.presentationMaterials.map { it.provider } shouldBe listOf(textProvider, choiceProvider, resolvedProvider)
        assembly.editorCatalog.diagnostics shouldBe emptyList()
    }

    test("catalog assembly drops a material with an inferred control outside its owning record and keeps its type") {
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
        assembly.editorCatalog.types
            .single { it.definition.id == definition.id }
            .status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
        assembly.editorCatalog.diagnostics.map { it.affected to it.code } shouldBe
            listOf(definition.id to "presentation_material_build_failed")
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
                part to null,
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
                ) to "Presentation part details has an incompatible declaring owner.",
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
                ) to "Presentation part details must have bounded editors within its owner record and no owner remainder.",
            )
        variants.forEach { (layout, rejection) ->
            val assembly =
                CatalogContributions(
                    declarations = listOf(OwnedTypeDeclaration(origin, definition), OwnedTypeDeclaration(origin, foreign)),
                    presentations = listOf(ownedPresentation(origin, provider, target, base.copy(layout = layout))),
                ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "atomic parts")))
            assembly.editorCatalog.types
                .single { it.definition.id == definition.id }
                .status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
            if (rejection == null) {
                assembly.editorCatalog.presentationMaterials
                    .single()
                    .inheritableNodes shouldBe listOf("part")
            } else {
                assembly.editorCatalog.presentationMaterials shouldBe emptyList()
                assembly.callbackFailures.map { it.cause.message } shouldBe listOf(rejection)
            }
        }
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

/** The inputs of the single check [declare] collects for [owner]. */
private fun checkInputs(
    owner: TypeDefinitionId,
    declare: DefaultConfigurationCollectionScope.() -> Unit,
): List<CheckInput> =
    DefaultConfigurationCollectionScope(owner)
        .apply(declare)
        .collected()
        .checks
        .single()
        .inputs

private fun fieldPattern(vararg names: String): RelativeFieldPattern =
    RelativeFieldPattern(
        segments =
            names.map {
                FieldPatternSegment.field(it)
            },
    )

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
