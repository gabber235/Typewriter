package com.typewritermc.operations

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypewriterType

/** One result of an operation candidate search: a candidate resource and its display label. */
@TypewriterType(id = "4e720b9034124ae2a4a63eedfb19218b")
data class OperationResourceOption(
    val id: ResourceId,
    val label: String,
)
