@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.operations

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparedValue
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.typedPath
import com.typewritermc.capability.CapabilityId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.frameworkContributions
import com.typewritermc.types.DataValue
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.operation.OperationCardinality
import skirout.editor.v1.operation.OperationDrop
import skirout.editor.v1.operation.OperationGroup
import skirout.editor.v1.operation.OperationInspector
import skirout.editor.v1.operation.OperationShortcut
import skirout.editor.v1.operation.ResourceOperationDefinition
import skirout.editor.v1.presentation.ButtonVariant
import skirout.editor.v1.presentation.HeaderActionTone
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.TypeDefinitionId

val OperationDeclarationTest by testSuite {
    test("declared appearance publishes with the tone following the group") {
        listOf(ButtonVariant.FILLED, ButtonVariant.OUTLINED, ButtonVariant.TEXT).forEach { variant ->
            val declaration =
                collect<Unit> {
                    appearance {
                        icon("mdi:delete-outline")
                        group(OperationGroup.DESTRUCTIVE, order = 3)
                        inspector(OperationInspector.ButtonWrapper(variant))
                    }
                    gestures { shortcut(OperationShortcut.DELETE) }
                    confirm("Remove these?") { action("Remove") }
                    prepare { }
                }
            val definition = bind(declaration).single()
            val appearance = definition.presentation
            appearance.label shouldBe "Example operation"
            appearance.icon shouldBe "mdi:delete-outline"
            appearance.order shouldBe 3
            appearance.tone shouldBe HeaderActionTone.DESTRUCTIVE
            appearance.shortcut shouldBe OperationShortcut.DELETE
            appearance.confirmation?.title shouldBe "Example operation"
            appearance.confirmation?.confirmationLabel shouldBe "Remove"
            (appearance.inspector as OperationInspector.ButtonWrapper).value shouldBe variant
            definition.capability.value shouldBe definition.id.capability.value
            definition.targets.cardinality shouldBe OperationCardinality.SELECTION
            definition.drop shouldBe null
        }
    }

    test("the core catalog publishes every core operation for any resource with labels from object names") {
        val assembly = frameworkContributions().assemble(CatalogAssemblyContext(CatalogGeneration("core operations")))
        assembly.operations.diagnostics shouldBe emptyList()
        val definitions = assembly.editorCatalog.resourceOperations.associateBy { it.id.declaration.substringAfterLast('.') }
        definitions.mapValues { it.value.presentation.label } shouldBe
            mapOf(
                "Delete" to "Delete",
                "Duplicate" to "Duplicate",
                "MoveToOwner" to "Move to",
                "LinkWith" to "Link with",
                "Unlink" to "Unlink",
                "LinkWithDuplicate" to "Link with duplicate",
            )
        definitions.values.all { it.targets.subject == skirout.editor.v1.type_catalog.ResourceTarget.ANY_RESOURCE } shouldBe true
        definitions.getValue("LinkWithDuplicate").targets.cardinality shouldBe OperationCardinality.SINGLE
        definitions.getValue("Delete").presentation.shortcut shouldBe OperationShortcut.DELETE
        definitions.getValue("MoveToOwner").drop shouldBe drop(ValuePath().field("destination"), "Move here")
        definitions.getValue("LinkWith").drop shouldBe drop(ValuePath().field("target"), "Link")
        definitions.getValue("Unlink").drop shouldBe drop(ValuePath().field("target"), "Unlink")
        val searches =
            assembly.editorCatalog.capabilities.mapNotNull { capability ->
                (capability as? skirout.editor.v1.capability.CapabilityDefinition.SearchWrapper)?.value?.capabilityId?.value?.let(
                    ::CapabilityId,
                )
            }
        searches shouldContainAll
            listOf("MoveToOwner" to "destination", "LinkWith" to "target", "Unlink" to "target").map { (operation, field) ->
                definitions.getValue(operation).id.candidateSearch(ValuePath().field(field))
            }
    }

    test("a drop field must declare candidates and an operation fills at most one field on drop") {
        val uncandidated =
            collect<MoveToOwnerInput> {
                input { MoveToOwnerInputFields.destination { fillOnDrop() } }
                prepare { }
            }
        uncandidated.failure?.message!! shouldContain "must declare candidates"

        val second =
            typedPath<MoveToOwnerInput, ResourceId>(
                MoveToOwnerInputDefinition.id,
                ValuePath().field("second"),
                ResourceIdDefinition.use.use,
            )
        val twice =
            collect<MoveToOwnerInput> {
                input {
                    MoveToOwnerInputFields.destination {
                        candidates { emptySequence() }
                        fillOnDrop()
                    }
                    second {
                        candidates { emptySequence() }
                        fillOnDrop()
                    }
                }
                prepare { }
            }
        twice.failure?.message!! shouldContain "at most one input field on drop"
    }

    test("a blank label is rejected at catalog assembly with an attributed diagnostic") {
        val declaration =
            collect<Unit> {
                appearance { label(" ") }
                prepare { }
            }
        val catalog = DefaultCheckedCatalog(CatalogGeneration("test"), emptyList())
        val bound = bindOperations(listOf(declaration), catalog, FactoryNativeBindingRegistry(catalog, emptyList()), emptyList())
        bound.definitions shouldBe emptyList()
        bound.diagnostics
            .single()
            .origins
            .single()
            .owner shouldBe origin().owner
        bound.failures
            .single()
            .cause.message!! shouldContain "label cannot be blank"
    }

    test("input fields must belong to the operation input type") {
        val assembly = frameworkContributions().assemble(CatalogAssemblyContext(CatalogGeneration("foreign field")))
        val declaration =
            collect<MoveToOwnerInput>(OperationInput.Typed(MoveToOwnerInputDefinition.use)) {
                input {
                    val foreign =
                        typedPath<MoveToOwnerInput, ResourceId>(
                            LinkWithInputDefinition.id,
                            ValuePath().field("destination"),
                            ResourceIdDefinition.use.use,
                        )
                    foreign { candidates { emptySequence() } }
                }
                prepare { }
            }
        val bound = bindOperations(listOf(declaration), assembly.checked, assembly.bindings, emptyList())
        bound.definitions shouldBe emptyList()
        bound.failures
            .single()
            .cause.message!! shouldContain "belongs to another type"
    }

    test("declaration collection does not run invocation callbacks") {
        var invoked = false
        val declaration =
            collect<Unit> {
                availableWhen {
                    invoked = true
                    OperationAvailability.ENABLED
                }
                prepare { invoked = true }
            }

        declaration.failure shouldBe null
        declaration.collected?.presentation?.label shouldBe "Example operation"
        invoked shouldBe false
    }

    test("new counterpart choices retain initialized values and validate their configured type") {
        val location = ValueLocation(ResourceId("owner"), ValuePath())

        fun choice(name: String) =
            CounterpartChoice.New(
                location,
                PreparedValue(
                    PreparedContent.Record(
                        AuthoringRecord(
                            TypeSelection.Complete(target.namedUse()),
                            mapOf("name" to DataValue.StringValue(name)),
                        ),
                    ),
                    emptyList(),
                ),
            )
        val source =
            LinkOccurrence(
                LinkOccurrenceId(EndpointId(value = "source"), location),
                ResourceId("owner"),
                LinkTarget(ResourceId("target"), null),
            )
        val proposed = choice("retained default")
        val choices = PreparationChoices(mapOf("inverse" to PreparationChoiceAnswer.Counterpart(proposed)))
        choices.require(
            PreparationChoice.Counterpart("inverse", "Choose inverse", source, listOf(choice("newly sampled default"))),
        ) shouldBe
            proposed
    }
}

