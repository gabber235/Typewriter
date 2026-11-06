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
import com.typewritermc.expression.FixtureReads
import com.typewritermc.expression.PortableExpressionLimits
import com.typewritermc.expression.eq
import com.typewritermc.expression.evaluate
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
import com.typewritermc.testkit.admitted
import com.typewritermc.testkit.binding
import com.typewritermc.testkit.checkInputs
import com.typewritermc.testkit.complete
import com.typewritermc.testkit.configurationProvider
import com.typewritermc.testkit.fieldDeclaration
import com.typewritermc.testkit.fieldPattern
import com.typewritermc.testkit.integerField
import com.typewritermc.testkit.nullableTextField
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.recordType
import com.typewritermc.testkit.rulePredicate
import com.typewritermc.testkit.textField
import com.typewritermc.testkit.unsignedIntegerField
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
import com.typewritermc.types.member
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
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.typed_value.PortableValue

val SdkRuntimeConformanceTest by testSuite {
    val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template

    val intUse = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use

    val testCodeUse = TEST_CODE_ID.namedUse()

    val testCodeDefinition =
        TypeDefinition.partial(id = TEST_CODE_ID, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))

    val testMessageId = definitionId("TestMessage")

    val testPortableRecordId = definitionId("TestPortableRecord")

    val testTreeParameter = ParameterKey(owner = TEST_TREE_ID, index = 0)

    val testMessageActionUse = TEST_MESSAGE_ACTION_ID.use()

    val testTextTreeUse = TEST_TREE_ID.use(listOf(TEXT_USE))

    val testIdentityKeyUse = TEST_IDENTITY_KEY_ID.namedUse()

    val testIdentityKeySetUse = StandardTypes.set.namedUse(listOf(testIdentityKeyUse.use))

    val testIdentityKeyMapUse = StandardTypes.map.namedUse(listOf(testIdentityKeyUse.use, TEXT_USE))

    val testPortableRecordUse = testPortableRecordId.namedUse()

    val testPortableRecordListUse = StandardTypes.list.namedUse(listOf(testPortableRecordUse.use))

    val testPortableRecordDefinition =
        TypeDefinition.partial(
            id = testPortableRecordId,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = testPortableRecordId, name = "label"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    form = RecordForm.CONCRETE,
                ),
        )

    val testIdentityKeyDefinition =
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
                    form = RecordForm.CONCRETE,
                ),
        )

    val testMessageDefinition =
        TypeDefinition.partial(
            id = testMessageId,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
        )

    val testTextMessageDefinition =
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
                    form = RecordForm.CONCRETE,
                ),
            parents = listOf(testMessageId.namedTemplate()),
        )

    val testTranslationMessageDefinition =
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
                    form = RecordForm.CONCRETE,
                ),
            parents = listOf(testMessageId.namedTemplate()),
        )

    val testMessageActionDefinition =
        TypeDefinition.partial(
            id = TEST_MESSAGE_ACTION_ID,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_MESSAGE_ACTION_ID, name = "message"),
                                type = testMessageId.template(),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_MESSAGE_ACTION_ID, name = "messages"),
                                type = StandardTypes.list.template(listOf(testMessageId.template())),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_MESSAGE_ACTION_ID, name = "optional"),
                                type = testMessageId.template().nullable(),
                            ),
                        ),
                    form = RecordForm.CONCRETE,
                ),
        )

    val testTreeDefinition =
        TypeDefinition.partial(
            id = TEST_TREE_ID,
            parameters = listOf(TypeParameter.partial(key = testTreeParameter, name = "T")),
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_TREE_ID, name = "value"),
                                type = testTreeParameter.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = TEST_TREE_ID, name = "children"),
                                type = StandardTypes.list.template(listOf(TEST_TREE_ID.template(listOf(testTreeParameter.template)))),
                            ),
                        ),
                    form = RecordForm.CONCRETE,
                ),
        )

    test("a generated resource selection matches exactly the resources whose configured field equals the value") {
        val predicate =
            requireNotNull(
                com.typewritermc.library.BookDraftType
                    .where { title eq literal("Requested") }
                    .predicate,
            )

        fun matches(title: String): Availability<DataValue> =
            evaluate(predicate, mapOf("configured_value" to ValueLocation.of(ResourceId("book:requested"), ValuePath.root))) {
                DataValue.StringValueWrapper(title).available()
            }

        matches("Requested") shouldBe Availability.Available(DataValue.BooleanWrapper(true))
        matches("Other") shouldBe Availability.Available(DataValue.BooleanWrapper(false))
    }

    val readLocation = ValueLocation.of(ResourceId("expression:test"))
    val read = testInput(ExpressionBindingId(value = "value"), ValuePath.root)
    val readBinding = mapOf("value" to readLocation)

    test("portable and short circuits on a false left operand without reading the right") {
        val reads = mutableListOf<ValueLocation>()

        evaluate(ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(false)), right = read), readBinding) {
            reads += it
            DataValue.BooleanWrapper(true).available()
        } shouldBe Availability.Available(DataValue.BooleanWrapper(false))
        reads shouldBe emptyList()
    }

    test("portable or else falls back when its value is unavailable") {
        evaluate(ExpressionNode.createOrElse(value = read, fallback = testLiteral(DataValue.StringValueWrapper("fallback"))), readBinding) {
            Availability.Unavailable(listOf(readLocation))
        } shouldBe Availability.Available(DataValue.StringValueWrapper("fallback"))
    }

    test("portable or else keeps a failed read instead of falling back") {
        val failed =
            Availability.Failed(
                EvaluationDiagnostic(failure = FailureId(value = "read_failed"), message = "broken", locations = listOf(readLocation)),
            )

        evaluate(ExpressionNode.createOrElse(value = read, fallback = testLiteral(DataValue.StringValueWrapper("hidden"))), readBinding) {
            failed
        } shouldBe failed
    }

    test("portable operations read a named scalar through its representation") {
        evaluate(
            ExpressionNode.createCall(
                operation = PortableOperationCatalog.TEXT_LENGTH.id,
                typeArguments = emptyList(),
                arguments = listOf(read),
            ),
            readBinding,
        ) { DataValue.named(testCodeUse, DataValue.StringValueWrapper("chapter")).available() } shouldBe
            Availability.Available(DataValue.integer(7.toBigInteger()))
    }

    test("portable evaluation bounds expression depth without evaluating a short circuited branch") {
        var nested: ExpressionNode = testLiteral(DataValue.BooleanWrapper(true))
        repeat(PortableExpressionLimits.MAX_DEPTH + 1) {
            nested = ExpressionNode.createAnd(left = testLiteral(DataValue.BooleanWrapper(true)), right = nested)
        }
        val evaluator = DefaultExpressionEvaluator(ExpressionValueReader { error("No reads expected") }, testPortableTypes())
        with(FixtureReads) {
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
            val origin = origin("typed_checks")
            val counter = recordType(definitionId("Counter"), fieldDeclaration(definitionId("Counter"), "count", int))
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
                declarations = listOf(OwnedTypeDeclaration(origin, counter), OwnedTypeDeclaration(origin, testCodeDefinition)),
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
                        .resolve(intUse)
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
                            testCodeUse.use,
                        ).ready()
                        .complete(DataValue.named(testCodeUse, DataValue.StringValueWrapper(code)))
                        .complete(),
                ),
            )

        passes("chapter") shouldBe true
        passes(" ") shouldBe false
    }

    test("an integer minimum accepts its bound and refuses the value below it") {
        val minimumThree: DefaultConfigurationCollectionScope.() -> Unit = {
            integerField(this, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count")))).minimum(3)
        }

        evaluate(rulePredicate(minimumThree), "configured_value" to DataValue.integer(3.toBigInteger())) shouldBe
            Availability.Available(DataValue.BooleanWrapper(true))
        evaluate(rulePredicate(minimumThree), "configured_value" to DataValue.integer(2.toBigInteger())) shouldBe
            Availability.Available(DataValue.BooleanWrapper(false))
    }

    test("an unsigned minimum compares values beyond the signed range exactly") {
        val bound = ULong.MAX_VALUE - 1uL
        val nearMaximum: DefaultConfigurationCollectionScope.() -> Unit = {
            unsignedIntegerField(this, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("count")))).minimum(bound)
        }

        evaluate(rulePredicate(nearMaximum), "configured_value" to DataValue.integer(ULong.MAX_VALUE.toString().toBigInteger())) shouldBe
            Availability.Available(DataValue.BooleanWrapper(true))
        evaluate(rulePredicate(nearMaximum), "configured_value" to DataValue.integer((bound - 1uL).toString().toBigInteger())) shouldBe
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

        listOf(
            "one",
            "one\ntwo",
        ).map { evaluate(rulePredicate(atLeastTwoLines), "configured_value" to DataValue.StringValueWrapper(it)) } shouldBe
            listOf(Availability.Available(DataValue.BooleanWrapper(false)), Availability.Available(DataValue.BooleanWrapper(true)))
        listOf("one\ntwo", "one\ntwo\nthree").map {
            evaluate(
                rulePredicate(atMostTwoLines),
                "configured_value" to DataValue.StringValueWrapper(it),
            )
        } shouldBe
            listOf(Availability.Available(DataValue.BooleanWrapper(true)), Availability.Available(DataValue.BooleanWrapper(false)))
    }

    test("a rule declared when a nullable field is present accepts a missing value and judges a present one") {
        val nonBlankWhenPresent: DefaultConfigurationCollectionScope.() -> Unit = {
            nullableTextField(this, RelativeFieldPattern(segments = listOf(FieldPatternSegment.field("text")))).whenPresent { nonBlank() }
        }

        evaluate(rulePredicate(nonBlankWhenPresent), "configured_value" to DataValue.NULL) shouldBe
            Availability.Available(DataValue.BooleanWrapper(true))
        evaluate(rulePredicate(nonBlankWhenPresent), "configured_value" to DataValue.StringValueWrapper("")) shouldBe
            Availability.Available(DataValue.BooleanWrapper(false))
        evaluate(rulePredicate(nonBlankWhenPresent), "configured_value" to DataValue.StringValueWrapper("text")) shouldBe
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
        } shouldBe listOf(CheckInput(owner, fieldPattern("style", "repetitions"), int))
    }

    test("abstract native fields collections and nullable values dispatch by concrete type tag") {
        val origin = origin("polymorphic_native")
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin, testMessageDefinition),
                        OwnedTypeDeclaration(origin, testTextMessageDefinition),
                        OwnedTypeDeclaration(origin, testTranslationMessageDefinition),
                        OwnedTypeDeclaration(origin, testMessageActionDefinition),
                        OwnedTypeDeclaration(origin, testTreeDefinition),
                    ),
                nativeBindings =
                    listOf(
                        OwnedNativeBinding(origin, TestTextMessageNativeBindingFactory),
                        OwnedNativeBinding(origin, TestTranslationMessageNativeBindingFactory),
                        OwnedNativeBinding(origin, TestMessageActionNativeBindingFactory),
                        OwnedNativeBinding(origin, TestTreeNativeBindingFactory),
                    ),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "polymorphic native")))
        val checked = assembly.checked.resolve(testMessageActionUse).ready()
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

        val treeChecked = assembly.checked.resolve(testTextTreeUse).ready()
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
                    testCodeDefinition,
                    testMessageDefinition,
                    testTextMessageDefinition,
                    testTranslationMessageDefinition,
                    testMessageActionDefinition,
                    testTreeDefinition,
                ).map { OwnedTypeDeclaration(origin("binding_misuse"), it) },
            nativeBindings =
                listOf(
                    TestCodeNativeBindingFactory,
                    TestTextMessageNativeBindingFactory,
                    TestTranslationMessageNativeBindingFactory,
                    TestMessageActionNativeBindingFactory,
                    TestTreeNativeBindingFactory,
                ).map { OwnedNativeBinding(origin("binding_misuse"), it) },
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "binding misuse")))

    mapOf(
        "a polymorphic binding given a value without a concrete type" to
            Triple(TEST_MESSAGE_USE, polymorphic.admitted(TEXT_USE, DataValue.StringValueWrapper("hello")), "missing_polymorphic_type_tag"),
        "a polymorphic binding given a concrete type it cannot read" to
            Triple(
                TEST_MESSAGE_USE,
                polymorphic.admitted(testCodeUse.use, DataValue.named(testCodeUse, DataValue.StringValueWrapper("code"))),
                "unreadable_polymorphic_type",
            ),
        "a generated record binding given a record without one of its native fields" to
            Triple(
                TEST_TEXT_MESSAGE_ID.use(),
                polymorphic.admitted(
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
                polymorphic.admitted(floatScalar(FloatWidth.SIXTY_FOUR).use, DataValue.FloatWrapper(1e300)),
                "float32_out_of_range",
            ),
        "a float32 binding given a float64 it cannot represent exactly" to
            Triple(
                floatScalar(FloatWidth.THIRTY_TWO).use,
                polymorphic.admitted(floatScalar(FloatWidth.SIXTY_FOUR).use, DataValue.FloatWrapper(0.1)),
                "float32_precision_loss",
            ),
    ).forEach { (case, misuse) ->
        test("$case refuses to decode it") {
            shouldThrow<NativeBindingException> { polymorphic.binding<Any>(misuse.first).decode(misuse.second) }.code shouldBe misuse.third
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
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
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
        val origin = origin("catalog_generation")
        val contributions =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin, testMessageDefinition),
                        OwnedTypeDeclaration(origin, testTextMessageDefinition),
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
            declarations = listOf(OwnedTypeDeclaration(origin("portable_bindings"), testPortableRecordDefinition)),
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "portable bindings")))
    val opaquePayload = DataValue.record(mapOf("label" to DataValue.StringValueWrapper("opaque")))
    val opaqueRecord = DataValue.named(testPortableRecordUse, opaquePayload)

    test("a portable binding decodes an opaque record to its actual type and payload and encodes it back unchanged") {
        val binding = portableBindings.binding<PortableValue>(testPortableRecordUse.use)
        val decoded =
            binding.decode(
                portableBindings.checked
                    .resolve(testPortableRecordUse.use)
                    .ready()
                    .complete(opaqueRecord)
                    .complete(),
            )

        decoded shouldBe PortableValue(actualType = testPortableRecordUse.use, payload = opaquePayload)
        binding.encode(decoded) shouldBe opaqueRecord
    }

    test("a portable binding carries opaque records through a list") {
        val binding = portableBindings.binding<List<PortableValue>>(testPortableRecordListUse.use)
        val authored =
            DataValue.named(
                testPortableRecordListUse,
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
                    .resolve(testPortableRecordListUse.use)
                    .ready()
                    .complete(authored)
                    .complete(),
            )
        val encoded = binding.encode(decoded) as DataValue.NamedWrapper

        decoded shouldBe listOf(PortableValue(actualType = testPortableRecordUse.use, payload = opaquePayload))
        (encoded.value.payload as DataValue.ListValueWrapper).value.items.map { it.value } shouldBe listOf(opaqueRecord)
    }

    val portableDoorId = definitionId("PortableDoor")
    val portableDoorUse = portableDoorId.namedUse().use
    val portableDoorBindings =
        CatalogContributions(
            declarations =
                (
                    listOf(
                        TypeDefinition.partial(
                            id = portableDoorId,
                            representation =
                                RepresentationTemplate.createRecord(
                                    fields = emptyList(),
                                    form =
                                        RecordForm.createClosed(
                                            cases = listOf("Open", "Closed").map { portableDoorId.member(it).namedTemplate() },
                                        ),
                                ),
                        ),
                    ) +
                        listOf("Open", "Closed").map {
                            TypeDefinition.partial(
                                id = portableDoorId.member(it),
                                representation = RepresentationTemplate.createScalar(kind = ScalarKind.UNIT),
                                parents = listOf(portableDoorId.namedTemplate()),
                            )
                        }
                ).map { OwnedTypeDeclaration(origin("portable_door"), it) },
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "portable door")))
    val openDoor = DataValue.named(portableDoorId.member("Open").namedUse(), DataValue.UNIT)

    test("a portable binding of a closed union decodes the case a value holds and encodes it back unchanged") {
        val binding = portableDoorBindings.binding<PortableValue>(portableDoorUse)
        val decoded =
            binding.decode(
                portableDoorBindings.checked
                    .resolve(portableDoorUse)
                    .ready()
                    .complete(openDoor)
                    .complete(),
            )

        decoded shouldBe PortableValue(actualType = portableDoorId.member("Open").namedUse().use, payload = DataValue.UNIT)
        binding.encode(decoded) shouldBe openDoor
    }

    test("a portable binding refuses to encode a value whose actual type is not its own") {
        shouldThrow<NativeBindingException> {
            portableBindings
                .binding<PortableValue>(
                    testPortableRecordUse.use,
                ).encode(PortableValue(actualType = testCodeUse.use, payload = opaquePayload))
        }.code shouldBe "wrong_portable_actual_type"
    }

    test("an opaque record without its required field is incomplete") {
        val invalid =
            portableBindings.checked
                .resolve(testPortableRecordUse.use)
                .ready()
                .complete(DataValue.named(testPortableRecordUse, DataValue.record(emptyMap())))

        (invalid as CompletenessResult.Invalid).problems.map { it.code } shouldBe listOf("missing_field")
    }

    test("native set and map reject canonical duplicate non data record values") {
        val origin = origin("canonical_native_duplicates")
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, testIdentityKeyDefinition)),
                nativeBindings = listOf(OwnedNativeBinding(origin, TestIdentityKeyNativeBindingFactory)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "canonical native duplicates")))
        val first =
            DataValue.named(
                testIdentityKeyUse,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("same"))),
            )
        val second =
            DataValue.named(
                testIdentityKeyUse,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("same"))),
            )

        val setChecked = assembly.checked.resolve(testIdentityKeySetUse.use).ready()
        val setValue =
            DataValue.named(
                testIdentityKeySetUse,
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

        val mapChecked = assembly.checked.resolve(testIdentityKeyMapUse.use).ready()
        val mapValue =
            DataValue.named(
                testIdentityKeyMapUse,
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
        val origin = origin("catalog_conflicts")
        val left = recordType(definitionId("Left"), fieldDeclaration(definitionId("Left"), "value", ScalarKind.TEXT.template))
        val right = recordType(definitionId("Right"), fieldDeclaration(definitionId("Right"), "value", int))
        val childId = definitionId("Child")
        val child =
            TypeDefinition.partial(
                id = childId,
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
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
        val duplicate =
            recordType(definitionId("Duplicate"), fieldDeclaration(definitionId("Duplicate"), "value", ScalarKind.TEXT.template))
        val assembly =
            CatalogContributions(
                declarations =
                    listOf(
                        OwnedTypeDeclaration(origin("catalog_conflicts"), duplicate),
                        OwnedTypeDeclaration(origin("duplicate_owner"), duplicate),
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
                            .DeclarationOrigin(owner = origin("catalog_conflicts").owner),
                        skirout.editor.v1.diagnostic
                            .DeclarationOrigin(owner = origin("duplicate_owner").owner),
                    ),
                ),
            )
    }

    test("catalog assembly quarantines a declaration in the opaque parameter namespace") {
        val reserved =
            TypeDefinition.partial(
                id = TypeDefinitionId.qualified("typewriter.parameter", "Reserved"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            )
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin("reserved"), reserved)),
            ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "reserved")))

        assembly.editorCatalog.types
            .single { it.definition.id == reserved.id }
            .status
            .let { (it as DeclarationStatus.UnavailableWrapper).value.map { diagnostic -> diagnostic.code } } shouldBe
            listOf("reserved_intrinsic_type_identity")
    }

    test("catalog assembly marks a type unavailable when a presentation targets it with the wrong number of type arguments") {
        val subject =
            recordType(
                definitionId("PresentedSubject"),
                fieldDeclaration(definitionId("PresentedSubject"), "value", ScalarKind.TEXT.template),
            )
        val provider =
            skirout.editor.v1.type_catalog
                .PresentationId(namespace = "test", name = "orphan")
        val target = PresentationTarget.NamedWrapper(subject.id.namedTemplate(listOf(int)))
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin("orphan"), subject)),
                presentations =
                    listOf(
                        ownedPresentation(
                            origin("orphan"),
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

        shouldThrow<IllegalArgumentException> { assembly.providers.retain(origin("nobody")) }.message shouldBe
            "Unknown provider origin ${origin("nobody")}."
    }

    test("competing inherited field presentations keep every child type ready and raise no conflict") {
        val origin = origin("field_presentation_conflicts")
        val root =
            recordType(
                definitionId("PresentationRoot"),
                fieldDeclaration(definitionId("PresentationRoot"), "value", ScalarKind.TEXT.template),
            )
        val textNamed =
            TypeDefinition.partial(
                id = definitionId("TextNamed"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(root.id.namedTemplate()),
            )
        val choiceNamed =
            TypeDefinition.partial(
                id = definitionId("ChoiceNamed"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(root.id.namedTemplate()),
            )
        val conflicted =
            TypeDefinition.partial(
                id = definitionId("ConflictedPresentationChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(textNamed.id.namedTemplate(), choiceNamed.id.namedTemplate()),
            )
        val resolved =
            TypeDefinition.partial(
                id = definitionId("ResolvedPresentationChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(textNamed.id.namedTemplate(), choiceNamed.id.namedTemplate()),
            )
        val unrelated =
            TypeDefinition.partial(
                id = definitionId("UnrelatedPresentationChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
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
        val origin = origin("invalid_field_presentation")
        val definition =
            recordType(
                definitionId("InvalidPresentationField"),
                fieldDeclaration(definitionId("InvalidPresentationField"), "actual", ScalarKind.TEXT.template),
            )
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
        val origin = origin("atomic_parts")
        val definition =
            recordType(definitionId("PartOwner"), fieldDeclaration(definitionId("PartOwner"), "value", ScalarKind.TEXT.template))
        val foreign =
            recordType(
                definitionId("ForeignPartOwner"),
                fieldDeclaration(definitionId("ForeignPartOwner"), "value", ScalarKind.TEXT.template),
            )
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
        val parent = recordType(definitionId("BoundedParent"), fieldDeclaration(definitionId("BoundedParent"), "value", int))
        val child =
            TypeDefinition.partial(
                id = definitionId("BoundedChild"),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
                parents = listOf(parent.id.namedTemplate()),
            )
        val origin = origin("inherited_rules")
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
                        OwnedConfiguration(origin("child_rules"), child.id, maximum),
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
                        form = RecordForm.CONCRETE,
                    ),
            )
        val origin = origin("generic_rules")
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
