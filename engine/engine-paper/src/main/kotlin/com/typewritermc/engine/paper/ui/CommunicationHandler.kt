package com.typewritermc.engine.paper.ui

import com.corundumstudio.socketio.Configuration
import com.corundumstudio.socketio.HandshakeData
import com.corundumstudio.socketio.SocketIOClient
import com.corundumstudio.socketio.SocketIOServer
import com.google.gson.JsonArray
import lirand.api.extensions.events.listen
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.entry.StagingManager
import com.typewritermc.engine.paper.events.StagingChangeEvent
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.config
import com.typewritermc.engine.paper.utils.logErrorIfNull
import com.typewritermc.engine.paper.utils.optionalConfig
import com.typewritermc.loader.ExtensionLoader
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.time.Instant
import java.util.*
import kotlin.collections.set


class CommunicationHandler : KoinComponent {
    private val clientSynchronizer: ClientSynchronizer by inject()
    private val writers: Writers by inject()
    private val stagingManager: StagingManager by inject()
    private val panelHost: PanelHost by inject()
    private val extensionLoader: ExtensionLoader by inject()
    private val extensionJson by extensionLoader::extensionJson

    private val hostName: String by config(
        "hostname",
        "127.0.0.1",
        comment = "The hostname of the server. CHANGE THIS to your servers ip."
    )
    private val panelPort: Int by config(
        "panel.port",
        8080,
        comment = "The port of the web panel. Make sure this port is open."
    )
    private val panelAppendPort: Boolean? by optionalConfig("panel.append_port")

    private val enabled: Boolean by config(
        "enabled",
        false,
        comment = "Whether the web panel and web sockets are enabled."
    )
    private val webSocketPort: Int by config(
        "websocket.port",
        9092,
        comment = "The port of the websocket server. Make sure this port is open."
    )
    private val auth: String by config(
        "websocket.auth", "session", comment = """
        |The authentication that is used. Leave unchanged if you don't know what you are doing.
        |Possible values: none (not recommended), session
    """.trimMargin()
    )
    private val websocketHostname: String? by optionalConfig("websocket.hostname")
    private val websocketAppendPort: Boolean? by optionalConfig("websocket.append_port")
    private val websocketSecure: Boolean? by optionalConfig("websocket.secure")


    val authenticationEnabled: Boolean
        get() = auth == "session"

    private val sessionTokens: MutableMap<UUID, SessionData> = mutableMapOf()

    var server: SocketIOServer? = null
        private set

    fun initialize() {
        if (!enabled) return
        logger.warning("Websocket server is enabled. This is not recommended for production servers.")
        panelHost.initialize()
        val config = Configuration().apply {
            hostname = "0.0.0.0"
            port = this@CommunicationHandler.webSocketPort
            setAuthorizationListener(this@CommunicationHandler::authenticate)
        }

        server = SocketIOServer(config)

        server?.addEventListener("fetch", String::class.java, clientSynchronizer::handleFetchRequest)
        server?.addEventListener("createPage", String::class.java, clientSynchronizer::handleCreatePage)
        server?.addEventListener("renamePage", String::class.java, clientSynchronizer::handleRenamePage)
        server?.addEventListener("changePageValue", String::class.java, clientSynchronizer::handleChangePageValue)
        server?.addEventListener("deletePage", String::class.java, clientSynchronizer::handleDeletePage)
        server?.addEventListener("moveEntry", String::class.java, clientSynchronizer::handleMoveEntry)
        server?.addEventListener("createEntry", String::class.java, clientSynchronizer::handleCreateEntry)
        server?.addEventListener("updateEntry", String::class.java, clientSynchronizer::handleEntryFieldUpdate)
        server?.addEventListener(
            "updateCompleteEntry",
            String::class.java,
            clientSynchronizer::handleEntryUpdate
        )
        server?.addEventListener("reorderEntry", String::class.java, clientSynchronizer::handleReorderEntry)
        server?.addEventListener("deleteEntry", String::class.java, clientSynchronizer::handleDeleteEntry)

        server?.addEventListener("publish", String::class.java, clientSynchronizer::handlePublish)

        server?.addEventListener("updateWriter", String::class.java, clientSynchronizer::handleUpdateWriter)
        server?.addEventListener("contentModeRequest", String::class.java, clientSynchronizer::handleContentModeRequest)

        server?.addConnectListener { socket ->
            logger.info("Client connected: ${socket.remoteAddress}")
            socket.sendEvent("stagingState", stagingManager.stagingState.name.lowercase())

            val token = getSessionToken(socket.handshakeData)
            if (token != null) {
                sessionTokens.computeIfPresent(token) { _, session ->
                    session.copy(lastConnectionId = socket.sessionId)
                }
            }

            val iconUrl = getIconUrl(token)

            writers.addWriter(socket.sessionId.toString(), iconUrl)
            server.broadcastWriters(writers)
        }

        server?.addDisconnectListener {
            logger.info("Client disconnected: ${it.remoteAddress}")
            server?.broadcastOperations?.sendEvent("disconnectWriter", it, it.sessionId.toString())

            writers.removeWriter(it.sessionId.toString())
            server.broadcastWriters(writers)
        }

        server?.start()


        plugin.listen<StagingChangeEvent> { (newState) ->
            server?.broadcastOperations?.sendEvent("stagingState", newState.name.lowercase())
        }
    }

