package com.typewritermc.services.libs.registrar

sealed interface RegistrationState {
    data object Initializing : RegistrationState
    data class Pending(val token: String) : RegistrationState
    data class Bound(val organizationId: String, val organizationName: String) : RegistrationState
    data class Failed(val message: String) : RegistrationState
}