private val target = TypeDefinitionId.qualified("fixture", "Resource")

/** Collects one operation on any resource as a generated provider would, with the label derived from `ExampleOperation`. */
private fun <I> collect(
    input: OperationInput = OperationInput.None,
    declare: ResourceOperationSpec<I>.() -> PreparedOperation,
): OperationDeclaration =
    collectOperation<ResourceDraft, I>(
        origin = origin(),
        declaration = "fixture.ExampleOperation",
        target = ResourceTarget.AnyResource,
        subjects = AnyResourceSubjects,
        input = input,
        defaultLabel = "Example operation",
    ) { spec -> ResourceOperationSpecImpl(spec).declare() }

private fun bind(declaration: OperationDeclaration): List<ResourceOperationDefinition> {
    val catalog = DefaultCheckedCatalog(CatalogGeneration("test"), emptyList())
    val bound = bindOperations(listOf(declaration), catalog, FactoryNativeBindingRegistry(catalog, emptyList()), emptyList())
    bound.failures shouldBe emptyList()
    return bound.definitions
}

private fun drop(
    input: ValuePath,
    hint: String,
) = OperationDrop(input = SkirAuthoringValueCodec.encode(input).getOrThrow(), hint = hint)

private fun origin(): ProviderOrigin =
    ProviderOrigin(
        DeclarationOwner(
            source = contributionKey(ContributionSourceId("fixture"), "main", ProducerId("ksp"), ContributionName("ops")),
            localIdentity = "fixture.ExampleOperation",
        ),
        ArtifactId("fixture"),
        "main",
    )
