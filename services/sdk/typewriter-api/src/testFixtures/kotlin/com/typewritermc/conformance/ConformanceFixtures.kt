@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.conformance

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.DraftView
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.MapDraft
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.draftViewProjection
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.item
import com.typewritermc.authoring.listDraftProjection
import com.typewritermc.authoring.mapDraftProjection
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.materialize
import com.typewritermc.authoring.nativeReadProjection
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.authoring.validateStructure
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
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagDraftType
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.of
import com.typewritermc.testkit.checkInputs
import com.typewritermc.testkit.complete
import com.typewritermc.testkit.configurationProvider
import com.typewritermc.testkit.fieldDeclaration
import com.typewritermc.testkit.fieldPattern
import com.typewritermc.testkit.integerField
import com.typewritermc.testkit.nullableTextField
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.record
import com.typewritermc.testkit.recordType
import com.typewritermc.testkit.textField
import com.typewritermc.testkit.unsignedIntegerField
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.GeneratedNativeField
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.GeneratedScalarNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingException
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.actualType
import com.typewritermc.types.bigInteger
import com.typewritermc.types.canonicalValueKey
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.of
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.toSkir
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.InputAnswer
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RequiredInput
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.diagnostic.InitializationDiagnostic
import skirout.editor.v1.diagnostic.StructuralResult
import skirout.editor.v1.expression.EvaluationBudget
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.typed_value.PortableValue
import java.math.BigInteger
import kotlin.coroutines.Continuation
import kotlin.coroutines.EmptyCoroutineContext
import kotlin.coroutines.startCoroutine

internal class FixtureKeyDraft(
    private val binding: DraftBinding,
) : DraftView {
    override val catalog = binding.catalog
    override val readContext = binding.readContext
    override val location = binding.location
    override val actualType = Availability.Available((binding.actual as TypeSelection.CompleteWrapper).use)
}

internal class FixtureDraftReads(
    override val catalog: CatalogGeneration,
    val values: Map<ValueLocation, DataValue>,
    private val collectionMembers: Map<ValueLocation, List<ItemId>> = emptyMap(),
) : AuthoredReads {
    override val readContext = ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return Availability.Unavailable(listOf(path.location))
        val native: Any =
            when (val payload = value.unwrapNamed()) {
                is DataValue.IntegerWrapper -> payload.bigInteger.intValueExact()
                is DataValue.StringValueWrapper -> payload.value
                is DataValue.BooleanWrapper -> payload.value
                else -> return failed("unsupported_fixture_read", path.location)
            }
        @Suppress("UNCHECKED_CAST")
        return Availability.Available(native as T)
    }

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> {
        @Suppress("UNCHECKED_CAST")
        return read(path as BoundPath<T>)
    }

    override fun presence(path: BoundPath<*>): Availability<Boolean> =
        when (values[path.location]) {
            null, DataValue.UNFILLED -> Availability.Unavailable(listOf(path.location))
            DataValue.NULL -> Availability.Available(false)
            else -> Availability.Available(true)
        }

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return Availability.Unavailable(listOf(path.location))
        val named = value as? DataValue.NamedWrapper ?: return failed("expected_named_binding", path.location)
        return Availability.Available(
            DraftBinding(
                catalog,
                readContext,
                path.location,
                DraftExpectation.PartialRoot(
                    PartialSchema(knownFields = emptyList(), dependentFields = emptyList(), pendingArguments = emptyList()),
                ),
                TypeSelection.CompleteWrapper(named.actualType),
            ),
        )
    }

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> {
        val value = values[path.location] ?: return Availability.Unavailable(listOf(path.location))
        if (value == DataValue.UNFILLED || value == DataValue.NULL) return Availability.Unavailable(listOf(path.location))
        return Availability.Available(value.canonicalValueKey())
    }

    override fun members(path: BoundCollectionPath): List<ItemId> = collectionMembers[path.location].orEmpty()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Selections are outside this fixture.")
}

internal fun <T> failed(
    code: String,
    location: ValueLocation,
): Availability<T> =
    Availability.Failed(
        EvaluationDiagnostic(
            failure =
                skirout.editor.v1.expression
                    .FailureId(value = code),
            message = code,
            locations = listOf(location),
        ),
    )

