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
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderIndexEntry
import com.typewritermc.discovery.GeneratedProviderInstantiator
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.RuntimeRegistrarId
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.PageElements
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.ACYCLIC_RELATION_FAMILY_ID
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.declared
import com.typewritermc.types.endpoint
import com.typewritermc.types.fieldMap
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.capability.NotificationSeverity
import skirout.editor.v1.capability.PanelInstruction
import skirout.editor.v1.catalog.EndpointCardinality
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
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import java.math.BigInteger
import java.util.Collections

val SyntheticDiscoveryTest by testSuite {
    test("generates stable declarations for the entry and polymorphic message family") {
        SyntheticEntryDefinition.id shouldBe
            TypeDefinitionId.declared("019d1c2a8f7b7cc18c2a4a7b2fd1e281")
        val entryFields = (SyntheticEntryDefinition.definition.representation as RepresentationTemplate.RecordWrapper).value.fields
        entryFields.map { it.owner.name } shouldContainExactly listOf("page", "name", "placement", "message", "cues")

        (SyntheticMessageDefinition.definition.representation as RepresentationTemplate.RecordWrapper).value.abstract_ shouldBe true
        LiteralMessageDefinition.definition.parents
            .single()
            .definition shouldBe SyntheticMessageDefinition.id
        RepeatedMessageDefinition.definition.parents
            .single()
            .definition shouldBe SyntheticMessageDefinition.id
    }

    test("generates ownership relations and their concrete authored bindings") {
        SyntheticEntryCues.contract.families shouldBe
            setOf(RelationFamilyId(value = ACYCLIC_RELATION_FAMILY_ID), RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID))
        SyntheticEntryCues.contract.first.cardinality shouldBe EndpointCardinality.ONE
        SyntheticEntryCues.contract.second.cardinality shouldBe EndpointCardinality.MANY
        SyntheticEntryEndpointBindings.bindings
            .single {
                it.valueOwner == SyntheticEntryDefinition.id &&
                    it.target == SyntheticSegmentDefinition.id.template()
            }.let { binding ->
                binding.valueOwner shouldBe SyntheticEntryDefinition.id
                binding.target shouldBe SyntheticSegmentDefinition.id.template()
                binding.containsCollection shouldBe true
            }

        SyntheticSegmentKeyframes.contract.families shouldBe
            setOf(RelationFamilyId(value = ACYCLIC_RELATION_FAMILY_ID), RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID))
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

    test("generated page reference bindings retain the exact relation endpoint and target") {
        val pageField =
            (SyntheticPageReferenceEntryDefinition.definition.representation as RepresentationTemplate.RecordWrapper)
                .value
                .fields
                .single { it.owner.name == "referencedPage" }
                .type as TypeTemplate.NamedWrapper

        pageField.value.definition shouldBe
            TypeDefinitionId.qualified("relation", "com.typewritermc.extensions.conformance.SyntheticPageReferences.Entry")
        SyntheticPageReferenceEntryEndpointBindings.bindings
            .single {
                it.endpoint == SyntheticPageReferences.contract.first.id
            }.target shouldBe
            SyntheticPageDefinition.id.template()
        SyntheticPageReferences.contract.second.resource shouldBe
            com.typewritermc.library.PageDefinition.id
                .namedTemplate()
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

    test("generated presentation composes concrete polymorphic controls with serialized paths") {
        val runtime = DefaultPresentationRuntime()
        val literal =
            LiteralMessageEditorPresentation_LiteralMessagePresentationProvider(runtime)
        val repeated =
            RepeatedMessageEditorPresentation_RepeatedMessagePresentationProvider(runtime)
        val entry =
            SyntheticEntryEditorPresentation_SyntheticEntryPresentationProvider(runtime)
        literal.descriptor(providerOrigin("literal"))
        repeated.descriptor(providerOrigin("repeated"))
        entry.descriptor(providerOrigin("entry"))
        val catalog = presentationCatalog()
        val checked = (catalog.resolve(SyntheticEntryDefinition.use.use) as Resolution.Ready).value

        val root = entry.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)).layout
        val children = (root.element as PresentationElement.ChildrenWrapper).value.axisNodes()
        val polymorphic =
            children
                .mapNotNull { it.element as? PresentationElement.PolymorphicInputWrapper }
                .single()
        polymorphic.value.concreteTypes shouldHaveSize 2
        val repeatedPresentation = requireNotNull(polymorphic.value.concreteTypes[1].presentation)
        (repeatedPresentation.element is PresentationElement.InvocationWrapper) shouldBe true
        val repeatedChecked = (catalog.resolve(RepeatedMessageDefinition.use.use) as Resolution.Ready).value
        val repeatedFields =
            (
                repeated
                    .build(
                        PresentationBuildBinding(
                            repeatedChecked.presentationTemplate(),
                            PresentationRole.WORKSPACE,
                        ),
                    ).layout.element as
                    PresentationElement.ChildrenWrapper
            ).value
                .axisNodes()
        val repetitions = repeatedFields[1].element as PresentationElement.NumericInputWrapper
        repetitions.value.control.binding.path.segments.single().let { segment ->
            (segment as PathSegment.FieldWrapper).value.name shouldBe "repeat_count"
        }
    }

    test("generated registrar contributes execution scope ownership") {
        runTest {
            val scope = RecordingRuntimeScope(this)

            val provider = SyntheticRuntimeRegistrarGeneratedRegistrarProvider()
            provider.descriptor.domains shouldBe setOf(DiscoveryDomains.Execution)
            provider.descriptor.id shouldBe RuntimeRegistrarId("synthetic")
            val registrar =
                provider.bind(
                    GeneratedProviderInstantiator { type -> type.getDeclaredConstructor().newInstance() },
                )
            with(scope) { registrar.register() }

            scope.owned shouldBe 1
        }
    }

    test("generated Realm capability providers decode invoke and encode through one catalog") {
        runTest {
            val owner = SyntheticRealmCapabilities()
            val resolver = CapabilityOwnerResolver { owner }
            val registry =
                RealmCapabilityRegistry(
                    listOf(
                        SyntheticRealmCapabilitiesPublishMessageGeneratedCapabilityProvider().bind(resolver),
                        SyntheticRealmCapabilitiesRepeatMessageGeneratedCapabilityProvider().bind(resolver),
                        SyntheticRealmCapabilitiesSearchMessagesGeneratedCapabilityProvider().bind(resolver),
                    ),
                )
            val catalog = messageCatalog()
            val runtime = RealmCapabilityRuntime(catalog, messageBindings(catalog))

            registry.definitions.map { it.id } shouldBe
                listOf(publishMessageCapability.id, repeatMessageCapability.id, searchMessagesCapability.id)
                    .sortedBy { it.value }
            val literal =
                DataValue.named(
                    LiteralMessageDefinition.use,
                    DataValue.record(mapOf("value" to DataValue.StringValueWrapper("hello"))),
                )
            registry
                .requireSearch(searchMessagesCapability.id)
                .invoke(SyntheticCapabilityContext, runtime, literal, RealmSearchQuery.partial(normalizedQuery = "hello"))
                .updates
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

            registry.requireComputation(repeatMessageCapability.id).invoke(
                SyntheticCapabilityContext,
                runtime,
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
            registry
                .requireCommand(publishMessageCapability.id)
                .invoke(SyntheticCapabilityContext, runtime, literal)
                .instructions shouldBe
                listOf(PanelInstruction.createNotify(severity = NotificationSeverity.SUCCESS, message = "hello"))
        }
    }
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

private class RecordingRuntimeScope(
    override val coroutineScope: CoroutineScope,
) : RuntimeScope {
    override val facts: DeploymentFacts = DeploymentFacts(emptyMap())
    var owned: Int = 0
        private set

    override fun own(cleanup: suspend () -> Unit) {
        owned += 1
    }

    override fun <R : AutoCloseable> own(resource: R): R {
        owned += 1
        return resource
    }
}

private data object SyntheticCapabilityContext :
    RealmSearchContext,
    RealmComputationContext,
    RealmCommandContext {
    override val invocationId: String = "synthetic"
}
