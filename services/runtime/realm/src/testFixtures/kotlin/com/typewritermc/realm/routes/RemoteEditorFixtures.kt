package com.typewritermc.realm.routes

import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.RealmWire
import com.typewritermc.realm.testing.RemoteSetupEditor
import com.typewritermc.services.libs.communicator.contract.UnaryContract

/**
 * Runs [test] with a [RemoteSetupEditor] that edits this Realm over its authoring routes on the wire, planning with the
 * catalog of [artifacts]. [beforeFirstCommit] runs once, right before the editor's first commit reaches the Realm, so a
 * test can save a change meanwhile.
 */
internal suspend fun RealmFixture.withRemoteEditor(
    artifacts: List<GeneratedProviderArtifact>,
    beforeFirstCommit: suspend () -> Unit = {},
    test: suspend (RemoteSetupEditor) -> Unit,
) = authoringRoutes().use { routes ->
    val commit = routes.requestAddress(RealmRouteScope::authoringEditCommit)
    var committed = false
    val wire =
        object : RealmWire {
            override suspend fun <Request : Any, Response : Any> call(
                contract: RealmRouteScope.() -> UnaryContract<RealmRouteScope, Request, Response>,
                request: Request,
            ): Response {
                if (!committed && routes.requestAddress(contract) == commit) {
                    committed = true
                    beforeFirstCommit()
                }
                return routes.call(contract, request)
            }
        }
    RemoteSetupEditor(wire, artifacts).use { test(it) }
}

/** Where [contract]'s requests to this fixture's Realm go. */
private fun RouteFixture.requestAddress(contract: RealmRouteScope.() -> UnaryContract<RealmRouteScope, *, *>) =
    address
        .contract()
        .requestAddress
        .render(address)
