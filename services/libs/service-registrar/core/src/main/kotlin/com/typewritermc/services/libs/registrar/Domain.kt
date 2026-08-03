package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator

/** A role advertised by a service identity. */
sealed interface ServiceRole {
    val version: String

    data class Engine(
        override val version: String,
    ) : ServiceRole {
        init {
            requireTrimmedNonblank(version, "version")
        }
    }

    data class Realm(
        override val version: String,
    ) : ServiceRole {
        init {
            requireTrimmedNonblank(version, "version")
        }
    }

    data class Custom(
        val name: String,
        override val version: String,
    ) : ServiceRole {
        init {
            requireTrimmedNonblank(name, "name")
            require(CUSTOM_ROLE.matches(name)) { "name must be a backend identifier" }
            requireTrimmedNonblank(version, "version")
        }
    }
}

/** Durable public identity attributes. */
class ServiceIdentity(
    val serviceId: String,
    val displayName: String,
    val username: String,
    roles: List<ServiceRole>,
) {
    val roles: List<ServiceRole> = roles.toList()

    init {
        requireTrimmedNonblank(serviceId, "serviceId")
        requireTrimmedNonblank(displayName, "displayName")
        requireTrimmedNonblank(username, "username")
        validateRoles(this.roles)
    }

    override fun equals(other: Any?): Boolean =
        other is ServiceIdentity &&
            serviceId == other.serviceId &&
            displayName == other.displayName &&
            username == other.username &&
            roles == other.roles

    override fun hashCode(): Int {
        var result = serviceId.hashCode()
        result = 31 * result + displayName.hashCode()
        result = 31 * result + username.hashCode()
        return 31 * result + roles.hashCode()
    }

    override fun toString(): String = "ServiceIdentity(serviceId=$serviceId, displayName=$displayName, username=$username, roles=$roles)"
}

/** Organization associated with a service. */
data class OrganizationBinding(
    val organizationId: String,
    val organizationName: String?,
) {
    init {
        requireTrimmedNonblank(organizationId, "organizationId")
    }
}

/** Stable resources exposed while registration is ready. */
data class ReadySession(
    val identity: ServiceIdentity,
    val binding: OrganizationBinding,
    val communicator: Communicator,
)

/** A value whose disclosure must be explicit. */
sealed class RedactedSecret private constructor(
    private val value: String,
) {
    init {
        require(value.isNotBlank()) { "secret must not be blank" }
    }

    /** Deliberately reveals the secret value. */
    fun reveal(): String = value

    final override fun toString(): String = "[REDACTED]"

    class AppPassword(
        value: String,
    ) : RedactedSecret(value)

    class AccessToken(
        value: String,
    ) : RedactedSecret(value)

    class SentinelJwt(
        value: String,
    ) : RedactedSecret(value)

    class SentinelSeed(
        value: String,
    ) : RedactedSecret(value)
}

/** Durable identity material. */
class IdentityCredentials(
    val identity: ServiceIdentity,
    private val appPassword: RedactedSecret.AppPassword,
) {
    /** Deliberately reveals the identity app password. */
    fun revealAppPassword(): String = appPassword.reveal()

    override fun toString(): String = "IdentityCredentials(identity=$identity, appPassword=[REDACTED])"
}

/** Short-lived operator registration token. */
class RegistrationToken(
    private val value: String,
) {
    init {
        requireTrimmedNonblank(value, "registrationToken")
    }

    /** Deliberately reveals the registration token. */
    fun reveal(): String = value

    override fun equals(other: Any?): Boolean = other is RegistrationToken && value == other.value

    override fun hashCode(): Int = value.hashCode()

    override fun toString(): String = "[REDACTED]"
}

internal fun validateRoles(roles: List<ServiceRole>) {
    require(roles.isNotEmpty()) { "at least one role is required" }
    require(roles.all { it.version.isNotBlank() && it.version == it.version.trim() }) {
        "role versions must be trimmed and nonblank"
    }
    require(roles.count { it is ServiceRole.Engine } <= 1) { "at most one engine role is allowed" }
    require(roles.count { it is ServiceRole.Realm } <= 1) { "at most one realm role is allowed" }
    val customs = roles.filterIsInstance<ServiceRole.Custom>()
    require(customs.map { it.name }.distinct().size == customs.size) {
        "custom role names must be unique"
    }
    require(customs.all { CUSTOM_ROLE.matches(it.name) }) {
        "custom role names must be backend identifiers"
    }
}

private fun requireTrimmedNonblank(
    value: String,
    name: String,
) {
    require(value.isNotBlank() && value == value.trim()) { "$name must be trimmed and nonblank" }
}

private val CUSTOM_ROLE = Regex("^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$")
