package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.complete
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCapabilityRuntime
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchUpdate
import com.typewritermc.capability.id
import com.typewritermc.discovery.CapabilityOwnerResolver
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderIndexEntry
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.PageElements
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.generatedProviders
import com.typewritermc.testkit.generatedTypeCatalog
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.ready
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.fieldMap
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.capability.NotificationSeverity
import skirout.editor.v1.capability.PanelInstruction
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.math.BigInteger
import java.util.Collections

val SyntheticDiscoveryTest by testSuite {
    val messageCatalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "conformance messages"),
            listOf(
                SyntheticMessageDefinition.definition,
                LiteralMessageDefinition.definition,
                RepeatedMessageDefinition.definition,
            ),
        )
    val messageBindings =
        FactoryNativeBindingRegistry(messageCatalog, listOf(LiteralMessageNativeBindingFactory, RepeatedMessageNativeBindingFactory))
    val capabilityRuntime = RealmCapabilityRuntime(messageCatalog, messageBindings)
    val capabilities =
        CapabilityOwnerResolver { SyntheticRealmCapabilities() }.let { resolver ->
            RealmCapabilityRegistry(
                listOf(
                    SyntheticRealmCapabilitiesPublishMessageGeneratedCapabilityProvider().bind(resolver),
                    SyntheticRealmCapabilitiesRepeatMessageGeneratedCapabilityProvider().bind(resolver),
                    SyntheticRealmCapabilitiesSearchMessagesGeneratedCapabilityProvider().bind(resolver),
                ),
            )
        }
    val context =
        object : RealmSearchContext, RealmComputationContext, RealmCommandContext {
            override val invocationId: String = "synthetic"
        }
    val hello = DataValue.named(LiteralMessageDefinition.use, DataValue.record(mapOf("value" to DataValue.StringValueWrapper("hello"))))

    test("both concrete messages, and only they, can be authored where any message is expected") {
        val catalog = messageCatalog
        val message = (catalog.resolve(SyntheticMessageDefinition.use.use) as Resolution.Ready).value

        catalog.concreteForms(message).map { it.use } shouldContainExactlyInAnyOrder
            listOf(LiteralMessageDefinition.use.use, RepeatedMessageDefinition.use.use)
    }

    test("native bindings preserve named identity and serialized field names") {
        val catalog = messageCatalog
        val bindings = messageBindings
        val checked = (catalog.resolve(RepeatedMessageDefinition.use.use) as Resolution.Ready).value

        @Suppress("UNCHECKED_CAST")
        val binding = bindings.bind(checked) as NativeBinding<RepeatedMessage>
        val source = RepeatedMessage("hello", 3)

        val encoded = binding.encode(source)

        encoded shouldBe
            DataValue.named(
                RepeatedMessageDefinition.use,
                DataValue.record(
                    mapOf(
                        "value" to DataValue.StringValueWrapper("hello"),
                        "repeat_count" to DataValue.integer(BigInteger.valueOf(3)),
                    ),
                ),
            )
        val complete = checked.complete(encoded) as CompletenessResult.Complete
        binding.decode(complete.value) shouldBe source
    }

    test("containing page and ordinary referenced page retain separate native fields") {
        val catalog = generatedTypeCatalog("conformance presentation")
        val factories =
            generatedProviders<NativeBindingFactory>(GeneratedProviderKind.NativeBinding)
                .distinctBy(NativeBindingFactory::provider)
        val bindings = FactoryNativeBindingRegistry(catalog, factories)
        val checked = (catalog.resolve(SyntheticPageReferenceEntryDefinition.use.use) as Resolution.Ready).value

        @Suppress("UNCHECKED_CAST")
        val binding = bindings.bind(checked) as NativeBinding<SyntheticPageReferenceEntry>
        val source =
            SyntheticPageReferenceEntry(
                page = Ref(ResourceId("containing")),
                name = "Reference",
                placement = GraphPlacement(),
                referencedPage = Ref(ResourceId("referenced")),
            )
        val encoded = binding.encode(source)
        val fields = ((encoded as DataValue.NamedWrapper).payload as DataValue.RecordWrapper).value.fieldMap
        fields.keys shouldBe setOf("page", "name", "placement", "referencedPage")
        val containing = (fields.getValue("page") as DataValue.NamedWrapper).payload as DataValue.LinkWrapper
        val referenced = (fields.getValue("referencedPage") as DataValue.NamedWrapper).payload as DataValue.LinkWrapper
        containing.endpoint shouldBe PageElements.contract.second.id
        referenced.endpoint shouldBe SyntheticPageReferences.contract.first.id
        containing.value.target.resource shouldBe ResourceId("containing").toSkir()
        referenced.value.target.resource shouldBe ResourceId("referenced").toSkir()
        binding.decode((checked.complete(encoded) as CompletenessResult.Complete).value) shouldBe source
        checked.schema.fields
            .single { it.key == "page" }
            .type shouldBe
            TypeDefinitionId
                .qualified(
                    "relation",
                    "com.typewritermc.library.PageElements.Element",
                ).use(listOf(SyntheticPageDefinition.use.use))
    }

    test("the entry editor offers both message kinds, and the repeated message edits its count with a number input") {
        val runtime = DefaultPresentationRuntime()
        val repeated = RepeatedMessageEditorPresentation_RepeatedMessagePresentationProvider(runtime)
        val entry = SyntheticEntryEditorPresentation_SyntheticEntryPresentationProvider(runtime)
        LiteralMessageEditorPresentation_LiteralMessagePresentationProvider(
            runtime,
        ).descriptor(origin("literal", artifact = "typewritermc:conformance"))
        repeated.descriptor(origin("repeated", artifact = "typewritermc:conformance"))
        entry.descriptor(origin("entry", artifact = "typewritermc:conformance"))
        val catalog = generatedTypeCatalog("conformance presentation")

        val message =
            entry
                .build(
                    PresentationBuildBinding(
                        catalog.ready(SyntheticEntryDefinition.use.use).presentationTemplate(),
                        PresentationRole.WORKSPACE,
                    ),
                ).layout
                .elementsOf<PresentationElement.PolymorphicInputWrapper>()
                .single()
        message.value.concreteTypes.map { it.concreteType } shouldContainExactlyInAnyOrder
            listOf(LiteralMessageDefinition.use.use, RepeatedMessageDefinition.use.use)

        val countInputs =
            repeated
                .build(
                    PresentationBuildBinding(
                        catalog.ready(RepeatedMessageDefinition.use.use).presentationTemplate(),
                        PresentationRole.WORKSPACE,
                    ),
                ).layout
                .elementsOf<PresentationElement.NumericInputWrapper>()
                .filter { input -> input.value.control.binding.path.segments == listOf(PathSegment.createField(name = "repeat_count")) }
        countInputs shouldHaveSize 1
    }

    test("a generated search capability decodes its input and streams encoded results") {
        runTest {
            capabilities
                .requireSearch(searchMessagesCapability.id)
                .invoke(
                    context,
                    capabilityRuntime,
                    hello,
                    RealmSearchQuery.partial(normalizedQuery = "hello"),
                ).updates
                .toList() shouldBe
                listOf(
                    RealmSearchUpdate.Partial(
                        listOf(
                            DataValue.named(
                                RepeatedMessageDefinition.use,
                                DataValue.record(
                                    mapOf(
                                        "value" to DataValue.StringValueWrapper("hello"),
                                        "repeat_count" to DataValue.integer(BigInteger.ONE),
                                    ),
                                ),
                            ),
                        ),
                    ),
                    RealmSearchUpdate.Complete,
                )
        }
    }

    test("a generated computation capability decodes its input and encodes its result") {
        runTest {
            capabilities
                .requireComputation(repeatMessageCapability.id)
                .invoke(
                    context,
                    capabilityRuntime,
                    DataValue.named(
                        RepeatedMessageDefinition.use,
                        DataValue.record(
                            mapOf(
                                "value" to DataValue.StringValueWrapper("go"),
                                "repeat_count" to DataValue.integer(BigInteger.TWO),
                            ),
                        ),
                    ),
                ) shouldBe
                DataValue.named(
                    LiteralMessageDefinition.use,
                    DataValue.record(mapOf("value" to DataValue.StringValueWrapper("gogo"))),
                )
        }
    }

    test("a generated command capability decodes its input and returns its panel instructions") {
        runTest {
            capabilities
                .requireCommand(publishMessageCapability.id)
                .invoke(context, capabilityRuntime, hello)
                .instructions shouldBe
                listOf(PanelInstruction.createNotify(severity = NotificationSeverity.SUCCESS, message = "hello"))
        }
    }
}
