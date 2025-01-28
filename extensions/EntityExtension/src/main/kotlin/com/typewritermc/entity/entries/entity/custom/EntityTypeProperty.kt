package com.typewritermc.entity.entries.entity.custom

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityType
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.engine.paper.entry.entity.EntityState
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.entity.entries.data.minecraft.PoseProperty
import com.typewritermc.entity.entries.data.minecraft.SpeedProperty
import com.typewritermc.entity.entries.data.minecraft.living.AgeableProperty
import com.typewritermc.entity.entries.data.minecraft.living.ScaleProperty
import com.typewritermc.entity.entries.data.minecraft.living.SizeProperty
import com.typewritermc.entity.entries.data.minecraft.living.pufferfish.PuffStateProperty
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
        if (other.size != null && size != null && size >= other.size) return false
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

private fun EntityType.matcher(properties: Map<KClass<*>, EntityProperty>): EntityDataMatcher {
    val isBaby = properties.property(AgeableProperty::class)?.baby ?: false
    val pose = properties.property(PoseProperty::class)?.pose ?: EntityPose.STANDING
    val size = properties.property(SizeProperty::class)?.size ?: 0
    val small = properties.property(SmallProperty::class)?.small ?: false
    val marker = properties.property(MarkerProperty::class)?.marker ?: false
    val puffState = properties.property(PuffStateProperty::class)?.state ?: PufferFishMeta.State.UNPUFFED

    return EntityDataMatcher(this, isBaby, pose, size, small, marker, puffState)
}

fun EntityType.state(properties: Map<KClass<*>, EntityProperty>): EntityState {
    val matcher = matcher(properties)
    return EntityState(
        eyeHeight = matcher.eyeHeight * (properties.property(ScaleProperty::class)?.scale ?: 1.0),
        speed = properties.property(SpeedProperty::class)?.speed ?: 0.2085f,
    )
}

