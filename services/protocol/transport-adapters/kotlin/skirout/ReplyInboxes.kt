package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.address.MessageAddress

/**
 * The reply inbox prefix of a service connection, `_INBOX.{service}`. Its reply inboxes are single tokens below
 * it, and the backend grants the connection exactly those.
 */
fun serviceReplyInboxPrefix(service: String): String = "_INBOX.${service}"

/**
 * Whether [reply] is a panel reply inbox, `_INBOX.{user}.{session}.{token}`, of [user] when given. A server answers only
 * the reply inboxes of its route's callers, so a request cannot aim the answer at a subject its sender may not publish.
 */
fun isPanelReplyInbox(reply: MessageAddress, user: String? = null): Boolean {
    val tokens = reply.value.split('.')
    return tokens.size == 4 &&
        tokens[0] == "_INBOX" &&
        (user == null || tokens[1] == user)
}

/**
 * Whether [reply] is a service reply inbox, `_INBOX.{service}.{token}`, of [service] when given. A server answers only
 * the reply inboxes of its route's callers, so a request cannot aim the answer at a subject its sender may not publish.
 */
fun isServiceReplyInbox(reply: MessageAddress, service: String? = null): Boolean {
    val tokens = reply.value.split('.')
    return tokens.size == 3 &&
        tokens[0] == "_INBOX" &&
        (service == null || tokens[1] == service)
}
