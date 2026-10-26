package com.typewritermc.protocol.transport.generated

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

private val realm = RealmRouteScope(organizationId = "writers", realmId = "quests")
private val service = ServiceRouteScope(serviceId = "billing")

private const val PANEL_INBOX = "_INBOX.alice.session-1.reply"
private const val SERVICE_INBOX = "_INBOX.billing.reply"
private const val FOREIGN_SUBJECT = "service.to.quests.organization.writers.realm.rollout.command"

/** Which of [replies] the generated rule answers for a request addressed to [address]. */
private fun <Address : Any> ReplyAddressRule<Address>.answered(
    address: Address,
    vararg replies: String,
): List<String> = replies.filter { admits(address, MessageAddress.of(it)) }

val GeneratedReplyAddressesTest by testSuite {
    test("a route that panels and services call answers both inboxes and nothing else") {
        realm.sharedBlobStore.replyAddresses.answered(realm, PANEL_INBOX, SERVICE_INBOX, FOREIGN_SUBJECT) shouldBe
            listOf(PANEL_INBOX, SERVICE_INBOX)
    }

    test("a route only services call refuses a panel inbox") {
        realm.rolloutProbe.replyAddresses.answered(realm, PANEL_INBOX, SERVICE_INBOX) shouldBe listOf(SERVICE_INBOX)
    }

    test("a route only panels call refuses a service inbox") {
        realm.editorCatalogWatch.replyAddresses.answered(realm, PANEL_INBOX, SERVICE_INBOX) shouldBe listOf(PANEL_INBOX)
    }

    test("a service scoped route answers only the inbox of the service it names") {
        service.registrationLeaseEnsure.replyAddresses.answered(service, SERVICE_INBOX, "_INBOX.payroll.reply") shouldBe
            listOf(SERVICE_INBOX)
    }
}
