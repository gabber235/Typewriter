package com.typewritermc.entity.entries.entity.custom

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityType
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.engine.paper.entry.entity.EntityState
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.entity.entries.data.minecraft.BoxSizeProperty
import com.typewritermc.entity.entries.data.minecraft.PoseProperty
import com.typewritermc.entity.entries.data.minecraft.SpeedProperty
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.ScaleProperty
import com.typewritermc.entity.entries.data.minecraft.living.SizeProperty
import com.typewritermc.entity.entries.data.minecraft.living.SleepingProperty
import com.typewritermc.entity.entries.data.minecraft.living.pufferfish.PuffStateProperty
import com.typewritermc.entity.entries.data.minecraft.living.tameable.SittingProperty
import com.typewritermc.entity.entries.data.minecraft.other.MarkerProperty
import com.typewritermc.entity.entries.data.minecraft.other.SmallProperty
import me.tofaa.entitylib.meta.mobs.water.PufferFishMeta
import java.util.*
import kotlin.reflect.KClass
import kotlin.reflect.full.safeCast

fun <T : EntityProperty> Map<KClass<*>, EntityProperty>.property(type: KClass<T>): T? {
    return type.safeCast(this[type])
}

private class EntityDataMatcher(
    val type: EntityType,
    val isBaby: Boolean? = null,
    val pose: EntityPose? = null,
    val size: Int? = null,
    val small: Boolean? = null,
    val marker: Boolean? = null,
    val puffState: PufferFishMeta.State? = null,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as EntityDataMatcher

        if (type != other.type) return false
        if (other.isBaby != null && isBaby != other.isBaby) return false
        if (other.pose != null && pose != other.pose) return false
        if (other.size != null && size != null && size > other.size) return false
        if (other.small != null && small != other.small) return false
        if (other.marker != null && marker != other.marker) return false
        if (other.puffState != null && puffState != other.puffState) return false

        return true
    }

    override fun hashCode(): Int = Objects.hash(type, isBaby, pose, size, small, marker, puffState)

    override fun toString(): String {
        return "EntityDataMatcher(type=${type.name}, isBaby=$isBaby, pose=$pose, size=$size, small=$small, marker=$marker, puffState=$puffState)"
    }
}

private data class EntityData(
    val width: Double,
    val height: Double,
    val eyeHeight: Double = height * 0.85
)

