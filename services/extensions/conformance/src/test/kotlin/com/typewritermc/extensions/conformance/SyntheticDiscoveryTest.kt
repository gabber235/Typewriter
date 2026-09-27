package com.typewritermc.extensions.conformance

import com.typewritermc.authoring.GraphPlacement
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
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.KeyedTypeContribution
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.TypeContributionAssembler
import com.typewritermc.discovery.TypeDiscoveryContributionCodec
import com.typewritermc.elements.Element
import com.typewritermc.elements.Entry
import com.typewritermc.discovery.runtime.DiscoveryArtifactPackage
import com.typewritermc.discovery.runtime.DiscoveryModuleLoader
import com.typewritermc.elements.ContentRole
import com.typewritermc.elements.ElementRuntimeFacet
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.PageId
import com.typewritermc.library.Page
import com.typewritermc.pages.PageProvider
import com.typewritermc.presentation.PresentationCatalogAssembler
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.types.CatalogAbstractTypePrototype
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RolePresentationStatus
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.Ref
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDecodingContext
import com.typewritermc.types.TypeEncodingContext
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationNode

val SyntheticDiscoveryTest by testSuite {
    test("generates the element descriptor and stable concrete identity") {
        SyntheticEntryContentPrototype.descriptor.name shouldBe "Synthetic Entry"
        SyntheticEntryContentPrototype.type.id shouldBe
            TypeId.Declared(
                com.typewritermc.types.DeclaredTypeId
                    .parse("019d1c2a8f7b7cc18c2a4a7b2fd1e281"),
            )
    }

    test("generates nested cues and their ownership relations") {
        SyntheticSegmentContentPrototype.descriptor.role shouldBe ContentRole.CUE
        SyntheticKeyframeContentPrototype.descriptor.role shouldBe ContentRole.CUE
        val relations = declaredContribution().relations.associateBy { it.id }
        listOf(
            RelationId("019d3a87003070008000000000000030"),
            RelationId("019d3a87003170008000000000000031"),
        ).forEach { relation ->
            relations.getValue(relation).families.contains(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)) shouldBe true
        }
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
                    SyntheticEntryContentPrototype,
                    LiteralMessageTypewriterPrototype,
                    RepeatedMessageTypewriterPrototype,
                    CatalogAbstractTypePrototype(
                        runtimeType = SyntheticMessage::class,
                        type = parent.id,
                        definition = parent,
                    ),
                ),
                (contribution.definitions + typeContribution("elements.cbor").definitions).distinctBy { it.id },
            )
        val source =
            SyntheticEntry(
                "Synthetic Entry",
                GraphPlacement(0, 0, 4, 1),
                LiteralMessage("hello"),
            )

        val encoded = with(CodecContext(registry)) { SyntheticEntryContentPrototype.encode(source) }
        val message = (encoded as DataValue.Record).fields.getValue("message") as DataValue.Polymorphic

        message.concreteType shouldBe LiteralMessageTypewriterPrototype.type
        with(CodecContext(registry)) { SyntheticEntryContentPrototype.decode(encoded) } shouldBe source
    }

    test("encodes exact page references as typed page references") {
        val definitions = typeContribution("elements.cbor").definitions
        val entryDefinition =
            definitions.single {
                it.id.id == TypeId.Declared(DeclaredTypeId.parse("019d3a87000270008000000000000002"))
            }
        val pageType =
            (entryDefinition.representation as TypeExpression.Record)
                .fields
                .single { it.name == "page" }
                .type as TypeExpression.Reference
        pageType.target.id shouldBe
            TypeId.Declared(DeclaredTypeId.parse("019d3a87000170008000000000000001"))
        val registry =
            TypePrototypeRegistry(
                listOf(SyntheticPageReferenceEntryContentPrototype),
                definitions,
            )
        val source =
            SyntheticPageReferenceEntry(
                "Synthetic Page Reference",
                GraphPlacement(0, 0, 4, 1),
                Ref<SyntheticPage>(PageId("opening").value),
            )

        val encoded = with(CodecContext(registry)) { SyntheticPageReferenceEntryContentPrototype.encode(source) }
        val fields = (encoded as DataValue.Record).fields

        fields.getValue("page") shouldBe DataValue.Reference(PageId("opening").value)
        with(CodecContext(registry)) { SyntheticPageReferenceEntryContentPrototype.decode(encoded) } shouldBe source
    }

    test("loads generated page providers with contribution provenance") {
        val origin = ArtifactId("typewritermc:conformance")
        val sourcePart = "loaded"
        val discovery =
            TypeContributionAssembler.assemble(
                listOf(
                    KeyedTypeContribution(
                        key = ContributionKey(origin, sourcePart, ProducerId("types"), ContributionName("pages.cbor")),
                        contribution = typeContribution("pages.cbor"),
                    ),
                ),
            )
        val deployment =
            DiscoveryModuleLoader().load(
                artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(origin), DeploymentFacts(emptyMap())),
                domain = DiscoveryDomains.Realm,
                discovery = discovery,
            )

        deployment.use {
            val provider =
                it.application.koin
                    .getAll<PageProvider>()
                    .single()
            provider.namespace shouldBe origin.value
            provider.sourcePart shouldBe sourcePart
            provider.declarationName shouldBe "syntheticPage"
        }
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
        DiscoveryModuleLoader()
            .load(
                artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(origin), DeploymentFacts(emptyMap())),
                domain = DiscoveryDomains.Execution,
                discovery = discovery,
            ).use {
                it.application.koin
                    .getAll<RuntimeRegistrar>()
                    .map { registrar -> registrar::class } shouldBe
                    listOf(SyntheticRuntimeRegistrar::class)
                it.application.koin
                    .getAll<ElementRuntimeFacet<*>>()
                    .map { facet -> facet::class } shouldBe
                    listOf(SyntheticEntryFacet::class)
            }

        DiscoveryModuleLoader()
            .load(
                artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(origin), DeploymentFacts(emptyMap())),
                domain = DiscoveryDomains.Realm,
                discovery = discovery,
            ).use {
                it.application.koin.getAll<RuntimeRegistrar>() shouldHaveSize 0
                it.application.koin.getAll<ElementRuntimeFacet<*>>() shouldHaveSize 0
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
            val entry = catalog.types.definitions.single { definition -> definition.id == SyntheticEntryContentPrototype.type }
            val editor = catalog.definitions.single { definition -> definition.presentationId.name == "editor" }
            val root = editor.root.element as skirout.editor.v1.presentation.PresentationElement.ChildrenWrapper
            val section =
                root.value
                    .axisNodes()
                    .single()
                    .element as skirout.editor.v1.presentation.PresentationElement.SectionWrapper
            val sectionContent = section.value.child.element as skirout.editor.v1.presentation.PresentationElement.ChildrenWrapper
            val polymorphic =
                sectionContent.value
                    .axisNodes()
                    .single()
                    .element as
                    skirout.editor.v1.presentation.PresentationElement.PolymorphicInputWrapper
            val repeated = requireNotNull(polymorphic.value.concreteTypes[1].presentation)
            val repeatedFields = repeated.element as skirout.editor.v1.presentation.PresentationElement.ChildrenWrapper
            val repetitions =
                repeatedFields.value.axisNodes()[1].element as
                    skirout.editor.v1.presentation.PresentationElement.NumericInputWrapper
            val path =
                repetitions.value.binding.path.segments.map { segment ->
                    (segment as skirout.editor.v1.path.DataPathSegment.FieldWrapper).value.fieldName
                }

            (entry.rolePresentations[com.typewritermc.types.PresentationRole.EDITOR] as? com.typewritermc.types.RolePresentationStatus.Ready)
                ?.id?.name shouldBe "editor"
            entry.namedPresentations["compact"]?.name shouldBe "compact"
            path shouldBe listOf("message", "repeat_count")
            catalog.diagnostics shouldBe emptyList()
        }
    }

    test("generated core presentations bind inherited Page Element and Entry fields") {
        val core = ArtifactId("typewritermc:core")
        val conformance = ArtifactId("typewritermc:conformance")
        val contributions =
            listOf(
                core to "declared.cbor",
                core to "presentations.cbor",
                conformance to "declared.cbor",
                conformance to "elements.cbor",
            ).map { (origin, name) ->
                KeyedTypeContribution(
                    key = ContributionKey(origin, "common", ProducerId("types"), ContributionName(name)),
                    contribution =
                        if (origin == core) coreTypeContribution(name) else typeContribution(name),
                )
            }
        val page = TypeId.Qualified("com.typewritermc.library", "Page")
        val pageDefinitions = contributions.mapNotNull { keyed ->
            keyed.contribution.definitions.firstOrNull { it.id.id == page }
                ?.let { keyed.key to it }
        }
        pageDefinitions.map { it.second.representation } shouldBe
            List(pageDefinitions.size) { pageDefinitions.first().second.representation }
        val discovery = TypeContributionAssembler.assemble(contributions)
        DiscoveryModuleLoader().load(
            artifactPackage = DiscoveryArtifactPackage(emptyList(), null, setOf(core, conformance), DeploymentFacts(emptyMap())),
            domain = DiscoveryDomains.Realm,
            discovery = discovery,
        ).use { deployment ->
            val providers = deployment.application.koin.getAll<PresentationProvider>()
                .filter { it.targetType in setOf(Page::class, Element::class, Entry::class) }
            val catalog = PresentationCatalogAssembler.assemble(providers, deployment.prototypes, discovery.catalog)
            val byName = catalog.types.definitions.associateBy { it.qualifiedName }

            listOf("book", "name", "chapter", "priority", "elements") shouldBe
                discovery.catalog.effectiveRecordFields(byName.getValue(Page::class.qualifiedName).id).map { it.name }
            listOf("name", "placement") shouldBe
                discovery.catalog.effectiveRecordFields(byName.getValue(Entry::class.qualifiedName).id).map { it.name }
            catalog.diagnostics shouldBe emptyList()
            listOf(
                Page::class.qualifiedName to PresentationRole.EDITOR,
                Page::class.qualifiedName to PresentationRole.CREATION,
                Element::class.qualifiedName to PresentationRole.REFERENCE_SUMMARY,
                Element::class.qualifiedName to PresentationRole.AUTHORING_RESULT,
                Entry::class.qualifiedName to PresentationRole.GRAPH_NODE,
            ).forEach { (name, role) ->
                (byName.getValue(name).rolePresentations[role] is RolePresentationStatus.Ready) shouldBe true
            }
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

                registry
                    .requireCommand(publishMessageCapability.id)
                    .invoke(
                        context = SyntheticCapabilityContext,
                        prototypes = it.prototypes,
                        payload = DataValue.Record(mapOf("value" to DataValue.StringValue("saved"))),
                    ).instructions shouldBe
                    listOf(PanelInstruction.Notify(NotificationSeverity.SUCCESS, "saved"))
            }
        }
    }
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

