package com.typewritermc.expression.operations

import java.math.BigDecimal

/** Realm's kernel of the decimal operations. */
internal object PortableDecimalKernel : DecimalKernel {
    /** The fraction digits of the canonical text, so trailing zeros never count. */
    override fun scale(value: BigDecimal): Int = value.canonicalDecimal().substringAfter('.', "").length
}
