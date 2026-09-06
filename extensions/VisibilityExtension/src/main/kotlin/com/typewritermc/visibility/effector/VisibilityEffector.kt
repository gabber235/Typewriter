package com.typewritermc.visibility.effector

/**
 * An active instance of a visibility effect applied to a specific viewer and target pair.
 *
 * Effectors are created when a rule wins the priority contest for a pair and disposed when the rule
 * is removed or a higher priority rule takes over. For a given pair the engine calls the lifecycle
 * sequentially: a new effector is only initialized after the previous one finished disposing.
 *
 * Both lifecycle methods are called from an async context. Implementations must switch to the main
 * thread themselves when they touch the Bukkit api, and must treat an offline player as a no op.
 */
interface VisibilityEffector {
    /**
     * Applies the visual modification for the pair.
     */
    suspend fun initialize()

    /**
     * Restores the default rendering for the pair.
     */
    suspend fun dispose()

    /**
     * Whether the client has to receive the pair again for this effector to apply or stop applying.
     *
     * A client keeps the profile it received when the target was added to it, so an effector that
     * rewrites that profile only reaches the client through a new add. That means a despawn and a
     * respawn, which is why the engine performs it once per lifecycle transition rather than once per
     * effector: a bundle of profile effects would otherwise flicker the target once per sub effect
     * and leave it partly disguised in between.
     *
     * Read after [initialize] and again after [dispose], so it has to stay true once the effector has
     * registered anything that needs it, disposal included.
     */
    val needsPairRerender: Boolean get() = false
}
