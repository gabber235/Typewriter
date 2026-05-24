package com.typewritermc.roadnetwork.pathfinding.pathetic.properties

/**
 * Describes the physical and behavioral properties of a single node in the pathfinding grid.
 * A node is described by a set of these properties rather than a single type.
 *
 * An empty set implicitly represents an AIR block.
 */
enum class PathNodeProperty {
    /** The block itself is physically solid. */
    SOLID,

    /** The block is a fluid. */
    LIQUID,

    /** The node is positioned above a surface that can be walked on. */
    WALKABLE_SURFACE,

    /** The node contains a climbable block. */
    CLIMBABLE,

    /** The node contains a fence, wall, or similar 1.5-block-high obstacle. */
    FENCE,

    /** The node contains a door. */
    DOOR,

    /** The node contains a trapdoor. */
    TRAPDOOR,

    /** The node contains a fence gate. */
    GATE,

    /** The node contains a pressure plate. */
    PRESSURE_PLATE,

    /** The node contains a block that the entity may be able to interact with to pass through. */
    OPENABLE,

    /** The node contains an openable block that is currently open. */
    OPEN,

    /** The node contains a block that deals generic contact damage. */
    DAMAGING,

    /** The node contains a block that deals fire damage. */
    FIRE_DAMAGE,

    /** The node is within a liquid block, posing a risk of drowning. */
    DROWNING_RISK,

    /** The node contains a thin surface-level feature (carpet, pressure plate, thin snow layer) that doesn't obstruct movement. */
    SURFACE_FEATURE
}