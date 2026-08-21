package com.typewritermc.engine.panel

/**
 * Lets panel targeted extension activators expose serialized read projections.
 *
 * Registration identifiers must be unique within the active deployment. Closing the returned handle removes the
 * projection, so activators should immediately attach it to their runtime scope.
 */
interface PanelEngineGateway {
    fun registerProjection(
        id: String,
        projection: suspend () -> ByteArray,
    ): AutoCloseable
}
