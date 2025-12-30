package com.typewritermc.realm

import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger

class Realm {
    private val logger: KLogger = logger {}

    fun initialize() {
        logger.info { "Initializing Realm" }
    }

    fun shutdown() {
        logger.info { "Shutting down Realm" }
    }
}