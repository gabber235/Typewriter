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
    test("both concrete messages, and only they, can be authored where any message is expected") {
        val catalog = messageCatalog()
        val message = (catalog.resolve(SyntheticMessageDefinition.use.use) as Resolution.Ready).value

        catalog.concreteForms(message).map { it.use } shouldContainExactlyInAnyOrder
            listOf(LiteralMessageDefinition.use.use, RepeatedMessageDefinition.use.use)
    }

    test("native bindings preserve named identity and serialized field names") {
        val catalog = messageCatalog()
        val bindings = messageBindings(catalog)
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
        val entries = generatedProviderEntries()
        val catalog = presentationCatalog()
        val factories =
            entries
                .filter { it.kind == GeneratedProviderKind.NativeBinding }
                .map { generatedProviderInstance(it.providerClass) as NativeBindingFactory }
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
        LiteralMessageEditorPresentation_LiteralMessagePresentationProvider(runtime).descriptor(providerOrigin("literal"))
        repeated.descriptor(providerOrigin("repeated"))
        entry.descriptor(providerOrigin("entry"))
        val catalog = presentationCatalog()

        val message =
            entry
                .build(catalog.workspaceOf(SyntheticEntryDefinition.use.use))
                .layout
                .flattened()
                .filterIsInstance<PresentationElement.PolymorphicInputWrapper>()
                .single()
        message.value.concreteTypes.map { it.concreteType } shouldContainExactlyInAnyOrder
            listOf(LiteralMessageDefinition.use.use, RepeatedMessageDefinition.use.use)

        val countInputs =
            repeated
                .build(catalog.workspaceOf(RepeatedMessageDefinition.use.use))
                .layout
                .flattened()
                .filterIsInstance<PresentationElement.NumericInputWrapper>()
                .filter { input -> input.value.control.binding.path.segments == listOf(PathSegment.createField(name = "repeat_count")) }
        countInputs shouldHaveSize 1
    }

    test("a generated search capability decodes its input and streams encoded results") {
        runTest {
            capabilities()
                .requireSearch(searchMessagesCapability.id)
                .invoke(
                    SyntheticCapabilityContext,
                    capabilityRuntime(),
                    literal("hello"),
                    RealmSearchQuery.partial(normalizedQuery = "hello"),
                ).updates
                .toList() shouldBe
                listOf(RealmSearchUpdate.Partial(listOf(repeated("hello", BigInteger.ONE))), RealmSearchUpdate.Complete)
        }
    }

    test("a generated computation capability decodes its input and encodes its result") {
        runTest {
            capabilities()
                .requireComputation(repeatMessageCapability.id)
                .invoke(SyntheticCapabilityContext, capabilityRuntime(), repeated("go", BigInteger.TWO)) shouldBe literal("gogo")
        }
    }

    test("a generated command capability decodes its input and returns its panel instructions") {
        runTest {
            capabilities()
                .requireCommand(publishMessageCapability.id)
                .invoke(SyntheticCapabilityContext, capabilityRuntime(), literal("hello"))
                .instructions shouldBe
                listOf(PanelInstruction.createNotify(severity = NotificationSeverity.SUCCESS, message = "hello"))
        }
    }
}

private fun capabilities(): RealmCapabilityRegistry {
    val resolver = CapabilityOwnerResolver { SyntheticRealmCapabilities() }
    return RealmCapabilityRegistry(
        listOf(
            SyntheticRealmCapabilitiesPublishMessageGeneratedCapabilityProvider().bind(resolver),
            SyntheticRealmCapabilitiesRepeatMessageGeneratedCapabilityProvider().bind(resolver),
            SyntheticRealmCapabilitiesSearchMessagesGeneratedCapabilityProvider().bind(resolver),
        ),
    )
}

private fun capabilityRuntime(): RealmCapabilityRuntime {
    val catalog = messageCatalog()
    return RealmCapabilityRuntime(catalog, messageBindings(catalog))
}

private fun literal(value: String) =
    DataValue.named(LiteralMessageDefinition.use, DataValue.record(mapOf("value" to DataValue.StringValueWrapper(value))))

