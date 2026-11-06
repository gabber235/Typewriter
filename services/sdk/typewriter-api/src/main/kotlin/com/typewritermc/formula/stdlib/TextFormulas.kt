package com.typewritermc.formula.stdlib

import com.typewritermc.expression.operations.PortableTextKernel
import com.typewritermc.formula.TypewriterFormulaName
import com.typewritermc.formula.TypewriterFormulaProvider

/**
 * Text functions. Lengths and positions count code points through the portable text kernel, so a creator gets the
 * same answer in formulas and in rules; Kotlin's own members count UTF-16 units, so each function has another Kotlin
 * name.
 */
@TypewriterFormulaProvider
object TextFormulas {
    @TypewriterFormulaName("length")
    val String.codePointLength: Int get() = PortableTextKernel.length(this)

    /** The code points from [start] up to [end]; fails when the range is outside the text. */
    @TypewriterFormulaName("substring")
    fun String.codePointSubstring(
        start: Int,
        end: Int,
    ): String = PortableTextKernel.substring(this, start, end)

    /** The code point position of the first [needle] at or after [from], or -1. */
    @TypewriterFormulaName("indexOf")
    fun String.codePointIndexOf(
        needle: String,
        from: Int = 0,
    ): Int = PortableTextKernel.indexOf(this, needle, from)

    @TypewriterFormulaName("plus")
    fun String.concat(other: String): String = this + other

    @TypewriterFormulaName("lowercase")
    fun String.lower(): String = PortableTextKernel.lower(this)

    @TypewriterFormulaName("uppercase")
    fun String.upper(): String = PortableTextKernel.upper(this)

    @TypewriterFormulaName("compareTo")
    fun String.compare(other: String): Int = compareTo(other)

    /** The text a string template builds: its literal parts and interpolated holes, in order. */
    fun template(parts: List<String>): String = parts.joinToString("")
}
