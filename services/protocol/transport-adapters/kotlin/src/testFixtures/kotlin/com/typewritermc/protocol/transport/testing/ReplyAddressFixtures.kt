package com.typewritermc.protocol.transport.testing

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule

/** The replies among [replies] that the generated rule admits for a request addressed to [address], in their given order. */
fun <Address : Any> ReplyAddressRule<Address>.answered(
    address: Address,
    vararg replies: String,
): List<String> = replies.filter { admits(address, MessageAddress.of(it)) }
