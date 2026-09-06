package com.typewritermc.realm.routes

import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.types.DeclaredTypeId
import skirout.kernel.v1.page_kind.PageKindId as SkirPageKindId
import skirout.kernel.v1.page_kind.PageKindRef as SkirPageKindRef

internal fun PageKindRef.toSkir(): SkirPageKindRef =
    SkirPageKindRef(
        id = SkirPageKindId(value = id.value.toString()),
        revision = revision,
    )

/**
 * Reconstructs a validated page kind from wire identity and revision.
 *
 * The canonical constructors reject malformed ids and nonpositive revisions; no schema migration occurs here.
 */
internal fun SkirPageKindRef.toLibrary(): PageKindRef =
    PageKindRef(
        id = PageKindId(DeclaredTypeId.parse(id.value)),
        revision = revision,
    )
