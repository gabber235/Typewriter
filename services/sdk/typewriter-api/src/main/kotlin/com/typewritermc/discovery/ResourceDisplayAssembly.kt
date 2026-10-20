@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.CheckedResourceDisplay
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.ResourceDisplaySubject
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.expression.CheckedExpressionProgram
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.children
import com.typewritermc.expression.nominalExpressionType
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.IconDefinition
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationOrigin
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isReady
import com.typewritermc.types.immutableCopy
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionQuery

/** The displays a catalog publishes and the diagnostics of the ones it rejected. */
internal class ResourceDisplayCollection(
    val displays: List<CheckedResourceDisplay>,
    val diagnostics: List<DeclarationDiagnostic>,
    val callbackFailures: List<CatalogCallbackFailure>,
)

/**
 * Builds, checks and publishes the declared resource displays.
 *
 * Each formula may read only the subject through [ResourceDisplaySubject.binding]: another input, such as a host
 * context value, or a read of another resource is rejected (`display_reads_context`), so editors can name a
 * resource from its own record. Formulas are checked against every subject the target covers: the target
 * type, or every resource type for the any resource display (`invalid_resource_display`). Two displays for one
 * target are ambiguous, so neither is published (`duplicate_resource_display`). Rejections are published as
 * diagnostics without quarantining the target, whose resources fall back to a less specific display.
 */
internal fun collectResourceDisplays(
    displays: List<OwnedResourceDisplay>,
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    resourceTypes: List<TypeDefinitionId>,
    checked: CheckedCatalog,
): ResourceDisplayCollection {
    val diagnostics = mutableListOf<DeclarationDiagnostic>()
    val callbackFailures = mutableListOf<CatalogCallbackFailure>()
    val compiled =
        displays.mapNotNull { owned ->
            val target = owned.provider.target
            val affected = target.affected
            if (target is ResourceTarget.Type && !checked.isReady(target.template.definition)) return@mapNotNull null
            val origins = listOf(DeclarationOrigin(owned.origin.owner))
            val formulas =
                try {
                    owned.provider.formulas().let { Triple(it.label.toNode(), it.accent.toNode(), it.icon.toNode()) }
                } catch (cancellation: CancellationException) {
                    throw cancellation
                } catch (cause: Exception) {
                    callbackFailures += CatalogCallbackFailure(owned.origin, CatalogCallback.Display(target), cause)
                    diagnostics += DeclarationDiagnostic(affected, "resource_display_build_failed", origins)
                    return@mapNotNull null
                }
            val (label, accent, icon) = formulas
            if (listOf(label, accent, icon).any { it.readsContext() }) {
                diagnostics += DeclarationDiagnostic(affected, "display_reads_context", origins)
                return@mapNotNull null
            }
            val subjects =
                when (target) {
                    is ResourceTarget.Type -> listOf(target.template.definition)
                    ResourceTarget.AnyResource -> resourceTypes
                }.mapNotNull { definitions[it] }
                    .filter { checked.isReady(it.id) }
            val checker = PortableExpressionChecker(checked::resolve)
            val programs =
                listOf(label to TEXT, accent to ColorDefinition.use, icon to IconDefinition.use).map { (node, expected) ->
                    checker.checkAgainst(node, expected, subjects, affected)
                }
            if (programs.any { it == null }) {
                diagnostics += DeclarationDiagnostic(affected, "invalid_resource_display", origins)
                return@mapNotNull null
            }
            owned to CheckedResourceDisplay(target.immutableCopy(), programs[0]!!, programs[1]!!, programs[2]!!)
        }
    val published =
        compiled.groupBy { (_, display) -> display.target }.flatMap { (target, declared) ->
            if (declared.size == 1) {
                listOf(declared.single().second)
            } else {
                diagnostics +=
                    DeclarationDiagnostic(
                        target.affected,
                        "duplicate_resource_display",
                        declared.map { (owned, _) -> DeclarationOrigin(owned.origin.owner) },
                    )
                emptyList()
            }
        }
    return ResourceDisplayCollection(published, diagnostics, callbackFailures)
}

/**
 * The checked program of [node] for one result type, or null when it fails for one of [subjects]. A subject that
 * still has free type parameters is checked structurally only, as generic presentation material is. The program
 * is independent of the subject: its queries read the subject's type and other resources, never subject fields.
 */
private fun PortableExpressionChecker.checkAgainst(
    node: ExpressionNode,
    expected: TypeUse,
    subjects: List<TypeDefinition>,
    affected: TypeDefinitionId,
): CheckedExpressionProgram? {
    if (checkExpressionStructure(node, setOf(ResourceDisplaySubject.binding)).isNotEmpty()) return null
    val output = nominalExpressionType(expected, mayBeMissing = true)
    var program: CheckedExpressionProgram? = null
    for (subject in subjects) {
        if (subject.parameters.isNotEmpty()) continue
        val binding = mapOf(ResourceDisplaySubject.binding to nominalExpressionType(TypeUse.Named(subject.id), mayBeMissing = true))
        when (val result = checkProgram(node, binding, output, affected)) {
            is Resolution.Ready -> program = program ?: result.value
            is Resolution.Invalid -> return null
        }
    }
    return program ?: CheckedExpressionProgram(node, output, emptyMap())
}

/**
 * Whether this formula reads anything but its subject: an input other than the subject, such as a host context
 * value, or another resource. Reading the subject's type from the catalog stays allowed.
 */
private fun ExpressionNode.readsContext(): Boolean =
    (this is ExpressionNode.InputWrapper && value.binding.value != ResourceDisplaySubject.binding.value) ||
        (this is ExpressionNode.QueryWrapper && value.readsResource) ||
        children().any { it.node.readsContext() }

private val ExpressionQuery.readsResource: Boolean
    get() =
        this is ExpressionQuery.ResourceIdentityWrapper ||
            this is ExpressionQuery.ResourceValueWrapper ||
            this is ExpressionQuery.ResourceConfigurationWrapper

/** The type a display diagnostic is reported on; the any resource display reports on the unpublished Resource. */
private val ResourceTarget.affected: TypeDefinitionId
    get() =
        when (this) {
            is ResourceTarget.Type -> template.definition
            ResourceTarget.AnyResource -> ANY_RESOURCE
        }

private val ANY_RESOURCE = TypeDefinitionId(TypeId.Qualified("kotlin", "com.typewritermc.types.Resource"), 1)

private val TEXT = TypeUse.Scalar(ScalarKind.Text)

internal fun ResourceTarget.immutableCopy(): ResourceTarget =
    when (this) {
        is ResourceTarget.Type -> ResourceTarget.Type(template.immutableCopy() as TypeTemplate.Named)
        ResourceTarget.AnyResource -> this
    }
