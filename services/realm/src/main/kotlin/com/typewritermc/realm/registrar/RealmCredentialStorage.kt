package com.typewritermc.realm.registrar

import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.CredentialStorage
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.cbor.Cbor
import kotlinx.serialization.decodeFromByteArray
import kotlinx.serialization.encodeToByteArray
import java.io.File

@OptIn(ExperimentalSerializationApi::class)
class RealmCredentialStorage(
    private val cbor: Cbor,
    private val file: File
) : CredentialStorage {
    override fun credential(): Credential? {
        if (!file.exists()) return null

        val bytes = file.readBytes()
        return cbor.decodeFromByteArray<Credential>(bytes)
    }

    override fun storeCredential(credential: Credential) {
        val bytes = cbor.encodeToByteArray(credential)
        file.writeBytes(bytes)
    }
}