private val generatedEntityDataMap = mapOf(
//<editor-fold desc="Entity Data Map Entries">
    EntityDataMatcher(EntityTypes.ALLAY) to EntityData(width = 0.35, height = 0.6, eyeHeight = 0.36),
    EntityDataMatcher(EntityTypes.AREA_EFFECT_CLOUD) to EntityData(width = 6.0, height = 0.5),
    EntityDataMatcher(EntityTypes.ARMADILLO, isBaby = false) to EntityData(
        width = 0.7,
        height = 0.65,
        eyeHeight = 0.26
    ),
    EntityDataMatcher(EntityTypes.ARMADILLO, isBaby = true) to EntityData(
        width = 0.42,
        height = 0.39,
        eyeHeight = 0.156
    ),
    EntityDataMatcher(EntityTypes.ARMOR_STAND, small = false, marker = false) to EntityData(
        width = 0.5,
        height = 1.975,
        eyeHeight = 1.7775
    ),
    EntityDataMatcher(EntityTypes.ARMOR_STAND, small = true, marker = false) to EntityData(
        width = 0.25,
        height = 0.9875,
        eyeHeight = 0.49375
    ),
    EntityDataMatcher(EntityTypes.ARMOR_STAND, small = false, marker = true) to EntityData(
        width = 0.0,
        height = 0.0,
        eyeHeight = 1.7775
    ),
    EntityDataMatcher(EntityTypes.ARMOR_STAND, small = true, marker = true) to EntityData(
        width = 0.0,
        height = 0.0,
        eyeHeight = 0.49375
    ),
    EntityDataMatcher(EntityTypes.ARROW) to EntityData(width = 0.5, height = 0.5, eyeHeight = 0.13),
    EntityDataMatcher(EntityTypes.AXOLOTL, isBaby = true) to EntityData(
        width = 0.375,
        height = 0.21,
        eyeHeight = 0.137549
    ),
    EntityDataMatcher(EntityTypes.AXOLOTL, isBaby = false) to EntityData(
        width = 0.75,
        height = 0.42,
        eyeHeight = 0.2751
    ),
    EntityDataMatcher(EntityTypes.BAT) to EntityData(width = 0.5, height = 0.9, eyeHeight = 0.45),
    EntityDataMatcher(EntityTypes.BEE, isBaby = true) to EntityData(width = 0.35, height = 0.3, eyeHeight = 0.15),
    EntityDataMatcher(EntityTypes.BEE, isBaby = false) to EntityData(width = 0.7, height = 0.6, eyeHeight = 0.3),
    EntityDataMatcher(EntityTypes.BLAZE) to EntityData(width = 0.6, height = 1.8),
    EntityDataMatcher(EntityTypes.BLOCK_DISPLAY) to EntityData(width = 0.0, height = 0.0),
    EntityDataMatcher(EntityTypes.BOAT) to EntityData(width = 1.375, height = 0.5625, eyeHeight = 0.5625),
    EntityDataMatcher(EntityTypes.CHEST_BOAT) to EntityData(width = 1.375, height = 0.5625, eyeHeight = 0.5625),
    EntityDataMatcher(EntityTypes.BOGGED) to EntityData(width = 0.6, height = 1.99, eyeHeight = 1.74),
    EntityDataMatcher(EntityTypes.BREEZE) to EntityData(width = 0.6, height = 1.77, eyeHeight = 1.3452),
    EntityDataMatcher(EntityTypes.CAMEL, isBaby = false, pose = EntityPose.STANDING) to EntityData(
        width = 1.7,
        height = 2.375,
        eyeHeight = 2.275
    ),
    EntityDataMatcher(EntityTypes.CAMEL, isBaby = true, pose = EntityPose.SITTING) to EntityData(
        width = 0.765,
        height = 0.42525,
        eyeHeight = 0.38025
    ),
    EntityDataMatcher(EntityTypes.CAMEL, isBaby = true) to EntityData(
        width = 0.765,
        height = 1.06875,
        eyeHeight = 1.02375
    ),
    EntityDataMatcher(EntityTypes.CAMEL, isBaby = false, pose = EntityPose.SITTING) to EntityData(
        width = 1.7,
        height = 0.945,
        eyeHeight = 0.845
    ),
    EntityDataMatcher(EntityTypes.CAMEL, isBaby = false) to EntityData(width = 1.7, height = 0.945, eyeHeight = 2.275),
    EntityDataMatcher(EntityTypes.CAMEL, isBaby = true, pose = EntityPose.STANDING) to EntityData(
        width = 0.765,
        height = 1.06875,
        eyeHeight = 1.02375
    ),
    EntityDataMatcher(EntityTypes.CAT, isBaby = true) to EntityData(width = 0.3, height = 0.35, eyeHeight = 0.175),
    EntityDataMatcher(EntityTypes.CAT, isBaby = false) to EntityData(width = 0.6, height = 0.7, eyeHeight = 0.35),
    EntityDataMatcher(EntityTypes.CAVE_SPIDER) to EntityData(width = 0.699999, height = 0.5, eyeHeight = 0.45),
    EntityDataMatcher(EntityTypes.CHICKEN, isBaby = false) to EntityData(width = 0.4, height = 0.7, eyeHeight = 0.644),
    EntityDataMatcher(EntityTypes.CHICKEN, isBaby = true) to EntityData(width = 0.2, height = 0.35),
    EntityDataMatcher(EntityTypes.COD) to EntityData(width = 0.5, height = 0.3, eyeHeight = 0.195),
    EntityDataMatcher(EntityTypes.COW, isBaby = true) to EntityData(width = 0.45, height = 0.7, eyeHeight = 0.665),
    EntityDataMatcher(EntityTypes.COW, isBaby = false) to EntityData(width = 0.9, height = 1.4, eyeHeight = 1.3),
    EntityDataMatcher(EntityTypes.CREEPER) to EntityData(width = 0.6, height = 1.7),
    EntityDataMatcher(EntityTypes.DOLPHIN) to EntityData(width = 0.9, height = 0.6, eyeHeight = 0.3),
    EntityDataMatcher(EntityTypes.DONKEY, isBaby = false) to EntityData(
        width = 1.396484,
        height = 1.5,
        eyeHeight = 1.425
    ),
    EntityDataMatcher(EntityTypes.DONKEY, isBaby = true) to EntityData(
        width = 0.698242,
        height = 0.75,
        eyeHeight = 0.7125
    ),
    EntityDataMatcher(EntityTypes.DRAGON_FIREBALL) to EntityData(width = 1.0, height = 1.0),
    EntityDataMatcher(EntityTypes.DROWNED, isBaby = false) to EntityData(width = 0.6, height = 1.95, eyeHeight = 1.74),
    EntityDataMatcher(EntityTypes.DROWNED, isBaby = true) to EntityData(width = 0.3, height = 0.975, eyeHeight = 0.93),
    EntityDataMatcher(EntityTypes.ELDER_GUARDIAN) to EntityData(width = 1.9975, height = 1.9975, eyeHeight = 0.998749),
    EntityDataMatcher(EntityTypes.END_CRYSTAL) to EntityData(width = 2.0, height = 2.0),
    EntityDataMatcher(EntityTypes.ENDER_DRAGON) to EntityData(width = 16.0, height = 8.0),
    EntityDataMatcher(EntityTypes.ENDERMAN) to EntityData(width = 0.6, height = 2.9, eyeHeight = 2.55),
    EntityDataMatcher(EntityTypes.ENDERMITE) to EntityData(width = 0.4, height = 0.3, eyeHeight = 0.13),
    EntityDataMatcher(EntityTypes.EVOKER) to EntityData(width = 0.6, height = 1.95),
    EntityDataMatcher(EntityTypes.EVOKER_FANGS) to EntityData(width = 0.5, height = 0.8),
    EntityDataMatcher(EntityTypes.EXPERIENCE_ORB) to EntityData(width = 0.5, height = 0.5),
    EntityDataMatcher(EntityTypes.EYE_OF_ENDER) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.FALLING_BLOCK) to EntityData(width = 0.98, height = 0.98),
    EntityDataMatcher(EntityTypes.FIREBALL) to EntityData(width = 1.0, height = 1.0),
    EntityDataMatcher(EntityTypes.FIREWORK_ROCKET) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.FISHING_BOBBER) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.FOX, isBaby = false) to EntityData(width = 0.6, height = 0.7, eyeHeight = 0.4),
    EntityDataMatcher(EntityTypes.FOX, isBaby = true) to EntityData(width = 0.3, height = 0.35),
    EntityDataMatcher(EntityTypes.FROG) to EntityData(width = 0.5, height = 0.5),
    EntityDataMatcher(EntityTypes.GHAST) to EntityData(width = 4.0, height = 4.0, eyeHeight = 2.6),
    EntityDataMatcher(EntityTypes.GIANT) to EntityData(width = 3.6, height = 12.0, eyeHeight = 10.44),
    EntityDataMatcher(EntityTypes.GLOW_ITEM_FRAME) to EntityData(width = 0.5, height = 0.5, eyeHeight = 0.0),
    EntityDataMatcher(EntityTypes.GLOW_SQUID) to EntityData(width = 0.8, height = 0.8, eyeHeight = 0.4),
    EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.LONG_JUMPING, isBaby = true) to EntityData(
        width = 0.315,
        height = 0.455
    ),
    EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.LONG_JUMPING, isBaby = false) to EntityData(
        width = 0.63,
        height = 0.91
    ),
    EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.STANDING, isBaby = true) to EntityData(
        width = 0.45,
        height = 0.65
    ),
    EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.STANDING, isBaby = false) to EntityData(
        width = 0.9,
        height = 1.3
    ),
    EntityDataMatcher(EntityTypes.GUARDIAN) to EntityData(width = 0.85, height = 0.85, eyeHeight = 0.425),
    EntityDataMatcher(EntityTypes.HOGLIN, isBaby = false) to EntityData(width = 1.396484, height = 1.4),
    EntityDataMatcher(EntityTypes.HOGLIN, isBaby = true) to EntityData(width = 0.698242, height = 0.7),
    EntityDataMatcher(EntityTypes.HORSE, isBaby = true) to EntityData(width = 0.698242, height = 0.8, eyeHeight = 0.76),
    EntityDataMatcher(EntityTypes.HORSE, isBaby = false) to EntityData(
        width = 1.396484,
        height = 1.6,
        eyeHeight = 1.52
    ),
    EntityDataMatcher(EntityTypes.HUSK, isBaby = true) to EntityData(width = 0.3, height = 0.975, eyeHeight = 0.93),
    EntityDataMatcher(EntityTypes.HUSK, isBaby = false) to EntityData(width = 0.6, height = 1.95, eyeHeight = 1.74),
    EntityDataMatcher(EntityTypes.ILLUSIONER) to EntityData(width = 0.6, height = 1.95),
    EntityDataMatcher(EntityTypes.INTERACTION) to EntityData(width = 0.0, height = 0.0, eyeHeight = 0.85),
    EntityDataMatcher(EntityTypes.IRON_GOLEM) to EntityData(width = 1.4, height = 2.7),
    EntityDataMatcher(EntityTypes.ITEM) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.ITEM_DISPLAY) to EntityData(width = 0.0, height = 0.0),
    EntityDataMatcher(EntityTypes.ITEM_FRAME) to EntityData(width = 0.5, height = 0.5, eyeHeight = 0.0),
    EntityDataMatcher(EntityTypes.LEASH_KNOT) to EntityData(width = 0.375, height = 0.5, eyeHeight = 0.0625),
    EntityDataMatcher(EntityTypes.LIGHTNING_BOLT) to EntityData(width = 0.0, height = 0.0),
    EntityDataMatcher(EntityTypes.LLAMA, isBaby = true) to EntityData(
        width = 0.45,
        height = 0.935,
        eyeHeight = 0.888249
    ),
    EntityDataMatcher(EntityTypes.LLAMA, isBaby = false) to EntityData(width = 0.9, height = 1.87, eyeHeight = 1.7765),
    EntityDataMatcher(EntityTypes.LLAMA_SPIT) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.MAGMA_CUBE, size = 4) to EntityData(width = 2.08, height = 2.08, eyeHeight = 1.3),
    EntityDataMatcher(EntityTypes.MAGMA_CUBE, size = 2) to EntityData(width = 1.04, height = 1.04, eyeHeight = 0.65),
    EntityDataMatcher(EntityTypes.MAGMA_CUBE, size = 1) to EntityData(width = 0.52, height = 0.52, eyeHeight = 0.325),
    EntityDataMatcher(EntityTypes.MARKER) to EntityData(width = 0.0, height = 0.0),
    EntityDataMatcher(EntityTypes.MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.CHEST_MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.COMMAND_BLOCK_MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.FURNACE_MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.HOPPER_MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.SPAWNER_MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.TNT_MINECART) to EntityData(width = 0.98, height = 0.7),
    EntityDataMatcher(EntityTypes.MOOSHROOM, isBaby = true) to EntityData(
        width = 0.45,
        height = 0.7,
        eyeHeight = 0.665
    ),
    EntityDataMatcher(EntityTypes.MOOSHROOM, isBaby = false) to EntityData(width = 0.9, height = 1.4, eyeHeight = 1.3),
    EntityDataMatcher(EntityTypes.MULE, isBaby = false) to EntityData(width = 1.396484, height = 1.6, eyeHeight = 1.52),
    EntityDataMatcher(EntityTypes.MULE, isBaby = true) to EntityData(width = 0.698242, height = 0.8, eyeHeight = 0.76),
    EntityDataMatcher(EntityTypes.OCELOT, isBaby = true) to EntityData(width = 0.3, height = 0.35),
    EntityDataMatcher(EntityTypes.OCELOT, isBaby = false) to EntityData(width = 0.6, height = 0.7),
    EntityDataMatcher(EntityTypes.OMINOUS_ITEM_SPAWNER) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.PAINTING) to EntityData(width = 0.5, height = 0.5),
    EntityDataMatcher(EntityTypes.PANDA, isBaby = true) to EntityData(width = 0.65, height = 0.625),
    EntityDataMatcher(EntityTypes.PANDA, isBaby = false) to EntityData(width = 1.3, height = 1.25),
    EntityDataMatcher(EntityTypes.PARROT) to EntityData(width = 0.5, height = 0.9, eyeHeight = 0.54),
    EntityDataMatcher(EntityTypes.PHANTOM) to EntityData(width = 0.9, height = 0.5, eyeHeight = 0.175),
    EntityDataMatcher(EntityTypes.PIG, isBaby = false) to EntityData(width = 0.9, height = 0.9),
    EntityDataMatcher(EntityTypes.PIG, isBaby = true) to EntityData(width = 0.45, height = 0.45),
    EntityDataMatcher(EntityTypes.PIGLIN, isBaby = true) to EntityData(width = 0.3, height = 0.975, eyeHeight = 0.97),
    EntityDataMatcher(EntityTypes.PIGLIN, isBaby = false) to EntityData(width = 0.6, height = 1.95, eyeHeight = 1.79),
    EntityDataMatcher(EntityTypes.PIGLIN_BRUTE) to EntityData(width = 0.6, height = 1.95, eyeHeight = 1.79),
    EntityDataMatcher(EntityTypes.PILLAGER) to EntityData(width = 0.6, height = 1.95),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SLEEPING) to EntityData(
        width = 0.2,
        height = 0.2,
        eyeHeight = 0.2
    ),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.FALL_FLYING) to EntityData(
        width = 0.6,
        height = 0.6,
        eyeHeight = 0.4
    ),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SWIMMING) to EntityData(
        width = 0.6,
        height = 0.6,
        eyeHeight = 0.4
    ),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.CROUCHING) to EntityData(
        width = 0.6,
        height = 1.5,
        eyeHeight = 1.27
    ),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.STANDING) to EntityData(
        width = 0.6,
        height = 1.8,
        eyeHeight = 1.62
    ),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SPIN_ATTACK) to EntityData(
        width = 0.6,
        height = 0.6,
        eyeHeight = 0.4
    ),
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.DYING) to EntityData(
        width = 0.2,
        height = 0.2,
        eyeHeight = 1.62
    ),
    EntityDataMatcher(EntityTypes.POLAR_BEAR, isBaby = true) to EntityData(width = 0.7, height = 0.7),
    EntityDataMatcher(EntityTypes.POLAR_BEAR, isBaby = false) to EntityData(width = 1.4, height = 1.4),
    EntityDataMatcher(EntityTypes.POTION) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.TNT) to EntityData(width = 0.98, height = 0.98, eyeHeight = 0.15),
    EntityDataMatcher(EntityTypes.PUFFERFISH, puffState = PufferFishMeta.State.entries[0]) to EntityData(
        width = 0.35,
        height = 0.35,
        eyeHeight = 0.2275
    ),
    EntityDataMatcher(EntityTypes.PUFFERFISH, puffState = PufferFishMeta.State.entries[1]) to EntityData(
        width = 0.49,
        height = 0.49,
        eyeHeight = 0.3185
    ),
    EntityDataMatcher(EntityTypes.PUFFERFISH, puffState = PufferFishMeta.State.entries[2]) to EntityData(
        width = 0.7,
        height = 0.7,
        eyeHeight = 0.455
    ),
    EntityDataMatcher(EntityTypes.RABBIT, isBaby = true) to EntityData(width = 0.2, height = 0.25),
    EntityDataMatcher(EntityTypes.RABBIT, isBaby = false) to EntityData(width = 0.4, height = 0.5),
    EntityDataMatcher(EntityTypes.RAVAGER) to EntityData(width = 1.95, height = 2.2),
    EntityDataMatcher(EntityTypes.SALMON) to EntityData(width = 0.7, height = 0.4, eyeHeight = 0.26),
    EntityDataMatcher(EntityTypes.SHEEP, isBaby = false) to EntityData(width = 0.9, height = 1.3, eyeHeight = 1.235),
    EntityDataMatcher(EntityTypes.SHEEP, isBaby = true) to EntityData(width = 0.45, height = 0.65, eyeHeight = 0.6175),
    EntityDataMatcher(EntityTypes.SHULKER) to EntityData(width = 1.0, height = 1.0, eyeHeight = 0.5),
    EntityDataMatcher(EntityTypes.SHULKER_BULLET) to EntityData(width = 0.3125, height = 0.3125),
    EntityDataMatcher(EntityTypes.SILVERFISH) to EntityData(width = 0.4, height = 0.3, eyeHeight = 0.13),
    EntityDataMatcher(EntityTypes.SKELETON) to EntityData(width = 0.6, height = 1.99, eyeHeight = 1.74),
    EntityDataMatcher(EntityTypes.SKELETON_HORSE, isBaby = false) to EntityData(
        width = 1.396484,
        height = 1.6,
        eyeHeight = 1.52
    ),
    EntityDataMatcher(EntityTypes.SKELETON_HORSE, isBaby = true) to EntityData(
        width = 0.698242,
        height = 0.8,
        eyeHeight = 0.76
    ),
    EntityDataMatcher(EntityTypes.SLIME, size = 4) to EntityData(width = 2.08, height = 2.08, eyeHeight = 1.3),
    EntityDataMatcher(EntityTypes.SLIME, size = 2) to EntityData(width = 1.04, height = 1.04, eyeHeight = 0.65),
    EntityDataMatcher(EntityTypes.SLIME, size = 1) to EntityData(width = 0.52, height = 0.52, eyeHeight = 0.325),
    EntityDataMatcher(EntityTypes.SMALL_FIREBALL) to EntityData(width = 0.3125, height = 0.3125),
    EntityDataMatcher(EntityTypes.SNIFFER, isBaby = true) to EntityData(
        width = 0.95,
        height = 0.875,
        eyeHeight = 0.525
    ),
    EntityDataMatcher(EntityTypes.SNIFFER, isBaby = false) to EntityData(width = 1.9, height = 1.75, eyeHeight = 1.05),
    EntityDataMatcher(EntityTypes.SNOW_GOLEM) to EntityData(width = 0.7, height = 1.9, eyeHeight = 1.7),
    EntityDataMatcher(EntityTypes.SNOWBALL) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.SPIDER) to EntityData(width = 1.4, height = 0.9, eyeHeight = 0.65),
    EntityDataMatcher(EntityTypes.SQUID) to EntityData(width = 0.8, height = 0.8, eyeHeight = 0.4),
    EntityDataMatcher(EntityTypes.STRAY) to EntityData(width = 0.6, height = 1.99, eyeHeight = 1.74),
    EntityDataMatcher(EntityTypes.STRIDER, isBaby = true) to EntityData(width = 0.45, height = 0.85),
    EntityDataMatcher(EntityTypes.STRIDER, isBaby = false) to EntityData(width = 0.9, height = 1.7),
    EntityDataMatcher(EntityTypes.TADPOLE) to EntityData(width = 0.4, height = 0.3, eyeHeight = 0.195),
    EntityDataMatcher(EntityTypes.TEXT_DISPLAY) to EntityData(width = 0.0, height = 0.0),
    EntityDataMatcher(EntityTypes.EXPERIENCE_BOTTLE) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.EGG) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.ENDER_PEARL) to EntityData(width = 0.25, height = 0.25),
    EntityDataMatcher(EntityTypes.TRADER_LLAMA, isBaby = true) to EntityData(
        width = 0.45,
        height = 0.935,
        eyeHeight = 0.88825
    ),
    EntityDataMatcher(EntityTypes.TRADER_LLAMA, isBaby = false) to EntityData(
        width = 0.9,
        height = 1.87,
        eyeHeight = 1.7765
    ),
    EntityDataMatcher(EntityTypes.TRIDENT) to EntityData(width = 0.5, height = 0.5, eyeHeight = 0.13),
    EntityDataMatcher(EntityTypes.TROPICAL_FISH) to EntityData(width = 0.5, height = 0.4, eyeHeight = 0.26),
    EntityDataMatcher(EntityTypes.TURTLE, isBaby = true) to EntityData(width = 0.36, height = 0.12),
    EntityDataMatcher(EntityTypes.TURTLE, isBaby = false) to EntityData(width = 1.2, height = 0.4),
    EntityDataMatcher(EntityTypes.VEX) to EntityData(width = 0.4, height = 0.8, eyeHeight = 0.51875),
    EntityDataMatcher(EntityTypes.VILLAGER, pose = EntityPose.STANDING, isBaby = false) to EntityData(
        width = 0.6,
        height = 1.95,
        eyeHeight = 0.81
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, pose = EntityPose.SLEEPING, isBaby = true) to EntityData(
        width = 0.2,
        height = 0.975,
        eyeHeight = 0.81
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, isBaby = true, pose = EntityPose.STANDING) to EntityData(
        width = 0.3,
        height = 0.975,
        eyeHeight = 0.81
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, pose = EntityPose.SLEEPING, isBaby = false) to EntityData(
        width = 0.2,
        height = 1.95,
        eyeHeight = 1.62
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, isBaby = true, pose = EntityPose.SLEEPING) to EntityData(
        width = 0.2,
        height = 0.975,
        eyeHeight = 0.81
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, isBaby = false, pose = EntityPose.SLEEPING) to EntityData(
        width = 0.2,
        height = 1.95,
        eyeHeight = 1.62
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, pose = EntityPose.STANDING, isBaby = true) to EntityData(
        width = 0.3,
        height = 1.95,
        eyeHeight = 0.81
    ),
    EntityDataMatcher(EntityTypes.VILLAGER, isBaby = false, pose = EntityPose.STANDING) to EntityData(
        width = 0.2,
        height = 1.95,
        eyeHeight = 1.62
    ),
    EntityDataMatcher(EntityTypes.VINDICATOR) to EntityData(width = 0.6, height = 1.95),
    EntityDataMatcher(EntityTypes.WANDERING_TRADER, isBaby = false) to EntityData(
        width = 0.6,
        height = 1.95,
        eyeHeight = 1.62
    ),
    EntityDataMatcher(EntityTypes.WANDERING_TRADER, isBaby = true) to EntityData(
        width = 0.3,
        height = 0.975,
        eyeHeight = 0.81
    ),
    EntityDataMatcher(EntityTypes.WARDEN) to EntityData(width = 0.9, height = 1.0),
    EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.EMERGING) to EntityData(width = 0.9, height = 1.0),
    EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.ROARING) to EntityData(width = 0.9, height = 2.9),
    EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.SNIFFING) to EntityData(width = 0.9, height = 2.9),
    EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.STANDING) to EntityData(width = 0.9, height = 2.9),
    EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.DIGGING) to EntityData(width = 0.9, height = 1.0),
    EntityDataMatcher(EntityTypes.WIND_CHARGE) to EntityData(width = 0.3125, height = 0.3125, eyeHeight = 0.0),
    EntityDataMatcher(EntityTypes.WITCH) to EntityData(width = 0.6, height = 1.95, eyeHeight = 1.62),
    EntityDataMatcher(EntityTypes.WITHER) to EntityData(width = 0.9, height = 3.5),
    EntityDataMatcher(EntityTypes.WITHER_SKELETON) to EntityData(width = 0.7, height = 2.4, eyeHeight = 2.1),
    EntityDataMatcher(EntityTypes.WITHER_SKULL) to EntityData(width = 0.3125, height = 0.3125),
    EntityDataMatcher(EntityTypes.WOLF, isBaby = true) to EntityData(width = 0.3, height = 0.425, eyeHeight = 0.34),
    EntityDataMatcher(EntityTypes.WOLF, isBaby = false) to EntityData(width = 0.6, height = 0.85, eyeHeight = 0.68),
    EntityDataMatcher(EntityTypes.ZOGLIN, isBaby = false) to EntityData(width = 1.396484, height = 1.4),
    EntityDataMatcher(EntityTypes.ZOGLIN, isBaby = true) to EntityData(width = 0.698242, height = 0.7),
    EntityDataMatcher(EntityTypes.ZOMBIE, isBaby = true) to EntityData(width = 0.3, height = 0.975, eyeHeight = 0.93),
    EntityDataMatcher(EntityTypes.ZOMBIE, isBaby = false) to EntityData(width = 0.6, height = 1.95, eyeHeight = 1.74),
    EntityDataMatcher(EntityTypes.ZOMBIE_HORSE, isBaby = true) to EntityData(
        width = 0.698242,
        height = 0.8,
        eyeHeight = 0.76
    ),
    EntityDataMatcher(EntityTypes.ZOMBIE_HORSE, isBaby = false) to EntityData(
        width = 1.396484,
        height = 1.6,
        eyeHeight = 1.52
    ),
    EntityDataMatcher(EntityTypes.ZOMBIE_VILLAGER, isBaby = true) to EntityData(
        width = 0.3,
        height = 0.975,
        eyeHeight = 0.93
    ),
    EntityDataMatcher(EntityTypes.ZOMBIE_VILLAGER, isBaby = false) to EntityData(
        width = 0.6,
        height = 1.95,
        eyeHeight = 1.74
    ),
    EntityDataMatcher(EntityTypes.ZOMBIFIED_PIGLIN, isBaby = true) to EntityData(
        width = 0.3,
        height = 0.975,
        eyeHeight = 0.97
    ),
    EntityDataMatcher(EntityTypes.ZOMBIFIED_PIGLIN, isBaby = false) to EntityData(
        width = 0.6,
        height = 1.95,
        eyeHeight = 1.79
    ),
