package com.typewritermc.realm.repository.utils

import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.types.DeclaredTypeId

/**
 * Validates a stored page kind identity and revision through the canonical domain constructors.
 *
 * Malformed hexadecimal identity or nonpositive revision fails at the storage boundary.
 */
internal fun pageKindRef(
    id: String,
    revision: Int,
): PageKindRef = PageKindRef(id = PageKindId(value = DeclaredTypeId.parse(id)), revision = revision)
