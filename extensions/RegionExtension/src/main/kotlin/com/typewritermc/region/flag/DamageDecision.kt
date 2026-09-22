package com.typewritermc.region.flag

import com.typewritermc.core.utils.point.Position
import com.typewritermc.region.entries.modifier.MobDamageModifierEntry
import com.typewritermc.region.entries.modifier.PvpModifierEntry
import org.bukkit.damage.DamageSource
import org.bukkit.entity.AreaEffectCloud
import org.bukkit.entity.Entity
import org.bukkit.entity.EvokerFangs
import org.bukkit.entity.minecart.ExplosiveMinecart
import org.bukkit.entity.Firework
import org.bukkit.entity.Player
import org.bukkit.entity.Projectile
import org.bukkit.entity.TNTPrimed
import org.bukkit.entity.Tameable
import org.bukkit.event.entity.EntityDamageByEntityEvent
import org.bukkit.event.entity.EntityDamageEvent

/**
 * Whether damage is allowed, given what the specific flag (PvP or mob damage) decided and what the
 * general player damage flag decided.
 *
 * The higher priority decision wins. When the same region holds both, the specific one wins, because
 * a region carrying "PvP allowed" and "player damage denied" means exactly that: fight here, but do
 * not fall to your death.
 *
 * `null` when no region decided, and the damage is then nobody's business.
 */
internal fun allowsDamage(
    specific: FlagDecision<*>?,
    general: FlagDecision<*>?,
    allowedBySpecific: Boolean,
    allowedByGeneral: Boolean,
): Boolean? {
    if (specific == null && general == null) return null
    if (specific == null) return allowedByGeneral
    if (general == null) return allowedBySpecific
    if (specific.priority != general.priority) {
        return if (specific.priority > general.priority) allowedBySpecific else allowedByGeneral
    }
    if (specific.order != general.order) {
        return if (specific.order > general.order) allowedBySpecific else allowedByGeneral
    }
    return allowedBySpecific
}

internal class SpecificDamage(val decision: FlagDecision<*>, val allowed: Boolean)

/**
 * The player answerable for [entity], or `null` when nobody is.
 *
 * A region flag is written about people, so damage a player set in motion has to resolve back
 * to that player however it was delivered. TNT, a lingering potion cloud and a pet are not
 * projectiles, so matching on [Projectile] alone lets someone kill in a region that denies PvP
 * by priming a block of TNT instead of swinging.
 */
internal fun responsiblePlayer(entity: Entity?): Player? = when (entity) {
    is Player -> entity
    is Projectile -> entity.shooter as? Player
    is TNTPrimed -> entity.source as? Player
    is AreaEffectCloud -> entity.source as? Player
    is EvokerFangs -> entity.owner as? Player
    is Tameable -> entity.owner as? Player
    else -> null
}

/**
 * The player answerable for this damage. [DamageSource.getCausingEntity] already unwraps most
 * indirect damage, and [responsiblePlayer] covers what it leaves behind.
 */
internal fun EntityDamageEvent.responsibleAttacker(): Player? =
    responsiblePlayer(damageSource.causingEntity)
        ?: responsiblePlayer((this as? EntityDamageByEntityEvent)?.damager)

/**
 * Whether [entity] is something a player built rather than something that lives in the world.
 *
 * Vanilla only records an owner for TNT a player lit by hand, so a cannon fired by a lever or a
 * dispenser arrives with nobody attached. Handing that to the mob damage flag would mean a truce
 * zone carrying only PvP does not cover the most common way to kill in one.
 */
private fun playerBuilt(entity: Entity?): Boolean = when (entity) {
    is TNTPrimed, is ExplosiveMinecart, is Firework -> true
    // A cloud is machinery only while a player is named on it. The Ender Dragon's breath is a
    // cloud too, and handing that to the PvP flag would mean an arena denying mob damage does not
    // cover the dragon's own attack. An owner that no longer resolves, because the mob died or
    // its chunk went, reads as no owner at all, so the absence cannot be taken for a player.
    is AreaEffectCloud -> entity.source is Player
    else -> false
}

/**
 * Whether the PvP flag owns this damage rather than the mob damage flag. Damage from a named
 * player, and damage from the machinery players build, are both PvP's business.
 */
internal fun EntityDamageEvent.attributedToPlayers(): Boolean =
    responsibleAttacker() != null || playerBuilt((this as? EntityDamageByEntityEvent)?.damager)

/** The specific flag that owns this damage: PvP when a player is behind it, mob damage otherwise. */
internal fun specificDecision(
    index: RegionFlagIndex,
    event: EntityDamageEvent,
    victim: Player,
    position: Position,
): SpecificDamage? {
    (event as? EntityDamageByEntityEvent)?.damager ?: return null
    if (event.attributedToPlayers()) {
        val decision = index.resolveDecision(PvpModifierEntry::class, position, victim) ?: return null
        return SpecificDamage(decision, decision.flag.allowed.get(victim))
    }
    val decision = index.resolveDecision(MobDamageModifierEntry::class, position, victim) ?: return null
    return SpecificDamage(decision, decision.flag.allowed.get(victim))
}
