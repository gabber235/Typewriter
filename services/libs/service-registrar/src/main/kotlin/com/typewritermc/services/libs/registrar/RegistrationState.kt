package com.typewritermc.services.libs.registrar

sealed interface RegistrationState {
    data object Initializing : RegistrationState

    data class Pending(val token: String) : RegistrationState {
        init {
            require(token.isNotBlank()) { "Token must not be blank" }
        }
    }

    data class Bound(val organizationId: String, val organizationName: String) : RegistrationState {
        init {
            require(organizationId.isNotBlank()) { "Organization ID must not be blank" }
        }
    }

    data class Failed(val message: String) : RegistrationState {
        init {
            require(message.isNotBlank()) { "Error message must not be blank" }
        }
    }
}