//</editor-fold>
)

private val manualEntityDataMap = mapOf(
    EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.3,
        eyeHeight = 1.02
    ),
    EntityDataMatcher(EntityTypes.ZOMBIE, isBaby = false, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.3,
        eyeHeight = 1.02
    ),
    EntityDataMatcher(EntityTypes.ZOMBIE, isBaby = true, pose = EntityPose.SITTING) to EntityData(
        width = 0.46,
        height = 0.8,
        eyeHeight = 0.54
    ),
    EntityDataMatcher(EntityTypes.HUSK, isBaby = false, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.4,
        eyeHeight = 1.12
    ),
    EntityDataMatcher(EntityTypes.HUSK, isBaby = true, pose = EntityPose.SITTING) to EntityData(
        width = 0.46,
        height = 0.8,
        eyeHeight = 0.54
    ),
    EntityDataMatcher(EntityTypes.SKELETON, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.3,
        eyeHeight = 1.02
    ),
    EntityDataMatcher(EntityTypes.PILLAGER, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.35,
        eyeHeight = 1.02
    ),
    EntityDataMatcher(EntityTypes.VINDICATOR, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.35,
        eyeHeight = 1.02
    ),
    EntityDataMatcher(EntityTypes.ILLUSIONER, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.35,
        eyeHeight = 1.02
    ),
    EntityDataMatcher(EntityTypes.PIGLIN, isBaby = false, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.3,
        eyeHeight = 1.09
    ),
    EntityDataMatcher(EntityTypes.PIGLIN, isBaby = true, pose = EntityPose.SITTING) to EntityData(
        width = 0.48,
        height = 0.8,
        eyeHeight = 0.54
    ),
    EntityDataMatcher(EntityTypes.PIGLIN_BRUTE, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 1.3,
        eyeHeight = 1.09
    ),
    EntityDataMatcher(EntityTypes.CAT, isBaby = false, pose = EntityPose.SITTING) to EntityData(
        width = 0.6,
        height = 0.7,
        eyeHeight = 0.64
    ),
    EntityDataMatcher(EntityTypes.CAT, isBaby = true, pose = EntityPose.SITTING) to EntityData(
        width = 0.3,
        height = 0.35,
        eyeHeight = 0.37
    ),
    EntityDataMatcher(EntityTypes.CAT, isBaby = true) to EntityData(width = 0.3, height = 0.35, eyeHeight = 0.28),
    EntityDataMatcher(EntityTypes.CAT, isBaby = false) to EntityData(width = 0.6, height = 0.7, eyeHeight = 0.48),
)

