package com.typewritermc.types.catalog

import com.typewritermc.types.named
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.ResourceMatch
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

/**
 * What a resource's configured type means in one catalog ([CheckedCatalog.typeOf]). Readers ask for this answer and
 * never read the stored selection: the selection holds only what a creator chose, and whether that makes a complete
 * type is the catalog's call.
 */
sealed interface ResourceType {
    /** The definition the resource is an instance of. */
    val definition: TypeDefinitionId

    /** The fields whose type is known: every field of a complete type, the independent ones of a partial type. */
    val knownFields: List<ResolvedField>

    /** Every parameter has an argument, so the type resolves like any other use. */
    data class Complete(
        val checked: CheckedType,
    ) : ResourceType {
        override val definition: TypeDefinitionId
            get() = checkNotNull(checked.use.named) { "A resource's complete type is a named use." }.definition

        override val knownFields: List<ResolvedField> get() = checked.schema.fields
    }

    /** A creator has not chosen an argument yet; [schema] holds the fields that need none and the ones that wait. */
    data class Partial(
        override val definition: TypeDefinitionId,
        val schema: PartialSchema,
    ) : ResourceType {
        override val knownFields: List<ResolvedField> get() = schema.knownFields
    }
}

/** [owner]'s complete type, or null while it is partial or does not resolve. */
fun CheckedCatalog.completeTypeOf(
    owner: ResourceId,
    selection: TypeSelection,
): CheckedType? = ((typeOf(owner, selection) as? Resolution.Ready)?.value as? ResourceType.Complete)?.checked

/**
 * Whether the creator's choices in [selection] read as [expected]: a complete type by readability, a partial one by the
 * applications it already fixes. Which resources a slot accepts asks this, never what they hold.
 */
fun CheckedCatalog.isSelectionReadableAs(
    selection: TypeSelection,
    expected: TypeUse,
): Boolean =
    when (val type = (authoredTypeOf(selection) as? Resolution.Ready)?.value) {
        null -> false
        is ResourceType.Complete -> isReadableAs(type.checked.use, expected)
        is ResourceType.Partial -> knownApplications(selection).any { isReadableAs(it.use, expected) }
    }

/** Whether a resource fits a [ResourceMatch]: yes, no, or not until a creator chooses more arguments. */
enum class Fit { YES, NO, UNDECIDED }

/**
 * Whether a resource configured by [selection] fits [match]; every place that names resources asks this. With an [owner],
 * a type reads what that resource's binds compute; without one, only the creator's choices, as a bind's own reads must.
 * A definition reads only the configured definition, so it fits before any argument is known; a type the choices do not
 * fix yet is [Fit.UNDECIDED] while the definition could still become it.
 */
fun CheckedCatalog.fits(
    selection: TypeSelection,
    match: ResourceMatch,
    owner: ResourceId?,
): Fit =
    when (match) {
        ResourceMatch.ANY_RESOURCE -> {
            Fit.YES
        }

        is ResourceMatch.DefinitionWrapper -> {
            isNominalSubtype(selection.definition, match.value).asFit()
        }

        is ResourceMatch.TypeWrapper -> {
            val expected = TypeUse.NamedWrapper(match.value)
            val resolved = if (owner == null) authoredTypeOf(selection) else typeOf(owner, selection)
            when (val type = (resolved as? Resolution.Ready)?.value) {
                null -> {
                    Fit.NO
                }

                is ResourceType.Complete -> {
                    isReadableAs(type.checked.use, expected).asFit()
                }

                is ResourceType.Partial -> {
                    when {
                        knownApplications(selection).any { isReadableAs(it.use, expected) } -> Fit.YES
                        isNominalSubtype(type.definition, match.value.definition) -> Fit.UNDECIDED
                        else -> Fit.NO
                    }
                }
            }
        }

        else -> {
            throw IllegalArgumentException("Unknown resource match.")
        }
    }

private fun Boolean.asFit(): Fit = if (this) Fit.YES else Fit.NO
