package com.typewritermc.types

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Carries either an Iconify identifier or inline SVG source in catalog metadata.
 *
 * [parse] recognizes Iconify syntax and treats other nonblank input as SVG. SVG construction checks only that
 * source is nonblank; rendering boundaries remain responsible for interpreting it safely.
 */
@Serializable
sealed interface Icon {
    val wireValue: String
        get() =
            when (this) {
                is Iconify -> value
                is Svg -> source
            }

    @Serializable
    @SerialName("iconify")
    data class Iconify(
        val value: String,
    ) : Icon {
        init {
            require(ICONIFY_PATTERN.matches(value)) { "Iconify icons must use prefix:name syntax." }
        }
    }

    @Serializable
    @SerialName("svg")
    data class Svg(
        val source: String,
    ) : Icon {
        init {
            require(source.isNotBlank()) { "SVG icons must not be blank." }
        }
    }

    companion object {
        fun parse(value: String): Icon =
            if (ICONIFY_PATTERN.matches(value)) {
                Iconify(value)
            } else {
                Svg(value)
            }
    }
}

/**
 * Stores color as an unsigned ARGB word shared by catalog and transport consumers.
 *
 * [parseRgb] accepts exactly six hexadecimal RGB digits prefixed by # and supplies fully opaque alpha. Direct
 * construction retains the supplied alpha bits.
 */
@JvmInline
@Serializable
value class Color(
    val argb: UInt,
) {
    companion object {
        fun parseRgb(value: String): Color {
            require(RGB_PATTERN.matches(value)) { "Colors must use hexadecimal RGB syntax." }
            return Color(0xFF000000u or value.substring(1).toUInt(16))
        }
    }
}

private val ICONIFY_PATTERN = Regex("[a-z0-9-]+:[a-z0-9-]+")
private val RGB_PATTERN = Regex("#[0-9A-Fa-f]{6}")
