package com.typewritermc.realm.routes

import com.typewritermc.library.PageKindRef
import skirout.kernel.v1.page_kind.PageKindId as SkirPageKindId
import skirout.kernel.v1.page_kind.PageKindRef as SkirPageKindRef

/** Encodes a library page kind reference using its stable type id and schema revision. */
internal fun PageKindRef.toSkir(): SkirPageKindRef =
    SkirPageKindRef(
        id = SkirPageKindId(value = id.value.toString()),
        revision = revision,
    )
