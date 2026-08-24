package com.typewritermc.extensions.conformance

import com.typewritermc.capability.NotificationSeverity
import com.typewritermc.capability.PanelInstruction
import com.typewritermc.capability.RealmCapabilityProvider
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchQuery
import com.typewritermc.capability.RealmSearchUpdate
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ContributionName
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.KeyedTypeContribution
import com.typewritermc.discovery.ProducerId
import com.typewritermc.discovery.TypeContributionAssembler
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.discovery.runtime.DiscoveryArtifactPackage
import com.typewritermc.discovery.runtime.DiscoveryModuleLoader
import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.elements.ElementKind
import com.typewritermc.elements.ElementRuntimeFacet
import com.typewritermc.elements.EntryExecutionContext
import com.typewritermc.elements.EntryOutput
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.PresentationCatalogAssembler
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.TypeDecodingContext
import com.typewritermc.types.TypeEncodingContext
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest

val SyntheticDiscoveryTest by testSuite {
    test("generates the element descriptor and stable concrete identity") {
        SyntheticEntryElementPrototype.descriptor.kind shouldBe ElementKind.ENTRY
        SyntheticEntryElementPrototype.descriptor.name shouldBe "Synthetic Entry"
        SyntheticEntryElementPrototype.type.id shouldBe
            TypeId.Declared(
                com.typewritermc.types.DeclaredTypeId
                    .parse("019d1c2a8f7b7cc18c2a4a7b2fd1e281"),
            )
    }

    test("synthesizes an abstract prototype with both stable implementations") {
        val contribution = declaredContribution()
        val parent =
            contribution.definitions.single {
                it.kind == NominalTypeKind.SEALED_ABSTRACT &&
                    it.id.id == TypeId.Qualified("com.typewritermc.extensions.conformance", "SyntheticMessage")
            }
        val abstractPrototype =
            CatalogAbstractTypePrototype(
                runtimeType = SyntheticMessage::class,
                type = parent.id,
                definition = parent,
            )
        val registry =
            TypePrototypeRegistry(
                listOf(LiteralMessageTypewriterPrototype, RepeatedMessageTypewriterPrototype, abstractPrototype),
            )

        with(registry) {
            abstractPrototype.implementations() shouldHaveSize 2
        }
        val value = LiteralMessage("hello")
        val encoded = with(registry) { with(CodecContext(registry)) { abstractPrototype.encode(value) } }
        encoded shouldBe
            DataValue.Polymorphic(
                LiteralMessageTypewriterPrototype.type,
                DataValue.Record(mapOf("value" to DataValue.StringValue("hello"))),
            )
        with(registry) { with(CodecContext(registry)) { abstractPrototype.decode(encoded) } } shouldBe value
    }

    test("executes the synthetic entry through a context parameter") {
        runTest {
            val output = RecordingOutput()
            val context = TestEntryExecutionContext(this, output)
            with(context) {
                SyntheticEntry(RepeatedMessage("hello", 2)).execute()
            }

            output.values shouldBe listOf(RepeatedMessage("hello", 2))
        }
    }

    test("encodes nested polymorphism through stable concrete identities") {
        val contribution = declaredContribution()
        val parent =
            contribution.definitions.single {
                it.kind == NominalTypeKind.SEALED_ABSTRACT &&
                    it.id.id == TypeId.Qualified("com.typewritermc.extensions.conformance", "SyntheticMessage")
            }
        val registry =
            TypePrototypeRegistry(
                listOf(
                    SyntheticEntryElementPrototype,
                    LiteralMessageTypewriterPrototype,
                    RepeatedMessageTypewriterPrototype,
                    CatalogAbstractTypePrototype(
                        runtimeType = SyntheticMessage::class,
                        type = parent.id,
                        definition = parent,
                    ),
                ),
            )
        val source = SyntheticEntry(LiteralMessage("hello"))

        val encoded = with(CodecContext(registry)) { SyntheticEntryElementPrototype.encode(source) }
        val message = (encoded as DataValue.Record).fields.getValue("message") as DataValue.Polymorphic

        message.concreteType shouldBe LiteralMessageTypewriterPrototype.type
        with(CodecContext(registry)) { SyntheticEntryElementPrototype.decode(encoded) } shouldBe source
    }

    test("loads generated facets and registrars only for execution discovery") {
        val origin = ArtifactId("typewritermc:conformance")
        val contributions =
            listOf("declared.cbor", "elements.cbor", "registrars.cbor").map { name ->
                KeyedTypeContribution(
                    key = ContributionKey(origin, "common", ProducerId("types"), ContributionName(name)),
                    contribution = typeContribution(name),
                )
            }
        val discovery = TypeContributionAssembler.assemble(contributions)
        val deployment =
            DiscoveryModuleLoader().load(
                artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(origin), DeploymentFacts(emptyMap())),
                domain = DiscoveryDomains.Execution,
                discovery = discovery,
            )

        deployment.use {
            it.application.koin
                .getAll<RuntimeRegistrar>()
                .map { registrar -> registrar::class } shouldBe
                listOf(SyntheticRuntimeRegistrar::class)
            it.application.koin
                .getAll<ElementRuntimeFacet<*>>()
                .map { facet -> facet::class } shouldBe
                listOf(SyntheticEntryFacet::class)
        }
    }

    test("loads and compiles the generated presentation for Realm discovery") {
        val origin = ArtifactId("typewritermc:conformance")
        val contributions =
            listOf("declared.cbor", "elements.cbor", "presentations.cbor").map { name ->
                KeyedTypeContribution(
                    key = ContributionKey(origin, "common", ProducerId("types"), ContributionName(name)),
                    contribution = typeContribution(name),
                )
            }
        val discovery = TypeContributionAssembler.assemble(contributions)
        val deployment =
            DiscoveryModuleLoader().load(
                artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(origin), DeploymentFacts(emptyMap())),
                domain = DiscoveryDomains.Realm,
                discovery = discovery,
            )

        deployment.use {
            val providers = it.application.koin.getAll<PresentationProvider>()
            providers.size shouldBe 2
            val catalog =
                PresentationCatalogAssembler.assemble(
                    providers = providers,
                    prototypes = it.prototypes,
                    types = discovery.catalog,
                )
            val entry = catalog.types.definitions.single { definition -> definition.id == SyntheticEntryElementPrototype.type }
            val editor = catalog.definitions.single { definition -> definition.presentationId.name == "editor" }
            val root = editor.root.element as skirout.editor.v1.presentation.PresentationElement.ChildrenWrapper
            val section =
                root.value.children
                    .single()
                    .element as skirout.editor.v1.presentation.PresentationElement.SectionWrapper
            val sectionContent = section.value.child.element as skirout.editor.v1.presentation.PresentationElement.ChildrenWrapper
            val polymorphic =
                sectionContent.value.children
                    .single()
                    .element as
                    skirout.editor.v1.presentation.PresentationElement.PolymorphicInputWrapper
            val repeated = requireNotNull(polymorphic.value.concreteTypes[1].presentation)
            val repeatedFields = repeated.element as skirout.editor.v1.presentation.PresentationElement.ChildrenWrapper
            val repetitions =
                repeatedFields.value.children[1].element as
                    skirout.editor.v1.presentation.PresentationElement.NumericInputWrapper
            val path =
                repetitions.value.binding.path.segments.map { segment ->
                    (segment as skirout.editor.v1.path.DataPathSegment.FieldWrapper).value.fieldName
                }

            entry.defaultPresentationId?.name shouldBe "editor"
            entry.namedPresentations["compact"]?.name shouldBe "compact"
            path shouldBe listOf("message", "repeat_count")
            catalog.diagnostics shouldBe emptyList()
        }
    }

    test("loads and executes generated Realm capability providers") {
        runTest {
            val origin = ArtifactId("typewritermc:conformance")
            val contributions =
                listOf("declared.cbor", "elements.cbor", "realm_capabilities.cbor").map { name ->
                    KeyedTypeContribution(
                        key = ContributionKey(origin, "common", ProducerId("types"), ContributionName(name)),
                        contribution = typeContribution(name),
                    )
                }
            val discovery = TypeContributionAssembler.assemble(contributions)
            val deployment =
                DiscoveryModuleLoader().load(
                    artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(origin), DeploymentFacts(emptyMap())),
                    domain = DiscoveryDomains.Realm,
                    discovery = discovery,
                )

            deployment.use {
                val registry =
                    RealmCapabilityRegistry(
                        providers = it.application.koin.getAll<RealmCapabilityProvider>(),
                        prototypes = it.prototypes,
                    )

                registry.descriptors.map { descriptor -> descriptor.id } shouldBe
                    listOf(publishMessageCapability.id, repeatMessageCapability.id, searchMessagesCapability.id).sortedBy { id -> id.value }

                val search =
                    registry.requireSearch(searchMessagesCapability.id).invoke(
                        context = SyntheticCapabilityContext,
                        prototypes = it.prototypes,
                        payload = DataValue.Record(mapOf("value" to DataValue.StringValue("hello"))),
                        query = RealmSearchQuery("hello"),
                    )
                search.updates.toList() shouldBe
                    listOf(
                        RealmSearchUpdate.Partial(
                            listOf(
                                DataValue.Record(
                                    mapOf(
                                        "value" to DataValue.StringValue("hello"),
                                        "repeat_count" to DataValue.Integer(java.math.BigInteger.ONE),
                                    ),
                                ),
                            ),
                        ),
                        RealmSearchUpdate.Complete,
                    )

                registry.requireComputation(repeatMessageCapability.id).invoke(
                    context = SyntheticCapabilityContext,
                    prototypes = it.prototypes,
                    payload =
                        DataValue.Record(
                            mapOf(
                                "value" to DataValue.StringValue("go"),
                                "repeat_count" to DataValue.Integer(java.math.BigInteger.TWO),
                            ),
                        ),
                ) shouldBe DataValue.Record(mapOf("value" to DataValue.StringValue("gogo")))

                registry.requireCommand(publishMessageCapability.id).invoke(
                    context = SyntheticCapabilityContext,
                    prototypes = it.prototypes,
                    payload = DataValue.Record(mapOf("value" to DataValue.StringValue("saved"))),
                ).instructions shouldBe
                    listOf(PanelInstruction.Notify(NotificationSeverity.SUCCESS, "saved"))
            }
        }
    }
}

private fun declaredContribution() = typeContribution("declared.cbor")

private fun typeContribution(name: String) =
    TypeDiscoveryContributionCodec.decode(
        requireNotNull(SyntheticEntry::class.java.getResourceAsStream("/META-INF/typewriter/contributions/types/$name"))
            .use { it.readAllBytes() },
    )

private class CodecContext(
    override val prototypes: TypePrototypeRegistry,
) : TypeEncodingContext,
    TypeDecodingContext

private class RecordingOutput : EntryOutput {
    val values = mutableListOf<Any>()

    override suspend fun send(value: Any) {
        values += value
    }
}

private class TestEntryExecutionContext(
    override val coroutineScope: CoroutineScope,
    override val output: EntryOutput,
) : EntryExecutionContext {
    override val prototypes = TypePrototypeRegistry(emptyList())
    override val facts = com.typewritermc.discovery.DeploymentFacts(emptyMap())

    override fun own(cleanup: suspend () -> Unit) = Unit

    override fun <Resource : AutoCloseable> own(resource: Resource): Resource = resource
}

private data object SyntheticCapabilityContext :
    RealmSearchContext,
    RealmComputationContext,
    RealmCommandContext {
    override val invocationId: String = "synthetic"
}
