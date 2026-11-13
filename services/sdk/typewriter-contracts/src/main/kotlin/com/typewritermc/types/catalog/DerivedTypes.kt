package com.typewritermc.types.catalog

import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

/*
 * A derived type is computed: extension code runs over a resource's content and produces a type under a key code
 * chooses. Its id, content(resource, derived(key)), never changes, so editing the content changes the type behind it
 * and nothing is written back.
 */

/** Where derived types come from in one view. */
fun interface DerivedOrigin {
    /** What [owner]'s derive blocks compute under [key]. */
    fun derived(
        owner: ResourceId,
        key: String,
    ): DerivedTarget

    companion object {
        /** A view in which no resource derives anything, so every derived id is missing. */
        val NONE: DerivedOrigin = DerivedOrigin { _, _ -> DerivedTarget.Missing(DerivedFailure.NoBlock) }
    }
}

/** What a derived key leads to. */
sealed interface DerivedTarget {
    /** A declaration whose id is the derived id; a union brings its [cases], each a member of that id. */
    data class Declared(
        val definition: TypeDefinition,
        val cases: List<TypeDefinition> = emptyList(),
    ) : DerivedTarget

    /** An alias: the derived id means [use]. */
    data class Plain(
        val use: TypeUse,
    ) : DerivedTarget

    /** Nothing was derived, and [failure] says why. */
    data class Missing(
        val failure: DerivedFailure,
    ) : DerivedTarget
}

/** Why a derived key leads nowhere; each [code] makes the derived type stand in as the error type. */
sealed interface DerivedFailure {
    val code: String

    /** No derive block of the resource computes this key. */
    data object NoBlock : DerivedFailure {
        override val code: String = "derived_type_missing"
    }

    /** More than one derive block computes this key. */
    data class Conflict(
        val origins: List<RuleOrigin>,
    ) : DerivedFailure {
        override val code: String = "derived_type_conflict"
    }

    /** Computing this key needs the key itself, through [through]. */
    data class Loop(
        val through: List<ResourceId>,
    ) : DerivedFailure {
        override val code: String = "derived_type_loop"
    }

    /** The derive block at [origin] threw. */
    data class Failed(
        val origin: RuleOrigin,
        val message: String,
    ) : DerivedFailure {
        override val code: String = "derived_type_failed"
    }
}
