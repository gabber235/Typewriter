package com.typewritermc.protocol.transport.generated

/**
 * The reply inbox prefix of a service connection, `_INBOX.{service}`. Its reply inboxes are single tokens below
 * it, and the backend grants the connection exactly those.
 */
fun serviceReplyInboxPrefix(service: String): String = "_INBOX.${service}"