private val entityDataMap = manualEntityDataMap + generatedEntityDataMap

private fun pose(properties: Map<KClass<*>, EntityProperty>): EntityPose {
    val isSitting = properties.property(SittingProperty::class)?.sitting
    if (isSitting == true) return EntityPose.SITTING
    val isSleeping = properties.property(SleepingProperty::class)?.sleeping
    if (isSleeping == true) return EntityPose.SLEEPING

    val pose = properties.property(PoseProperty::class)?.pose
    if (pose != null) return pose

    return EntityPose.STANDING
}

private fun EntityType.matcher(properties: Map<KClass<*>, EntityProperty>): EntityDataMatcher {
    val isBaby = properties.property(AgeableProperty::class)?.baby ?: false
    val size = properties.property(SizeProperty::class)?.size ?: 0
    val small = properties.property(SmallProperty::class)?.small ?: false
    val marker = properties.property(MarkerProperty::class)?.marker ?: false
    val puffState = properties.property(PuffStateProperty::class)?.state ?: PufferFishMeta.State.UNPUFFED

    return EntityDataMatcher(this, isBaby, pose(properties), size, small, marker, puffState)
}

private val EntityDataMatcher.entityData: EntityData?
    get() = entityDataMap.entries.find { (key, _) -> this == key }?.value

