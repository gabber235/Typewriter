package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.and
import com.typewritermc.expression.call
import com.typewritermc.expression.literal
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.expression.or
import com.typewritermc.expression.parseInteger
import com.typewritermc.expression.shl
import com.typewritermc.expression.shr
import com.typewritermc.expression.substring
import com.typewritermc.expression.unwrap
import com.typewritermc.expression.wrapAs
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.integerScalar
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.TypeUse

/*
 * Color shortcuts. A color is the named type Color over an unsigned 32 bit ARGB word: alpha in bits 24 to 31, then
 * red, green and blue. value.unwrap and value.wrap move between the two; shifts and masks read the channels.
 */

/** The ARGB word of this color. */
@get:JvmName("colorArgb")
val <M : MissingPolicy> Expr<Color, M>.argb: Expr<UInt, M> get() = unwrap()

/** The color of the ARGB word [argb]. */
fun <M : MissingPolicy> colorOf(argb: Expr<UInt, M>): Expr<Color, M> = argb.wrapAs(TypeUse.NamedWrapper(ColorDefinition.use))

/** The alpha channel, 0 (transparent) to 255 (opaque). */
@get:JvmName("colorAlpha")
val <M : MissingPolicy> Expr<Color, M>.alpha: Expr<UInt, M> get() = channel(24)

/** The red channel, 0 to 255. */
@get:JvmName("colorRed")
val <M : MissingPolicy> Expr<Color, M>.red: Expr<UInt, M> get() = channel(16)

/** The green channel, 0 to 255. */
@get:JvmName("colorGreen")
val <M : MissingPolicy> Expr<Color, M>.green: Expr<UInt, M> get() = channel(8)

/** The blue channel, 0 to 255. */
@get:JvmName("colorBlue")
val <M : MissingPolicy> Expr<Color, M>.blue: Expr<UInt, M> get() = channel(0)

private fun <M : MissingPolicy> Expr<Color, M>.channel(shift: Int): Expr<UInt, M> = (argb shr shift) and 0xFFu

/** This color with the alpha channel [alpha]; fails with inexact_conversion when [alpha] is outside 0 to 255. */
fun <M : MissingPolicy> Expr<Color, M>.withAlpha(alpha: Expr<UInt, M>): Expr<Color, M> =
    colorOf((argb and 0x00FFFFFFu) or (alpha.exactByte() shl 24))

/** This color with the alpha channel [alpha], 0 (transparent) to 255 (opaque). */
@JvmName("withAlphaRaw")
fun <M : MissingPolicy> Expr<Color, M>.withAlpha(alpha: Int): Expr<Color, M> {
    require(alpha in 0..255) { "Color alpha must be between 0 and 255." }
    return colorOf((argb and 0x00FFFFFFu) or literal(alpha.toUInt() shl 24).lift())
}

/** The value as an unsigned byte, failing with inexact_conversion outside 0 to 255; still typed as a word for shifts. */
private fun <M : MissingPolicy> Expr<UInt, M>.exactByte(): Expr<UInt, M> =
    call(
        PortableOperationCatalog.NUMBER_CONVERT,
        this,
        typeArguments = listOf(integerScalar(IntegerWidth.UNSIGNED_EIGHT).use.toTemplate()),
    )

/** The opaque color of "#RRGGBB" text with six hexadecimal digits, or null for any other text. */
fun <M : MissingPolicy> Expr<String, M>.toColorOrNull(): Expr<Color?, M> =
    shared(this) { text ->
        choose(
            text.matches("#[0-9A-Fa-f]{6}"),
            colorOf(literal(0xFF000000u).lift<UInt, M>() or text.substring(1, 7).parseInteger(16).asWord()).orNull(),
            nullLiteral(),
        )
    }

/** This color as "#RRGGBB" text with uppercase hexadecimal digits; the alpha channel is not shown. */
fun <M : MissingPolicy> Expr<Color, M>.toHexString(): Expr<String, M> =
    shared(argb) { word ->
        concat(literal("#").lift(), *(20 downTo 0 step 4).map { shift -> hexNibble((word shr shift) and 0xFu) }.toTypedArray())
    }

private fun <M : MissingPolicy> hexNibble(nibble: Expr<UInt, M>): Expr<String, M> =
    shared(nibble.asIndex()) { index -> literal("0123456789ABCDEF").lift<String, M>().substring(index, index + 1) }

/** Reinterprets an integer of another width as a word; integer operations accept every width of the family. */
@Suppress("UNCHECKED_CAST")
private fun <M : MissingPolicy> Expr<Long, M>.asWord(): Expr<UInt, M> = this as Expr<UInt, M>

/** Reinterprets a small word as an int32 index; integer parameters accept every width that holds the value. */
@Suppress("UNCHECKED_CAST")
private fun <M : MissingPolicy> Expr<UInt, M>.asIndex(): Expr<Int, M> = this as Expr<Int, M>
