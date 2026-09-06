package com.typewritermc.library

/**
 * Exposes the canonical structural record key model to library callers.
 *
 * This alias preserves the same type identity as the types package; it introduces no separate serialization
 * format.
 */
typealias RecordIdKey = com.typewritermc.types.RecordIdKey

/**
 * Exposes the canonical compound record value model without duplicating it in the library package.
 */
typealias RecordIdValue = com.typewritermc.types.RecordIdValue
