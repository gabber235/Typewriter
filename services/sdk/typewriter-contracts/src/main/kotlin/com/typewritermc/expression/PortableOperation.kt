package com.typewritermc.expression

import com.typewritermc.presentation.OperationDescriptor
import com.typewritermc.types.catalog.Resolution

interface PortableOperation {
    val id: OperationId

    fun resolve(inputs: List<ExpressionType>): Resolution<OperationDescriptor>
}
