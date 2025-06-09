package com.typewritermc.engine.paper.utils

import com.destroystokyo.paper.profile.PlayerProfile
import com.typewritermc.engine.paper.logger
import net.kyori.adventure.audience.Audience
import net.kyori.adventure.key.Key
import net.kyori.adventure.sound.Sound
import net.kyori.adventure.text.Component
import org.bukkit.Color
import org.bukkit.GameMode
import org.bukkit.Location
import org.bukkit.enchantments.Enchantment
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemFlag
import org.bukkit.inventory.meta.ItemMeta
import org.bukkit.inventory.meta.SkullMeta
import org.bukkit.profile.PlayerTextures
import java.io.File
import java.net.MalformedURLException
import java.net.URI
import java.time.Duration
import java.util.*
import kotlin.math.abs
import kotlin.math.log10
import kotlin.math.round
import kotlin.math.roundToLong


operator fun File.get(name: String): File = File(this, name)

/**
 * Can an entity look at this player?
 */
val Player.isLookable: Boolean
    get() = this.isValid && this.gameMode != GameMode.SPECTATOR && !this.isInvisible

fun <T> T?.logErrorIfNull(message: String): T? {
    if (this == null) logger.severe(message)
    return this
}

infix fun <T> Boolean.then(t: T): T? = if (this) t else null


fun Duration.toTicks(): Long = this.toMillis() / TICK_MS
operator fun Duration.times(other: Double): Duration = Duration.ofMillis((this.toMillis() * other).roundToLong())

fun Audience.playSound(
    sound: String,
    source: Sound.Source = Sound.Source.MASTER,
    volume: Float = 1.0f,
    pitch: Float = 1.0f
) = playSound(Sound.sound(Key.key(sound), source, volume, pitch))


fun Location.distanceSqrt(other: Location): Double? {
    if (world != other.world) return null
    val dx = x - other.x
    val dy = y - other.y
    val dz = z - other.z
    return dx * dx + dy * dy + dz * dz
}

val Location.up: Location
    get() = clone().apply { y += 1 }

operator fun Location.component1(): Double = x
operator fun Location.component2(): Double = y
operator fun Location.component3(): Double = z


fun Color.toPacketColor(): com.github.retrooper.packetevents.protocol.color.Color {
    return com.github.retrooper.packetevents.protocol.color.Color(red, green, blue)
}

fun Double.round(decimals: Int): Double {
    var multiplier = 1.0
    repeat(decimals) { multiplier *= 10 }

    return round(this * multiplier) / multiplier
}

fun Float.round(decimals: Int): Float {
    var multiplier = 1.0
    repeat(decimals) { multiplier *= 10 }

    return (round(this * multiplier) / multiplier).toFloat()
}

val Int.digits: Int
    get() = if (this == 0) 1 else log10(abs(this.toDouble())).toInt() + 1


val String.lineCount: Int
    get() = this.count { it == '\n' } + 1

val <T : Any> Optional<T>?.optional: Optional<T> get() = Optional.ofNullable(this?.orElse(null))
val <T : Any> T?.optional: Optional<T> get() = Optional.ofNullable(this)

var ItemMeta.loreString: String?
    get() = lore()?.joinToString("\n") { it.asMini() }
    set(value) {
        lore(value?.split("\n")?.map { "<!i><white>$it".asMini() })
    }

var ItemMeta.name: String?
    get() = if (hasDisplayName()) displayName()?.asMini() else null
    set(value) = displayName(if (!value.isNullOrEmpty()) "<!i>$value".asMini() else Component.text(" "))

fun ItemMeta.unClickable(): ItemMeta {
    addEnchant(Enchantment.BINDING_CURSE, 1, true)
    addItemFlags(ItemFlag.HIDE_ENCHANTS)
    return this
}

private val RANDOM_UUID =
    UUID.fromString("92864445-51c5-4c3b-9039-517c9927d1b4") // We reuse the same "random" UUID all the time

private fun getProfile(url: String): PlayerProfile {
    val profile: PlayerProfile = server.createProfile(RANDOM_UUID) // Get a new player profile
    val textures: PlayerTextures = profile.textures
    textures.skin = try {
        // The URL to the skin, for example: https://textures.minecraft.net/texture/18813764b2abc94ec3c3bc67b9147c21be850cdf996679703157f4555997ea63a
        URI(url).toURL()
    } catch (exception: MalformedURLException) {
        throw RuntimeException("Invalid URL", exception)
    }
    profile.setTextures(textures) // Set the textures back to the profile
    return profile
}

fun SkullMeta.applySkinUrl(url: String) {
    playerProfile = getProfile(url)
}

/**
 * Extension function for String to parse it flexibly as a Double.
 *
 * Handles:
 * - US-style: #,###.##
 * - DE-style: #.###,##
 * - Standard decimal: ###.##
 * - Scientific notation: ###.##e## or ###.##E##
 * - Integers: ######
 * - Leading/trailing whitespace.
 * - Optional leading +/- sign.
 *
 * It works by normalizing the input string to a standard format
 * (using '.' as decimal separator, no thousands separators)
 * and then using Kotlin's built-in `toDoubleOrNull()`.
 *
 * @return The parsed Double, or null if parsing fails or the format is
 *   unresolvable.
 */
fun String.parseDoubleFlexible(): Double? {
    val cleaned = this.trim()
    if (cleaned.isEmpty()) {
        return null
    }

    // Shortcut: If it already parses directly, return immediately.
    cleaned.toDoubleOrNull()?.let { return it }

    // If direct parsing failed, proceed with normalization.
    val hasDot = cleaned.contains('.')
    val hasComma = cleaned.contains(',')

    if (!hasComma && cleaned.count { it == '.' } <= 1) {
        // If no commas and at most one dot, direct parse should have worked, meaning it is invalid.
        return null
    }

    val normalized: String = when {
        hasDot && hasComma -> {
            val lastDotIndex = cleaned.lastIndexOf('.')
            val lastCommaIndex = cleaned.lastIndexOf(',')
            if (lastDotIndex > lastCommaIndex) { // US style: 1,234.56
                cleaned.replace(",", "")
            } else { // DE style: 1.234,56
                cleaned.replace(".", "").replace(',', '.')
            }
        }

        hasComma -> {
            if (cleaned.count { it == ',' } > 1) { // Thousands: 1,234,567
                cleaned.replace(",", "")
            } else { // Decimal: 123,45
                cleaned.replace(',', '.')
            }
        }

        hasDot -> { // Only dots (and direct parse failed -> multiple dots)
            // Thousands: 1.234.567
            cleaned.replace(".", "")
        }

        else -> {
            return null // Should have been caught earlier
        }
    }

    return normalized.toDoubleOrNull()
}
