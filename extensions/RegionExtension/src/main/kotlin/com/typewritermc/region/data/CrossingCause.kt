package com.typewritermc.region.data

/**
 * Why a player became (or stopped being) a member of a region.
 *
 * - [PLAYER_MOVED]: the player walked or rode across the boundary (PlayerMoveEvent or
 *   VehicleMoveEvent).
 * - [TELEPORTED]: the player teleported across the boundary (PlayerTeleportEvent).
 * - [ENGULFED]: the region's geometry advanced into a stationary player (no Bukkit event).
 * - [DISCONNECTED]: the player logged out while inside. Only ever a leave, and their session
 *   is already being torn down, so actions that need the player online will not land.
 */
enum class CrossingCause {
    PLAYER_MOVED,
    TELEPORTED,
    ENGULFED,
    DISCONNECTED,
    ;

    /**
     * Whether the engine can undo this crossing by cancelling a Bukkit event. A crossing that
     * cannot be undone always happened, so a handler must react to it even when it refused the
     * player's last attempt to walk in.
     */
    val revocable: Boolean get() = this == PLAYER_MOVED || this == TELEPORTED
}
