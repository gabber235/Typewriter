package com.typewritermc.core.exceptions

import kotlin.reflect.KClass

/**
 * Exception thrown when data for a specific context cannot be found.
 *
 * This exception is typically thrown when attempting to retrieve data for a context
 * but the data is not available or cannot be found for the given class and context.
 */
class ContextDataNotFoundException(
    val contextClass: KClass<*>,
    val contextData: Any?,
    val entryId: String? = null
) : RuntimeException(buildMessage(contextClass, contextData, entryId)) {

    companion object {
        private fun buildMessage(contextClass: KClass<*>, contextData: Any?, entryId: String?): String {
            return if (entryId != null) {
                "Could not find data for $contextClass, data: $contextData for entry $entryId"
            } else {
                "Could not find data for $contextClass, data: $contextData"
            }
        }
    }
}