package com.typewritermc.protocol.transport

import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf

/**
 * The identities of a realm route subject: the organization that owns the realm and the realm itself.
 *
 * Every generated realm contract is an extension on this scope, so one value addresses all routes of one realm.
 */
data class RealmRouteScope(
    val organizationId: String,
    val realmId: String,
)

/** Reads this subject as a typed address whose `{organization}` and `{realm}` tokens render a [RealmRouteScope]. */
fun String.realmTemplate(): AddressTemplate<RealmRouteScope> =
    addressTemplate(
        render = { addressValuesOf("organization" to it.organizationId, "realm" to it.realmId) },
        parse = { RealmRouteScope(it.require("organization"), it.require("realm")) },
    )

/**
 * The identity of a service route subject: the registered service the route belongs to.
 *
 * Every generated service registration contract is an extension on this scope.
 */
data class ServiceRouteScope(
    val serviceId: String,
)

/** Reads this subject as a typed address whose `{service}` token renders a [ServiceRouteScope]. */
fun String.serviceTemplate(): AddressTemplate<ServiceRouteScope> =
    addressTemplate(
        render = { addressValuesOf("service" to it.serviceId) },
        parse = { ServiceRouteScope(it.require("service")) },
    )
