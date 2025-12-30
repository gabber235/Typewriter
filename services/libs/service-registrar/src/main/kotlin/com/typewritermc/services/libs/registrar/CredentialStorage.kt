package com.typewritermc.services.libs.registrar

import kotlinx.serialization.Serializable

interface CredentialStorage {
    fun credential(): Credential?
    fun storeCredential(credential: Credential)
}

@Serializable
data class Credential(
    val id: String,
    val name: String,
    val token: String
) {
    init {
        require(id.isNotBlank()) {"id cannot be blank"}
        require(name.isNotBlank()) {"name cannot be blank"}
        require(token.isNotBlank()) {"token cannot be blank"}
    }

    override fun toString(): String {
        return "Credential(id='$id', name='$name', token='***')"
    }
}