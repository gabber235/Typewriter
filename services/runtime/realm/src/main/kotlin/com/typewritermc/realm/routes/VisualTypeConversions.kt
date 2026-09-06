package com.typewritermc.realm.routes

import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import skirout.kernel.v1.color.Color as SkirColor
import skirout.kernel.v1.icon.Icon as SkirIcon

/**
 * Transfers ARGB bits through the signed wire integer without changing their color meaning.
 *
 * The inverse restores the unsigned representation; a negative signed value can still represent a valid opaque
 * color.
 */
internal fun Color.toSkir(): SkirColor = SkirColor(argb = argb.toInt())

internal fun SkirColor.toLibrary(): Color = Color(argb = argb.toUInt())

internal fun Icon.toSkir(): SkirIcon =
    when (this) {
        is Icon.Iconify -> SkirIcon.IconifyWrapper(value)
        is Icon.Svg -> SkirIcon.SvgWrapper(source)
    }
