package com.typewritermc.region.data

/**
 * How a distance to the region boundary is measured.
 *
 * [FULL] measures against the whole boundary, floor and ceiling included. [HORIZONTAL]
 * measures in the horizontal XZ plane only, against the region's vertical silhouette, so
 * floor and ceiling faces do not contribute. Use it when a region face lies on the ground
 * and the distance should reflect the walls instead of the floor underfoot.
 */
enum class DistanceMode {
    FULL,
    HORIZONTAL,
}