internal class CapturingPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)
    var sampled: Map<FieldOwner, CompleteValue> = emptyMap()

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        sampled = supplied
        return CaptureResult.Captured(mapOf(DEFAULTED_OWNER to DataValue.integer(java.math.BigInteger.valueOf(3))))
    }
}

internal class FailingPlan(
    private val diagnostic: InitializationDiagnostic,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(DEFAULTED_OWNER)

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult = CaptureResult.Unavailable(listOf(diagnostic))
}

internal class FieldFailingPlan(
    field: FieldOwner,
    private val diagnostic: InitializationDiagnostic,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(field)

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult = CaptureResult.Unavailable(listOf(diagnostic))
}

internal class AbstractInputPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(ABSTRACT_DEFAULT_OWNER)
    var sampled: Map<FieldOwner, CompleteValue> = emptyMap()

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        sampled = supplied
        return CaptureResult.Captured(
            mapOf(ABSTRACT_DEFAULT_OWNER to DataValue.integer(java.math.BigInteger.valueOf(11))),
        )
    }
}

internal class ChildPlan : NativeConstructionPlan {
    override val defaultedFields = setOf(CHILD_DEFAULT_OWNER)

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult =
        CaptureResult.Captured(
            mapOf(CHILD_DEFAULT_OWNER to DataValue.integer(java.math.BigInteger.valueOf(7))),
        )
}

internal class PlanFactory(
    override val constructionPlan: NativeConstructionPlan,
    override val definition: TypeDefinitionId = INITIALIZED_ID,
) : NativeBindingFactory {
    override val provider = NativeBindingId(value = "test.initialization")

    override fun bind(
        actual: com.typewritermc.types.catalog.CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> = error("Initialization sampling does not bind a complete native record.")
}

internal fun <T> runSuspend(block: suspend () -> T): T {
    var result: Result<T>? = null
    block.startCoroutine(
        object : Continuation<T> {
            override val context = EmptyCoroutineContext

            override fun resumeWith(value: Result<T>) {
                result = value
            }
        },
    )
    return result!!.getOrThrow()
}

internal val INITIALIZED_ID = TypeDefinitionId.qualified("test", "Initialized")

internal val DEFAULTED_OWNER = FieldOwner(definition = INITIALIZED_ID, name = "defaulted")

internal val ABSTRACT_DEFAULT_OWNER = FieldOwner(definition = TypeDefinitionId.qualified("test", "AbstractOwner"), name = "defaulted")

internal val CHILD_DEFAULT_OWNER = FieldOwner(definition = TypeDefinitionId.qualified("test", "Child"), name = "defaulted")

internal fun recordRequest(
    generation: CatalogGeneration,
    selection: TypeSelection,
    supplied: Map<String, DataValue>,
) = ValuePreparationRequest(
    catalog = generation,
    target = PreparationTarget.RecordWrapper(selection),
    suppliedValue = DataValue.record(supplied),
)

internal data class ResumeFixture(
    val runtime: DefaultInitializationRuntime,
    val request: ValuePreparationRequest,
    val marker: CountingPlan,
    val settings: CountingPlan,
)

internal fun resumeFixture(
    defaultedSettings: Boolean = false,
    failMarker: Boolean = false,
): ResumeFixture {
    val root = id("Root")
    val settings = id("Settings")
    val marker = id("Marker")
    val markerPlan = CountingPlan(FieldOwner(definition = marker, name = "id"), fail = failMarker)
    val settingsPlan = CountingPlan(FieldOwner(definition = settings, name = "label"))
    val settingsFields =
        buildList {
            add(
                FieldDeclaration.partial(owner = FieldOwner(definition = settings, name = "target"), type = LINK_USE.template()),
            )
            if (defaultedSettings) {
                add(
                    FieldDeclaration.partial(
                        owner = FieldOwner(definition = settings, name = "label"),
                        type = ScalarKind.TEXT.template,
                        hasConstructorDefault = true,
                    ),
                )
            }
        }
    val catalog =
        DefaultCheckedCatalog(
            GENERATION,
            listOf(
                resourceDefinition(),
                linkDefinition(),
                TypeDefinition.partial(
                    id = root,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = root, name = "settings"),
                                        type = settings.template(emptyList()),
                                    ),
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = root, name = "marker"),
                                        type = marker.template(emptyList()),
                                    ),
                                ),
                            abstract_ = false,
                        ),
                ),
                TypeDefinition.partial(
                    id = settings,
                    representation = RepresentationTemplate.createRecord(fields = settingsFields, abstract_ = false),
                ),
                TypeDefinition.partial(
                    id = marker,
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = marker, name = "id"),
                                        type = ScalarKind.TEXT.template,
                                        hasConstructorDefault = true,
                                    ),
                                ),
                            abstract_ = false,
                        ),
                ),
            ),
        )
    val factories =
        buildList {
            add(ResumePlanFactory(marker, markerPlan))
            if (defaultedSettings) add(ResumePlanFactory(settings, settingsPlan))
        }
    return ResumeFixture(
        DefaultInitializationRuntime(catalog, FactoryNativeBindingRegistry(catalog, factories)),
        request(root),
        markerPlan,
        settingsPlan,
    )
}