private fun repeated(
    value: String,
    count: BigInteger,
) = DataValue.named(
    RepeatedMessageDefinition.use,
    DataValue.record(mapOf("value" to DataValue.StringValueWrapper(value), "repeat_count" to DataValue.integer(count))),
)

private fun DefaultCheckedCatalog.workspaceOf(use: skirout.editor.v1.type_catalog.TypeUse): PresentationBuildBinding =
    PresentationBuildBinding((resolve(use) as Resolution.Ready).value.presentationTemplate(), PresentationRole.WORKSPACE)

/** The element of [this] and every element nested in its children, depth first in reading order. */
private fun PresentationNode.flattened(): List<PresentationElement> {
    val element = element ?: return emptyList()
    val children = (element as? PresentationElement.ChildrenWrapper)?.value?.axisNodes().orEmpty()
    return listOf(element) + children.flatMap { it.flattened() }
}

private fun messageCatalog() =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "conformance messages"),
        listOf(
            SyntheticMessageDefinition.definition,
            LiteralMessageDefinition.definition,
            RepeatedMessageDefinition.definition,
        ),
    )

private fun messageBindings(catalog: DefaultCheckedCatalog) =
    FactoryNativeBindingRegistry(
        catalog,
        listOf(LiteralMessageNativeBindingFactory, RepeatedMessageNativeBindingFactory),
    )

private fun generatedProviderEntries(): List<GeneratedProviderIndexEntry> =
    Collections
        .list(
            requireNotNull(
                Thread.currentThread().contextClassLoader,
            ).getResources(GENERATED_PROVIDER_INDEX_PATH),
        ).flatMap { resource ->
            resource.openStream().bufferedReader().use {
                GeneratedProviderIndex
                    .parse(it.readText())
            }
        }.distinct()

private fun generatedProviderInstance(name: String): Any {
    val type = Class.forName(name)
    return type.fields.singleOrNull { it.name == "INSTANCE" }?.get(null) ?: type.getConstructor().newInstance()
}

private fun presentationCatalog(): DefaultCheckedCatalog {
    val definitions =
        generatedProviderEntries()
            .filter { it.kind == GeneratedProviderKind.Type }
            .map { (generatedProviderInstance(it.providerClass) as GeneratedTypeProvider).definition }
            .distinctBy(TypeDefinition::id)
    return DefaultCheckedCatalog(
        CatalogGeneration(value = "conformance presentation"),
        StandardTypes.definitions + definitions,
    )
}

private fun providerOrigin(local: String): ProviderOrigin {
    val source = ContributionSourceId("artifact:typewritermc:conformance")
    val key = contributionKey(source, "common", ProducerId("types"), ContributionName(local))
    return ProviderOrigin(
        owner = DeclarationOwner(source = key, localIdentity = local),
        artifact = ArtifactId("typewritermc:conformance"),
        sourcePart = "common",
    )
}

private fun ChildrenElement.axisNodes(): List<PresentationNode> =
    when (this) {
        is ChildrenElement.ColumnWrapper -> {
            value.children.map { it.node() }
        }

        is ChildrenElement.RowWrapper -> {
            value.children.map { it.node() }
        }

        is ChildrenElement.WrapWrapper -> {
            value.children
        }

        is ChildrenElement.GridWrapper -> {
            value.children
        }

        is ChildrenElement.StackWrapper -> {
            value.children.map {
                when (it) {
                    is skirout.editor.v1.presentation.StackChild.PositionedWrapper -> it.value.child
                    is skirout.editor.v1.presentation.StackChild.FlowWrapper -> it.value
                    else -> error("Unknown stack child")
                }
            }
        }

        ChildrenElement.UNKNOWN,
        is ChildrenElement.Unknown,
        -> {
            emptyList()
        }
    }

private fun AxisChild.node(): PresentationNode =
    when (this) {
        is AxisChild.FixedWrapper -> value

        is AxisChild.FlexibleWrapper -> value.child

        AxisChild.UNKNOWN,
        is AxisChild.Unknown,
        -> error("Unknown axis child")
    }

private data object SyntheticCapabilityContext :
    RealmSearchContext,
    RealmComputationContext,
    RealmCommandContext {
    override val invocationId: String = "synthetic"
}
