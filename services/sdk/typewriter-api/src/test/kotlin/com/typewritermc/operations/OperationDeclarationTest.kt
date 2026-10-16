package com.typewritermc.operations

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.ReadProjection
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.read
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.ContributionKey
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.EndpointId
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val OperationDeclarationTest by testSuite {
    test("duplicate local IDs become an attributed catalog failure without publishing tentative callbacks") {
        val declaration =
            collectOperations(origin(), "fixture.Ops", TypeTemplate.Named(target), projection) { scope ->
                repeat(2) {
                    scope.operation("duplicate", noInput()) {
                        label("Example")
                        prepare { }
                    }
                }
            }
        val catalog = DefaultCheckedCatalog(CatalogGeneration("test"), emptyList())
        val bound =
            bindOperations(listOf(declaration), catalog, FactoryNativeBindingRegistry(catalog, emptyList()), emptyList(), emptyList())

        bound.definitions shouldBe emptyList()
        bound.authoringProviders shouldBe emptyList()
        bound.diagnostics
            .single()
            .origins
            .single()
            .owner shouldBe origin().owner
        bound.failures
            .single()
            .cause.message!!
            .contains("Duplicate operation local ID") shouldBe true
    }

    test("declaration collection does not run invocation callbacks") {
        var invoked = false
        val declaration =
            collectOperations(origin(), "fixture.Ops", TypeTemplate.Named(target), projection) { scope ->
                scope.operation("example", noInput()) {
                    label("Example")
                    availability {
                        invoked = true
                        OperationAvailability.Enabled
                    }
                    prepare { invoked = true }
                }
            }

        declaration.failure shouldBe null
        declaration.operations.size shouldBe 1
        invoked shouldBe false
    }

    test("included command actions require a callable command descriptor and compatible payload") {
        val id = ResourceOperationId("fixture", "main", "fixture.Ops", "command")
        val capability = com.typewritermc.capability.CapabilityId("fixture:command")
        val action =
            skirout.editor.v1.action.EditorAction.RealmWrapper(
                skirout.editor.v1.action.RealmEditorAction.createCommand(
                    capabilityId =
                        skirout.editor.v1.type_catalog
                            .CapabilityId(value = capability.value),
                    payload =
                        com.typewritermc.types.skir.SkirTypeCodec
                            .encode(
                                com.typewritermc.presentation.ExpressionNode
                                    .Literal(DataValue.StringValue("example")),
                            ).getOrThrow(),
                ),
            )
        val declaration =
            collectOperations(origin(), "fixture.Ops", TypeTemplate.Named(target), projection) { scope ->
                scope.include(
                    ResourceOperationDefinition(
                        id,
                        OperationPresentation("Run"),
                        OperationTargets.Single(TypeTemplate.Named(target)),
                        action,
                    ),
                )
            }
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration("test"),
                listOf(
                    com.typewritermc.types.TypeDefinition(
                        target,
                        representation =
                            com.typewritermc.types.RepresentationTemplate
                                .Record(emptyList()),
                    ),
                ),
            )

        fun bind(capabilities: List<com.typewritermc.capability.RealmCapabilityDescriptor>) =
            bindOperations(
                listOf(declaration),
                catalog,
                FactoryNativeBindingRegistry(catalog, emptyList()),
                emptyList(),
                emptyList(),
                capabilities,
            )
        bind(emptyList()).definitions shouldBe emptyList()
        bind(
            listOf(
                com.typewritermc.capability.RealmCapabilityDescriptor.Command(
                    capability,
                    TypeUse.Scalar(com.typewritermc.types.ScalarKind.Boolean),
                ),
            ),
        ).definitions shouldBe emptyList()
        val valid =
            bind(
                listOf(
                    com.typewritermc.capability.RealmCapabilityDescriptor.Command(
                        capability,
                        TypeUse.Scalar(com.typewritermc.types.ScalarKind.Text),
                    ),
                ),
            )
        valid.diagnostics shouldBe emptyList()
        valid.definitions.single().id shouldBe id
    }

    test("new counterpart choices retain initialized values and validate their configured type") {
        val location = ValueLocation(ResourceId("owner"), ValuePath())

        fun choice(name: String) =
            CounterpartChoice.New(
                location,
                PreparedValue(
                    PreparedContent.Record(
                        AuthoringRecord(
                            TypeSelection.Complete(TypeUse.Named(target)),
                            mapOf("name" to DataValue.StringValue(name)),
                        ),
                    ),
                    emptyList(),
                ),
            )
        val source =
            LinkOccurrence(LinkOccurrenceId(EndpointId("source"), location), ResourceId("owner"), LinkTarget(ResourceId("target"), null))
        val proposed = choice("retained default")
        val choices = PreparationChoices(mapOf("inverse" to PreparationChoiceAnswer.Counterpart(proposed)))
        choices.require(
            PreparationChoice.Counterpart("inverse", "Choose inverse", source, listOf(choice("newly sampled default"))),
        ) shouldBe
            proposed
    }
}

private val target = TypeDefinitionId(TypeId.Qualified("fixture", "Resource"), 1)
private val projection =
    object : ReadProjection<ResourceDraft> {
        override val expected = TypeUse.Named(target)

        context(reads: AuthoredReads)
        override fun read(location: ValueLocation): Availability<ResourceDraft> = error("Not invoked while collecting declarations")
    }

private fun origin(): ProviderOrigin =
    ProviderOrigin(
        DeclarationOwner(
            ContributionKey(ContributionSourceId("fixture"), "main", ProducerId("ksp"), ContributionName("ops")),
            "fixture.Ops",
        ),
        ArtifactId("fixture"),
        "main",
    )
