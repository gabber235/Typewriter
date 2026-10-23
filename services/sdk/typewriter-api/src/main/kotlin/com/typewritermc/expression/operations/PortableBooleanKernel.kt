package com.typewritermc.expression.operations

/** Realm's kernel of the boolean operations. */
internal object PortableBooleanKernel : BooleanKernel {
    override fun not(value: Boolean): Boolean = !value
}