internal class CountingPlan(
    val field: FieldOwner,
    val fail: Boolean = false,
    val value: DataValue? = null,
) : NativeConstructionPlan {
    override val defaultedFields = setOf(field)
    var calls = 0

    override fun sample(
        arguments: AppliedNativeArguments,
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        calls++
        return if (fail) {
            CaptureResult.Unavailable(
                listOf(
                    InitializationDiagnostic(field = field, code = "test_capture_failed", message = "Capture failed.", relativePath = null),
                ),
            )
        } else {
            CaptureResult.Captured(mapOf(field to (value ?: DataValue.StringValueWrapper("capture:$calls"))))
        }
    }
}

internal class ResumePlanFactory(
    override val definition: TypeDefinitionId,
    override val constructionPlan: NativeConstructionPlan,
) : NativeBindingFactory {
    override val provider = NativeBindingId(value = "test.resume")

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> = error("Preparation does not decode complete records.")
}

internal val GENERATION = CatalogGeneration(value = "resume")

internal val RESOURCE_ID = id("Resource")

internal val LINK_ID = id("Reference")

internal val LINK_USE = LINK_ID.namedUse(emptyList())

internal val ENDPOINT = EndpointId(value = "required-reference")

internal fun id(name: String) = TypeDefinitionId.qualified("test.resume", name)

internal fun NamedTypeUse.template() = definition.template(emptyList())

internal fun resourceDefinition() =
    TypeDefinition.partial(id = RESOURCE_ID, representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false))

internal fun linkDefinition() =
    TypeDefinition.partial(
        id = LINK_ID,
        representation = RepresentationTemplate.createLink(endpoint = ENDPOINT, target = RESOURCE_ID.template(emptyList())),
    )

internal fun request(id: TypeDefinitionId) =
    ValuePreparationRequest(
        catalog = GENERATION,
        target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(id.namedUse(emptyList()))),
        suppliedValue = DataValue.record(emptyMap()),
    )

internal fun path(vararg fields: String) = ValuePath(segments = fields.map { PathSegment.createField(name = it) })

internal fun reference() =
    DataValue.named(
        LINK_USE,
        DataValue.createLink(endpoint = ENDPOINT, target = LinkTarget(resource = ResourceId("reserved-target").toSkir(), opposite = null)),
    )

