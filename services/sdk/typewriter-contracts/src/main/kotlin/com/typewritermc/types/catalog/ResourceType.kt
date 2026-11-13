package com.typewritermc.types.catalog

import com.typewritermc.types.named
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.ResolvedField
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

/** The complete type the creator's choices in [selection] make, or null while one is missing or it does not resolve. */
fun CheckedCatalog.completeAuthoredTypeOf(selection: TypeSelection): CheckedType? =
    ((authoredTypeOf(selection) as? Resolution.Ready)?.value as? ResourceType.Complete)?.checked
