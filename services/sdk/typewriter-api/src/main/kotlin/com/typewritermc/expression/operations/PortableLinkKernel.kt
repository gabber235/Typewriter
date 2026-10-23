package com.typewritermc.expression.operations

import skirout.editor.v1.type_catalog.LinkValue
import skirout.editor.v1.type_catalog.ResourceId

/** Realm's kernel of the link operations. */
internal object PortableLinkKernel : LinkKernel {
    override fun target(reference: LinkValue): ResourceId = reference.target.resource
}
