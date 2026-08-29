package com.typewritermc.realm.repository.utils

import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.types.DeclaredTypeId

internal fun pageKindRef(
    id: String,
    revision: Int,
): PageKindRef = PageKindRef(id = PageKindId(value = DeclaredTypeId.parse(id)), revision = revision)
