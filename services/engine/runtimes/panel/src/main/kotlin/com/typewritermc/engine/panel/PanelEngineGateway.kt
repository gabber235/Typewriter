package com.typewritermc.engine.panel

interface PanelEngineGateway {
    fun registerProjection(
        id: String,
        projection: suspend () -> ByteArray,
    ): AutoCloseable
}