private fun declaredContribution() = typeContribution("declared.cbor")

private fun typeContribution(name: String) =
    SyntheticEntry::class.java.classLoader
        .getResources("META-INF/typewriter/contributions/types/$name")
        .asSequence()
        .map { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()) } }
        .single { contribution ->
            contribution.prototypeBindings.any { it.runtimeClass.startsWith(CONFORMANCE_PACKAGE) } ||
                contribution.executableBindings.any { it.moduleProviderClass.startsWith(CONFORMANCE_PACKAGE) }
        }

private fun coreTypeContribution(name: String) =
    SyntheticEntry::class.java.classLoader
        .getResources("META-INF/typewriter/contributions/types/$name")
        .asSequence()
        .map { resource -> resource.openStream().use { TypeDiscoveryContributionCodec.decode(it.readAllBytes()) } }
        .single { contribution ->
            when (name) {
                "declared.cbor" ->
                    contribution.prototypeBindings.any { it.runtimeClass == "com.typewritermc.library.Book" } &&
                        contribution.definitions.none { it.qualifiedName?.startsWith(CONFORMANCE_PACKAGE) == true }
                "presentations.cbor" -> contribution.executableBindings.any {
                    it.moduleProviderClass == "com.typewritermc.library.CorePageEditorPresentationDiscoveryModule"
                }
                else -> false
            }
        }

private const val CONFORMANCE_PACKAGE = "com.typewritermc.extensions.conformance."

private class CodecContext(
    override val prototypes: TypePrototypeRegistry,
) : TypeEncodingContext,
    TypeDecodingContext

private data object SyntheticCapabilityContext :
    RealmSearchContext,
    RealmComputationContext,
    RealmCommandContext {
    override val invocationId: String = "synthetic"
}
