package com.typewritermc.presentation

/** Finite, nonnegative logical pixels between or around presentation content. */
@JvmInline
value class Spacing(
    val pixels: Double,
) {
    init {
        require(pixels.isFinite() && pixels >= 0) { "Spacing must be finite and nonnegative." }
    }

    companion object {
        val NONE: Spacing = Spacing(0.0)
    }
}

/** A CSS style font weight, 1 to 1000; 400 is regular and 700 bold. */
@JvmInline
value class FontWeight(
    val value: Int,
) {
    init {
        require(value in 1..1000) { "Font weight must be between 1 and 1000." }
    }
}

/** A nonnegative delay or transition length in milliseconds. */
@JvmInline
value class DisplayDelay(
    val milliseconds: Int,
) {
    init {
        require(milliseconds >= 0) { "Display delays must be nonnegative." }
    }
}