internal fun fieldPresentationMaterial(
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

internal fun ownedPresentation(
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

internal fun providerOrigin(name: String): ProviderOrigin {
    val key = contributionKey(ContributionSourceId("test"), "main", ProducerId("sdk"), ContributionName(name))
    return ProviderOrigin(DeclarationOwner(source = key, localIdentity = name), ArtifactId("test:sdk"), "main")
}

internal fun definitionId(name: String): TypeDefinitionId = TypeDefinitionId.qualified("test", name)

internal fun DataValue.available(): Availability<DataValue> = Availability.Available(this)

internal object EmptyReads : AuthoredReads {
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
internal value class TestCode(
    val value: String,
)

internal object TestCodeNativeBindingFactory : NativeBindingFactory {
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

internal sealed interface TestMessage

internal data class TestTextMessage(
    val text: String,
) : TestMessage

internal data class TestTranslationMessage(
    val key: String,
) : TestMessage

internal data class TestMessageAction(
    val message: TestMessage,
    val messages: List<TestMessage>,
    val optional: TestMessage?,
)

internal data class TestTree<T>(
    val value: T,
    val children: List<TestTree<T>>,
)

internal class TestIdentityKey(
    val value: String,
)

internal object TestTextMessageNativeBindingFactory : NativeBindingFactory {
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

internal object TestTranslationMessageNativeBindingFactory : NativeBindingFactory {
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

internal object TestMessageActionNativeBindingFactory : NativeBindingFactory {
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

internal object TestTreeNativeBindingFactory : NativeBindingFactory {
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

internal object TestIdentityKeyNativeBindingFactory : NativeBindingFactory {
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

internal val TEXT_USE = ScalarKind.TEXT.use

internal val TEST_CODE_ID = definitionId("TestCode")

internal val TEST_TEXT_MESSAGE_ID = definitionId("TestTextMessage")

internal val TEST_TRANSLATION_MESSAGE_ID = definitionId("TestTranslationMessage")

internal val TEST_MESSAGE_ACTION_ID = definitionId("TestMessageAction")

internal val TEST_TREE_ID = definitionId("TestTree")

internal val TEST_IDENTITY_KEY_ID = definitionId("TestIdentityKey")

internal val TEST_MESSAGE_USE = definitionId("TestMessage").use()

internal val TEST_MESSAGE_LIST_USE = StandardTypes.list.use(listOf(TEST_MESSAGE_USE))

internal val TEST_OPTIONAL_MESSAGE_USE = TEST_MESSAGE_USE.nullable()

/** A pending generic configuration whose type argument is still unfilled, and the initialization that prepares it. */
internal object PendingInitialization {
    val generation = CatalogGeneration(value = "pending initialization catalog")
    val definitionId = TypeDefinitionId.qualified("test", "PendingConfiguration")
    val parameter = ParameterKey(owner = definitionId, index = 0)
    val defaulted = FieldOwner(definition = definitionId, name = "defaulted")
    val catalog =
        DefaultCheckedCatalog(
            generation,
            listOf(
                TypeDefinition.partial(
                    id = definitionId,
                    parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                    representation =
                        RepresentationTemplate.createRecord(
                            fields =
                                listOf(
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = definitionId, name = "independent"),
                                        type = ScalarKind.TEXT.template,
                                    ),
                                    FieldDeclaration.partial(
                                        owner = defaulted,
                                        type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                        hasConstructorDefault = true,
                                    ),
                                    FieldDeclaration.partial(
                                        owner = FieldOwner(definition = definitionId, name = "dependent"),
                                        type = parameter.template,
                                    ),
                                ),
                            abstract_ = false,
                        ),
                ),
            ),
        )
    val construction =
        object : NativeConstructionPlan {
            override val defaultedFields = setOf(defaulted)

            override fun sample(
                arguments: AppliedNativeArguments,
                supplied: Map<FieldOwner, CompleteValue>,
            ): CaptureResult = error("Pending creation must not sample a native constructor.")
        }
    val selection = TypeSelection.createPending(definition = definitionId, arguments = listOf(ArgumentSelection.UNFILLED))

    /** Prepares a pending record with the [supplied] field values. */
    fun prepare(supplied: Map<String, DataValue>) =
        DefaultInitializationRuntime(
            catalog,
            FactoryNativeBindingRegistry(catalog, listOf(PlanFactory(construction, definitionId))),
        ).prepareNow(recordRequest(generation, selection, supplied))
}

/** What [expression] evaluates to when its one input, read at [at], gives [result]; every read is recorded in [reads]. */
internal fun evaluateReading(
    expression: ExpressionNode,
    at: ValueLocation,
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
            ExpressionBindings(mapOf(ExpressionBindingId(value = "value") to at)),
            EvaluationBudget(maxSteps = 100, maxCollectionItems = 100),
        )
    }
}

/** What the one portable rule [helper] declares gives when its field holds [value]. */
internal fun ruleOutcome(
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
