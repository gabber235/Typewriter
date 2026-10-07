package com.typewritermc.visibility.effector

/**
 * A [VisibilityEffector] that needs to do work every server tick while it is active.
 *
 * The engine ticks these on the server thread, inside the same hop rulers use to read live state, so
 * implementations may read the Bukkit api directly and should keep the work short. Ticking starts
 * once [VisibilityEffector.initialize] completed and stops before [VisibilityEffector.dispose] runs,
 * but a tick already in flight can overlap disposal, so implementations must tolerate being ticked
 * while tearing down.
 */
interface TickableVisibilityEffector : VisibilityEffector {
    suspend fun tick()
}
