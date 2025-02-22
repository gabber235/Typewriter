package com.typewritermc.engine.paper.utils

class Color(
    val color: Int,
) {
    companion object {
        fun fromHex(hex: String): Color {
            val color = hex.removePrefix("#").toLong(16).toInt()
            return Color(color)
        }

        val BLACK_BACKGROUND = Color(0x40000000)
        val WHITE = Color(0xFFFFFFFF.toInt())
    }

    val alpha: Int get() = (color shr 24) and 0xFF
    val red: Int get() = (color shr 16) and 0xFF
    val green: Int get() = (color shr 8) and 0xFF
    val blue: Int get() = color and 0xFF

    fun toBukkitColor(): org.bukkit.Color {
        return org.bukkit.Color.fromARGB(alpha, red, green, blue)
    }
}