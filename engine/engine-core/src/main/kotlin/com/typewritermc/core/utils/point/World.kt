package com.typewritermc.core.utils.point

import kotlinx.serialization.Serializable

@Serializable
data class World(
    val identifier: String,
) {
    companion object {
        val Empty = World("")
    }
}