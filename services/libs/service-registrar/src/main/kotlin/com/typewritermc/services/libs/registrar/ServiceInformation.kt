package com.typewritermc.services.libs.registrar

data class ServicesInfo(
    val realm: ServiceInformation.RealmInformation? = null,
    val engine: ServiceInformation.EngineInformation? = null,
) {
    init {
        require(realm != null || engine != null) { "at least one service must be registered" }
    }
}

sealed interface ServiceInformation {
    val version: String

    data class RealmInformation(override val version: String) : ServiceInformation
    data class EngineInformation(override val version: String, val platform: String) : ServiceInformation
}