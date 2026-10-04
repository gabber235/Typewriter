package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.capability.NotificationSeverity
import com.typewritermc.capability.PanelInstruction
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCapabilityRuntime
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchQuery
import com.typewritermc.capability.RealmSearchUpdate
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CapabilityOwnerResolver
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.TypewriterRegistrar
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import java.math.BigInteger

val SyntheticDiscoveryTest by testSuite {
    test("generates stable declarations for the entry and polymorphic message family") {
        SyntheticEntryDefinition.id shouldBe
            TypeDefinitionId(TypeId.Declared(DeclaredTypeId.parse("019d1c2a8f7b7cc18c2a4a7b2fd1e281")), 1)
        val entryFields = (SyntheticEntryDefinition.definition.representation as RepresentationTemplate.Record).fields
        entryFields.map { it.owner.name } shouldContainExactly listOf("name", "placement", "message", "cues")

        (SyntheticMessageDefinition.definition.representation as RepresentationTemplate.Record).abstract shouldBe true
        LiteralMessageDefinition.definition.parents
            .single()
            .definition shouldBe SyntheticMessageDefinition.id
        RepeatedMessageDefinition.definition.parents
            .single()
            .definition shouldBe SyntheticMessageDefinition.id
    }

    test("generates ownership relations and their concrete authored bindings") {
        SyntheticEntryCues.contract.families shouldBe setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID))
        SyntheticEntryCues.contract.first.cardinality shouldBe EndpointCardinality.One
        SyntheticEntryCues.contract.second.cardinality shouldBe EndpointCardinality.Many
        SyntheticEntryEndpointBindings.bindings.single().let { binding ->
            binding.valueOwner shouldBe SyntheticEntryDefinition.id
            binding.target shouldBe TypeTemplate.Named(SyntheticSegmentDefinition.id)
            binding.containsCollection shouldBe true
        }

        SyntheticSegmentKeyframes.contract.families shouldBe setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID))
    }

    test("native bindings preserve named identity and serialized field names") {
        val catalog = messageCatalog()
        val bindings = messageBindings(catalog)
        val checked = (catalog.resolve(RepeatedMessageDefinition.use) as Resolution.Ready).value

        @Suppress("UNCHECKED_CAST")
        val binding = bindings.bind(checked) as com.typewritermc.types.NativeBinding<RepeatedMessage>
        val source = RepeatedMessage("hello", 3)

        val encoded = binding.encode(source)

        encoded shouldBe
            DataValue.Named(
                RepeatedMessageDefinition.use,
                DataValue.Record(
                    mapOf(
                        "value" to DataValue.StringValue("hello"),
                        "repeat_count" to DataValue.Integer(BigInteger.valueOf(3)),
                    ),
                ),
            )
        val complete = checked.complete(encoded) as CompletenessResult.Complete
        binding.decode(complete.value) shouldBe source
    }

    test("generated page reference bindings retain the exact relation endpoint and target") {
        val pageField =
            (SyntheticPageReferenceEntryDefinition.definition.representation as RepresentationTemplate.Record)
                .fields
                .single { it.owner.name == "page" }
                .type as TypeTemplate.Named

        pageField.definition shouldBe
            TypeDefinitionId(
                TypeId.Qualified("relation", "com.typewritermc.extensions.conformance.SyntheticPageReferences.Entry"),
                1,
            )
        SyntheticPageReferenceEntryEndpointBindings.bindings.single().target shouldBe
            TypeTemplate.Named(SyntheticPageDefinition.id)
        SyntheticPageReferences.contract.second.resource shouldBe TypeTemplate.Named(com.typewritermc.library.PageDefinition.id)
    }

    test("generated presentation composes concrete polymorphic controls with serialized paths") {
        val runtime = DefaultPresentationRuntime()
        val literal =
            com_typewritermc_extensions_conformance_LiteralMessageEditorPresentation_LiteralMessagePresentationProvider(runtime)
        val repeated =
            com_typewritermc_extensions_conformance_RepeatedMessageEditorPresentation_RepeatedMessagePresentationProvider(runtime)
        val entry =
            com_typewritermc_extensions_conformance_SyntheticEntryEditorPresentation_SyntheticEntryPresentationProvider(runtime)
        literal.descriptor(providerOrigin("literal"))
        repeated.descriptor(providerOrigin("repeated"))
        entry.descriptor(providerOrigin("entry"))
        val catalog = presentationCatalog()
        val checked = (catalog.resolve(SyntheticEntryDefinition.use) as Resolution.Ready).value

        val root = entry.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.EDITOR)).layout
        val children = (root.element as PresentationElement.ChildrenWrapper).value.axisNodes()
        val polymorphic =
            children
                .mapNotNull { it.element as? PresentationElement.PolymorphicInputWrapper }
                .single()
        polymorphic.value.concreteTypes shouldHaveSize 2
        val repeatedPresentation = requireNotNull(polymorphic.value.concreteTypes[1].presentation)
        (repeatedPresentation.element is PresentationElement.InvocationWrapper) shouldBe true
        val repeatedChecked = (catalog.resolve(RepeatedMessageDefinition.use) as Resolution.Ready).value
        val repeatedFields =
            (
                repeated.build(PresentationBuildBinding(repeatedChecked.presentationTemplate(), PresentationRole.EDITOR)).layout.element as
                    PresentationElement.ChildrenWrapper
            ).value
                .axisNodes()
        val repetitions = repeatedFields[1].element as PresentationElement.NumericInputWrapper
        repetitions.value.binding.path.segments.single().let { segment ->
            (segment as skirout.editor.v1.type_catalog.PathSegment.FieldWrapper).value.name shouldBe "repeat_count"
        }
    }

    test("generated registrar contributes execution scope ownership") {
        runTest {
            val scope = RecordingRuntimeScope(this)

            with(scope) { SyntheticRuntimeRegistrar().register() }

            scope.owned shouldBe 1
            SyntheticRuntimeRegistrar::class.java.getAnnotation(TypewriterRegistrar::class.java).let { annotation ->
                annotation.execution shouldBe true
                annotation.realm shouldBe false
            }
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

            registry.descriptors.map { it.id } shouldBe
                listOf(publishMessageCapability.id, repeatMessageCapability.id, searchMessagesCapability.id)
                    .sortedBy { it.value }
            val literal =
                DataValue.Named(
                    LiteralMessageDefinition.use,
                    DataValue.Record(mapOf("value" to DataValue.StringValue("hello"))),
                )
            registry
                .requireSearch(searchMessagesCapability.id)
                .invoke(SyntheticCapabilityContext, runtime, literal, RealmSearchQuery("hello"))
                .updates
                .toList() shouldBe
                listOf(
                    RealmSearchUpdate.Partial(
                        listOf(
                            DataValue.Named(
                                RepeatedMessageDefinition.use,
                                DataValue.Record(
                                    mapOf(
                                        "value" to DataValue.StringValue("hello"),
                                        "repeat_count" to DataValue.Integer(BigInteger.ONE),
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
                DataValue.Named(
                    RepeatedMessageDefinition.use,
                    DataValue.Record(
                        mapOf(
                            "value" to DataValue.StringValue("go"),
                            "repeat_count" to DataValue.Integer(BigInteger.TWO),
                        ),
                    ),
                ),
            ) shouldBe
                DataValue.Named(
                    LiteralMessageDefinition.use,
                    DataValue.Record(mapOf("value" to DataValue.StringValue("gogo"))),
                )
            registry
                .requireCommand(publishMessageCapability.id)
                .invoke(SyntheticCapabilityContext, runtime, literal)
                .instructions shouldBe
                listOf(PanelInstruction.Notify(NotificationSeverity.SUCCESS, "hello"))
        }
    }
}

private fun messageCatalog() =
    DefaultCheckedCatalog(
        CatalogGeneration("conformance messages"),
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

private fun presentationCatalog(): DefaultCheckedCatalog {
    val messageField =
        (SyntheticEntryDefinition.definition.representation as RepresentationTemplate.Record)
            .fields
            .single { it.owner.name == "message" }
    val entry =
        TypeDefinition(
            id = SyntheticEntryDefinition.id,
            representation = RepresentationTemplate.Record(listOf(messageField)),
        )
    return DefaultCheckedCatalog(
        CatalogGeneration("conformance presentation"),
        listOf(
            entry,
            SyntheticMessageDefinition.definition,
            LiteralMessageDefinition.definition,
            RepeatedMessageDefinition.definition,
        ),
    )
}

private fun providerOrigin(local: String): ProviderOrigin {
    val source = ContributionSourceId("artifact:typewritermc:conformance")
    val key = ContributionKey(source, "common", ProducerId("types"), ContributionName(local))
    return ProviderOrigin(
        owner = DeclarationOwner(key, local),
        artifact = ArtifactId("typewritermc:conformance"),
        sourcePart = "common",
    )
}

private fun ChildrenElement.axisNodes(): List<PresentationNode> =
    when (this) {
        is ChildrenElement.ColumnWrapper -> value.children.map { it.node() }

        is ChildrenElement.RowWrapper -> value.children.map { it.node() }

        is ChildrenElement.WrapWrapper -> value.children

        is ChildrenElement.GridWrapper -> value.children

        is ChildrenElement.StackWrapper -> value.children

        ChildrenElement.UNKNOWN,
        is ChildrenElement.Unknown,
        -> emptyList()
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
