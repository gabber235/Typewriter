package com.typewritermc.services.libs.communicator.routing

class SubjectParams(private val map: Map<String, String>) {
    operator fun get(key: String): String? = map[key]

    fun require(key: String): String = map[key] ?: error("Parameter '$key' not found in subject params")
}