private val EntityDataMatcher.eyeHeight: Double
    get() {
        return when (this) {
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SITTING) -> 0.98
//<editor-fold desc="Entity EntityEyeHeightProperty by properties">
            EntityDataMatcher(EntityTypes.ALLAY) -> 0.36
            EntityDataMatcher(EntityTypes.AREA_EFFECT_CLOUD) -> 0.425
            EntityDataMatcher(EntityTypes.ARMADILLO, isBaby = false) -> 0.26
            EntityDataMatcher(EntityTypes.ARMADILLO, isBaby = true) -> 0.156
            EntityDataMatcher(EntityTypes.ARMOR_STAND, small = true, marker = true) -> 0.0
            EntityDataMatcher(EntityTypes.ARMOR_STAND, small = false, marker = true) -> 0.0
            EntityDataMatcher(EntityTypes.ARMOR_STAND, small = false, marker = false) -> 1.7775
            EntityDataMatcher(EntityTypes.ARMOR_STAND, small = true, marker = false) -> 0.49375
            EntityDataMatcher(EntityTypes.ARROW) -> 0.13
            EntityDataMatcher(EntityTypes.AXOLOTL, isBaby = true) -> 0.137549
            EntityDataMatcher(EntityTypes.AXOLOTL, isBaby = false) -> 0.2751
            EntityDataMatcher(EntityTypes.BAT) -> 0.45
            EntityDataMatcher(EntityTypes.BEE, isBaby = true) -> 0.15
            EntityDataMatcher(EntityTypes.BEE, isBaby = false) -> 0.3
            EntityDataMatcher(EntityTypes.BLAZE) -> 1.53
            EntityDataMatcher(EntityTypes.BLOCK_DISPLAY) -> 0.0
            EntityDataMatcher(EntityTypes.BOAT) -> 0.5625
            EntityDataMatcher(EntityTypes.CHEST_BOAT) -> 0.5625
            EntityDataMatcher(EntityTypes.BOGGED) -> 1.74
            EntityDataMatcher(EntityTypes.BREEZE) -> 1.3452
            EntityDataMatcher(EntityTypes.CAMEL, isBaby = true, pose = EntityPose.SITTING) -> 0.38025
            EntityDataMatcher(EntityTypes.CAMEL, isBaby = true, pose = EntityPose.STANDING) -> 1.02375
            EntityDataMatcher(EntityTypes.CAMEL, isBaby = false, pose = EntityPose.SITTING) -> 0.845
            EntityDataMatcher(EntityTypes.CAMEL, isBaby = false, pose = EntityPose.STANDING) -> 2.275
            EntityDataMatcher(EntityTypes.CAT, isBaby = false) -> 0.35
            EntityDataMatcher(EntityTypes.CAT, isBaby = true) -> 0.175
            EntityDataMatcher(EntityTypes.CAVE_SPIDER) -> 0.45
            EntityDataMatcher(EntityTypes.CHICKEN, isBaby = false) -> 0.644
            EntityDataMatcher(EntityTypes.CHICKEN, isBaby = true) -> 0.2975
            EntityDataMatcher(EntityTypes.COD) -> 0.195
            EntityDataMatcher(EntityTypes.COW, isBaby = true) -> 0.665
            EntityDataMatcher(EntityTypes.COW, isBaby = false) -> 1.3
            EntityDataMatcher(EntityTypes.CREEPER) -> 1.445
            EntityDataMatcher(EntityTypes.DOLPHIN) -> 0.3
            EntityDataMatcher(EntityTypes.DONKEY, isBaby = false) -> 1.425
            EntityDataMatcher(EntityTypes.DONKEY, isBaby = true) -> 0.7125
            EntityDataMatcher(EntityTypes.DRAGON_FIREBALL) -> 0.85
            EntityDataMatcher(EntityTypes.DROWNED, isBaby = true) -> 0.93
            EntityDataMatcher(EntityTypes.DROWNED, isBaby = false) -> 1.74
            EntityDataMatcher(EntityTypes.ELDER_GUARDIAN) -> 0.998749
            EntityDataMatcher(EntityTypes.END_CRYSTAL) -> 1.7
            EntityDataMatcher(EntityTypes.ENDER_DRAGON) -> 6.8
            EntityDataMatcher(EntityTypes.ENDERMAN) -> 2.55
            EntityDataMatcher(EntityTypes.ENDERMITE) -> 0.13
            EntityDataMatcher(EntityTypes.EVOKER) -> 1.6575
            EntityDataMatcher(EntityTypes.EVOKER_FANGS) -> 0.68
            EntityDataMatcher(EntityTypes.EXPERIENCE_ORB) -> 0.425
            EntityDataMatcher(EntityTypes.EYE_OF_ENDER) -> 0.2125
            EntityDataMatcher(EntityTypes.FALLING_BLOCK) -> 0.833
            EntityDataMatcher(EntityTypes.FIREBALL) -> 0.85
            EntityDataMatcher(EntityTypes.FIREWORK_ROCKET) -> 0.2125
            EntityDataMatcher(EntityTypes.FISHING_BOBBER) -> 0.2125
            EntityDataMatcher(EntityTypes.FOX, isBaby = true) -> 0.2975
            EntityDataMatcher(EntityTypes.FOX, isBaby = false) -> 0.4
            EntityDataMatcher(EntityTypes.FROG) -> 0.425
            EntityDataMatcher(EntityTypes.GHAST) -> 2.6
            EntityDataMatcher(EntityTypes.GIANT) -> 10.44
            EntityDataMatcher(EntityTypes.GLOW_ITEM_FRAME) -> 0.0
            EntityDataMatcher(EntityTypes.GLOW_SQUID) -> 0.4
            EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.LONG_JUMPING, isBaby = true) -> 0.38675
            EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.STANDING, isBaby = true) -> 0.5525
            EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.LONG_JUMPING, isBaby = false) -> 0.7735
            EntityDataMatcher(EntityTypes.GOAT, pose = EntityPose.STANDING, isBaby = false) -> 1.105
            EntityDataMatcher(EntityTypes.GUARDIAN) -> 0.425
            EntityDataMatcher(EntityTypes.HOGLIN, isBaby = false) -> 1.19
            EntityDataMatcher(EntityTypes.HOGLIN, isBaby = true) -> 0.595
            EntityDataMatcher(EntityTypes.HORSE, isBaby = true) -> 0.76
            EntityDataMatcher(EntityTypes.HORSE, isBaby = false) -> 1.52
            EntityDataMatcher(EntityTypes.HUSK, isBaby = false) -> 1.74
            EntityDataMatcher(EntityTypes.HUSK, isBaby = true) -> 0.93
            EntityDataMatcher(EntityTypes.ILLUSIONER) -> 1.6575
            EntityDataMatcher(EntityTypes.INTERACTION) -> 0.85
            EntityDataMatcher(EntityTypes.IRON_GOLEM) -> 2.295
            EntityDataMatcher(EntityTypes.ITEM) -> 0.2125
            EntityDataMatcher(EntityTypes.ITEM_DISPLAY) -> 0.0
            EntityDataMatcher(EntityTypes.ITEM_FRAME) -> 0.0
            EntityDataMatcher(EntityTypes.LEASH_KNOT) -> 0.0625
            EntityDataMatcher(EntityTypes.LIGHTNING_BOLT) -> 0.0
            EntityDataMatcher(EntityTypes.LLAMA, isBaby = false) -> 1.7765
            EntityDataMatcher(EntityTypes.LLAMA, isBaby = true) -> 0.888249
            EntityDataMatcher(EntityTypes.MAGMA_CUBE, size = 4) -> 1.3
            EntityDataMatcher(EntityTypes.MAGMA_CUBE, size = 2) -> 0.65
            EntityDataMatcher(EntityTypes.MAGMA_CUBE, size = 1) -> 0.325
            EntityDataMatcher(EntityTypes.MARKER) -> 0.0
            EntityDataMatcher(EntityTypes.MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.CHEST_MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.COMMAND_BLOCK_MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.FURNACE_MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.HOPPER_MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.SPAWNER_MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.TNT_MINECART) -> 0.595
            EntityDataMatcher(EntityTypes.MOOSHROOM, isBaby = false) -> 1.3
            EntityDataMatcher(EntityTypes.MOOSHROOM, isBaby = true) -> 0.665
            EntityDataMatcher(EntityTypes.MULE, isBaby = true) -> 0.76
            EntityDataMatcher(EntityTypes.MULE, isBaby = false) -> 1.52
            EntityDataMatcher(EntityTypes.OCELOT, isBaby = false) -> 0.595
            EntityDataMatcher(EntityTypes.OCELOT, isBaby = true) -> 0.2975
            EntityDataMatcher(EntityTypes.OMINOUS_ITEM_SPAWNER) -> 0.2125
            EntityDataMatcher(EntityTypes.PAINTING) -> 0.425
            EntityDataMatcher(EntityTypes.PANDA, isBaby = true) -> 0.53125
            EntityDataMatcher(EntityTypes.PANDA, isBaby = false) -> 1.0625
            EntityDataMatcher(EntityTypes.PARROT) -> 0.54
            EntityDataMatcher(EntityTypes.PHANTOM) -> 0.175
            EntityDataMatcher(EntityTypes.PIG, isBaby = false) -> 0.765
            EntityDataMatcher(EntityTypes.PIG, isBaby = true) -> 0.3825
            EntityDataMatcher(EntityTypes.PIGLIN, isBaby = false) -> 1.79
            EntityDataMatcher(EntityTypes.PIGLIN, isBaby = true) -> 0.97
            EntityDataMatcher(EntityTypes.PIGLIN_BRUTE) -> 1.79
            EntityDataMatcher(EntityTypes.PILLAGER) -> 1.6575
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.DYING) -> 1.62
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.FALL_FLYING) -> 0.4
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SLEEPING) -> 0.2
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SPIN_ATTACK) -> 0.4
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.SWIMMING) -> 0.4
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.STANDING) -> 1.62
            EntityDataMatcher(EntityTypes.PLAYER, pose = EntityPose.CROUCHING) -> 1.27
            EntityDataMatcher(EntityTypes.POLAR_BEAR, isBaby = true) -> 0.595
            EntityDataMatcher(EntityTypes.POLAR_BEAR, isBaby = false) -> 1.19
            EntityDataMatcher(EntityTypes.POTION) -> 0.2125
            EntityDataMatcher(EntityTypes.TNT) -> 0.15
            EntityDataMatcher(EntityTypes.PUFFERFISH, puffState = PufferFishMeta.State.entries[0]) -> 0.2275
            EntityDataMatcher(EntityTypes.PUFFERFISH, puffState = PufferFishMeta.State.entries[2]) -> 0.455
            EntityDataMatcher(EntityTypes.PUFFERFISH, puffState = PufferFishMeta.State.entries[1]) -> 0.3185
            EntityDataMatcher(EntityTypes.RABBIT, isBaby = false) -> 0.425
            EntityDataMatcher(EntityTypes.RABBIT, isBaby = true) -> 0.2125
            EntityDataMatcher(EntityTypes.RAVAGER) -> 1.87
            EntityDataMatcher(EntityTypes.SALMON) -> 0.26
            EntityDataMatcher(EntityTypes.SHEEP, isBaby = false) -> 1.235
            EntityDataMatcher(EntityTypes.SHEEP, isBaby = true) -> 0.6175
            EntityDataMatcher(EntityTypes.SHULKER) -> 0.5
            EntityDataMatcher(EntityTypes.SHULKER_BULLET) -> 0.265625
            EntityDataMatcher(EntityTypes.SILVERFISH) -> 0.13
            EntityDataMatcher(EntityTypes.SKELETON) -> 1.74
            EntityDataMatcher(EntityTypes.SKELETON_HORSE, isBaby = false) -> 1.52
            EntityDataMatcher(EntityTypes.SKELETON_HORSE, isBaby = true) -> 0.76
            EntityDataMatcher(EntityTypes.SLIME, size = 4) -> 1.3
            EntityDataMatcher(EntityTypes.SLIME, size = 2) -> 0.65
            EntityDataMatcher(EntityTypes.SLIME, size = 1) -> 0.325
            EntityDataMatcher(EntityTypes.SMALL_FIREBALL) -> 0.265625
            EntityDataMatcher(EntityTypes.SNIFFER, isBaby = false) -> 1.05
            EntityDataMatcher(EntityTypes.SNIFFER, isBaby = true) -> 0.525
            EntityDataMatcher(EntityTypes.SNOW_GOLEM) -> 1.7
            EntityDataMatcher(EntityTypes.SNOWBALL) -> 0.2125
            EntityDataMatcher(EntityTypes.SPIDER) -> 0.65
            EntityDataMatcher(EntityTypes.SQUID) -> 0.4
            EntityDataMatcher(EntityTypes.STRAY) -> 1.74
            EntityDataMatcher(EntityTypes.STRIDER, isBaby = true) -> 0.7225
            EntityDataMatcher(EntityTypes.STRIDER, isBaby = false) -> 1.445
            EntityDataMatcher(EntityTypes.TADPOLE) -> 0.195
            EntityDataMatcher(EntityTypes.TEXT_DISPLAY) -> 0.0
            EntityDataMatcher(EntityTypes.EXPERIENCE_BOTTLE) -> 0.2125
            EntityDataMatcher(EntityTypes.EGG) -> 0.2125
            EntityDataMatcher(EntityTypes.ENDER_PEARL) -> 0.2125
            EntityDataMatcher(EntityTypes.TRADER_LLAMA, isBaby = false) -> 1.7765
            EntityDataMatcher(EntityTypes.TRADER_LLAMA, isBaby = true) -> 0.88825
            EntityDataMatcher(EntityTypes.TRIDENT) -> 0.13
            EntityDataMatcher(EntityTypes.TROPICAL_FISH) -> 0.26
            EntityDataMatcher(EntityTypes.TURTLE, isBaby = false) -> 0.34
            EntityDataMatcher(EntityTypes.TURTLE, isBaby = true) -> 0.102
            EntityDataMatcher(EntityTypes.VEX) -> 0.51875
            EntityDataMatcher(EntityTypes.VILLAGER, isBaby = false, pose = EntityPose.STANDING) -> 1.62
            EntityDataMatcher(EntityTypes.VILLAGER, isBaby = true, pose = EntityPose.SLEEPING) -> 0.2
            EntityDataMatcher(EntityTypes.VILLAGER, isBaby = false, pose = EntityPose.SLEEPING) -> 0.2
            EntityDataMatcher(EntityTypes.VILLAGER, isBaby = true, pose = EntityPose.STANDING) -> 0.81
            EntityDataMatcher(EntityTypes.VINDICATOR) -> 1.6575
            EntityDataMatcher(EntityTypes.WANDERING_TRADER, isBaby = false) -> 1.62
            EntityDataMatcher(EntityTypes.WANDERING_TRADER, isBaby = true) -> 0.81
            EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.DIGGING) -> 0.85
            EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.EMERGING) -> 0.85
            EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.ROARING) -> 2.4650002
            EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.SNIFFING) -> 2.4650002
            EntityDataMatcher(EntityTypes.WARDEN, pose = EntityPose.STANDING) -> 2.4650002
            EntityDataMatcher(EntityTypes.WIND_CHARGE) -> 0.0
            EntityDataMatcher(EntityTypes.WITCH) -> 1.62
            EntityDataMatcher(EntityTypes.WITHER) -> 2.975
            EntityDataMatcher(EntityTypes.WITHER_SKELETON) -> 2.1
            EntityDataMatcher(EntityTypes.WITHER_SKULL) -> 0.265625
            EntityDataMatcher(EntityTypes.WOLF, isBaby = false) -> 0.68
            EntityDataMatcher(EntityTypes.WOLF, isBaby = true) -> 0.34
            EntityDataMatcher(EntityTypes.ZOGLIN, isBaby = true) -> 0.595
            EntityDataMatcher(EntityTypes.ZOGLIN, isBaby = false) -> 1.19
            EntityDataMatcher(EntityTypes.ZOMBIE, isBaby = true) -> 0.93
            EntityDataMatcher(EntityTypes.ZOMBIE, isBaby = false) -> 1.74
            EntityDataMatcher(EntityTypes.ZOMBIE_HORSE, isBaby = false) -> 1.52
            EntityDataMatcher(EntityTypes.ZOMBIE_HORSE, isBaby = true) -> 0.76
            EntityDataMatcher(EntityTypes.ZOMBIE_VILLAGER, isBaby = true) -> 0.93
            EntityDataMatcher(EntityTypes.ZOMBIE_VILLAGER, isBaby = false) -> 1.74
            EntityDataMatcher(EntityTypes.ZOMBIFIED_PIGLIN, isBaby = false) -> 1.79
            EntityDataMatcher(EntityTypes.ZOMBIFIED_PIGLIN, isBaby = true) -> 0.97
//</editor-fold>
            else -> throw IllegalArgumentException("Could not find eye height for $this, please report this on the TypeWriter Discord!")
        }
    }