private val EntityDataMatcher.width: Double
    get() = entityData?.width
        ?: throw IllegalArgumentException("Could not find width for $this, please report this on the TypeWriter Discord!")

private val EntityDataMatcher.height: Double
    get() = entityData?.height
        ?: throw IllegalArgumentException("Could not find height for $this, please report this on the TypeWriter Discord!")

private val EntityDataMatcher.eyeHeight: Double
    get() = entityData?.eyeHeight
        ?: throw IllegalArgumentException("Could not find eye height for $this, please report this on the TypeWriter Discord!")

fun EntityType.state(properties: Map<KClass<*>, EntityProperty>): EntityState {
    val matcher = matcher(properties)
    val scale = properties.property(ScaleProperty::class)?.scale ?: 1.0
    val boxSize = properties.property(BoxSizeProperty::class)

    return EntityState(
        eyeHeight = matcher.eyeHeight * scale,
        speed = properties.property(SpeedProperty::class)?.speed ?: 0.2085f,
        width = (boxSize?.width ?: matcher.width) * scale,
        height = (boxSize?.height ?: matcher.height) * scale,
    )
}

private fun EntityDataMatcher.width(properties: Map<KClass<*>, EntityProperty>): Double {
    val scale = properties.property(ScaleProperty::class)?.scale ?: 1.0
    val boxSize = properties.property(BoxSizeProperty::class)
    return (boxSize?.width ?: width) * scale
}

private fun EntityDataMatcher.height(properties: Map<KClass<*>, EntityProperty>): Double {
    val scale = properties.property(ScaleProperty::class)?.scale ?: 1.0
    val boxSize = properties.property(BoxSizeProperty::class)
    return (boxSize?.height ?: height) * scale
}

private fun EntityDataMatcher.eyeHeight(properties: Map<KClass<*>, EntityProperty>): Double {
    val scale = properties.property(ScaleProperty::class)?.scale ?: 1.0
    return eyeHeight * scale
}

fun EntityType.pathingCapabilities(properties: Map<KClass<*>, EntityProperty>): EntityPathingCapabilities {
    val matcher = matcher(properties)
    return EntityPathingCapabilities.DEFAULT.copy(
        width = matcher.width(properties),
        height = matcher.height(properties)
    )
}
