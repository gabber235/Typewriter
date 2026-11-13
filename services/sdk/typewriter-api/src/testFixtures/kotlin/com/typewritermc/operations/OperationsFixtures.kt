@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.operations

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.typedPath
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.assemble
import com.typewritermc.library.frameworkContributions
import com.typewritermc.testkit.origin
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.field
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.operation.OperationCardinality
import skirout.editor.v1.operation.OperationDrop
import skirout.editor.v1.operation.OperationGroup
import skirout.editor.v1.operation.OperationShortcut
import skirout.editor.v1.operation.ResourceOperationDefinition
import skirout.editor.v1.presentation.HeaderActionTone
import skirout.editor.v1.resource_operations.PreparationChoice
import skirout.editor.v1.resource_operations.PreparationChoiceAnswer
import skirout.editor.v1.resource_operations.PreparationChoiceId
import skirout.editor.v1.resource_operations.PreparationCounterpartOption
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

internal val target = TypeDefinitionId.qualified("fixture", "Resource")

/** Collects one operation on any resource as a generated provider would, with the label derived from `ExampleOperation`. */
internal fun <I> collect(
    input: OperationInput = OperationInput.None,
    declare: ResourceOperationSpec<I>.() -> PreparedOperation,
): OperationDeclaration =
    collectOperation<ResourceDraft, I>(
        origin = origin("fixture.ExampleOperation", artifact = "fixture"),
        declaration = "fixture.ExampleOperation",
        target = ResourceTarget.ANY_RESOURCE,
        subjects = AnyResourceSubjects,
        input = input,
        defaultLabel = "Example operation",
    ) { spec -> ResourceOperationSpecImpl(spec).declare() }

internal fun bind(declaration: OperationDeclaration): List<ResourceOperationDefinition> {
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "test"), emptyList())
    val bound = bindOperations(listOf(declaration), catalog, FactoryNativeBindingRegistry(catalog, emptyList()), emptyList())
    bound.failures shouldBe emptyList()
    return bound.definitions
}

internal fun drop(
    input: ValuePath,
    hint: String,
) = OperationDrop(input = input, hint = hint)