    fun load() {
        if (!enabled) return
        server?.broadcastOperations?.sendEvent("stagingState", stagingManager.stagingState.name.lowercase())

        val array = JsonArray()
        stagingManager.pages.forEach { (_, page) ->
            array.add(page)
        }
        server?.broadcastOperations?.sendEvent("updatePages", array.toString())
        server?.broadcastOperations?.sendEvent("updateExtensions", extensionJson.toString())
    }

    private fun authenticate(data: HandshakeData): Boolean {
        if (auth == "none") return true
        if (auth == "session") {
            val token = getSessionToken(data)
                .logErrorIfNull("${data.address} tried to connect to the socket without token!") ?: return false
            val session = sessionTokens[token] ?: return false
            return session.isValid
        }
        return false
    }

    private fun getSessionToken(data: HandshakeData): UUID? {
        if (auth == "none") return null
        if (auth == "session") {
            val token = data.getSingleUrlParam("token") ?: return null
            return UUID.fromString(token)
        }
        return null
    }

    private fun generateSessionToken(playerId: UUID?): UUID {
        // If there already is a token for this player, use that one.
        val existingToken = sessionTokens.filter { it.value.playerId == playerId }.keys.firstOrNull()
        if (existingToken != null) return existingToken

        // Otherwise, create a new token.
        val token = UUID.randomUUID()
        sessionTokens[token] = SessionData.create(playerId)
        return token
    }

    fun generateUrl(playerId: UUID?): String {
        var url: String = if (hostName.startsWith("http")) hostName
        else "http://${hostName}"

        if (panelAppendPort != false) url += ":${panelPort}"
        url += "/#/connect?host=${websocketHostname ?: hostName}"
        if (websocketAppendPort != false) url += "&port=${webSocketPort}"
        if (auth == "session") url += "&token=${generateSessionToken(playerId)}"
        if (websocketSecure == true) url += "&secure=true"

        return url
    }

    fun getPlayer(client: SocketIOClient): Player? {
        val token = getSessionToken(client.handshakeData) ?: return null
        val session = sessionTokens[token] ?: return null
        return session.playerId?.let { plugin.server.getPlayer(it) }
    }

    fun getIconUrl(sessionId: String): String? {
        val client = server?.getClient(UUID.fromString(sessionId)) ?: return null
        val token = getSessionToken(client.handshakeData) ?: return null
        return getIconUrl(token)
    }

    private fun getIconUrl(token: UUID?): String? {
        val session = sessionTokens[token] ?: return null
        return session.playerId?.let {
            "https://crafatar.com/avatars/$it?size=64&overlay"
        }
    }

    fun shutdown() {
        if (!enabled) return
        server?.stop()
        panelHost.dispose()
        writers.dispose()
    }
}

data class SessionData(
    val playerId: UUID?,
    val created: Instant,
    val lastConnectionId: UUID? = null,
) {
    companion object {
        fun create(playerId: UUID?) = SessionData(playerId, Instant.now())
    }

    /**
     * Check if the session is still valid.
     *
     * A session is valid if the player is still online.
     *
     * @return true if the session is still valid, false otherwise.
     */
    val isValid: Boolean
        get() = playerId?.let { server.getPlayer(it) != null } ?: true
}