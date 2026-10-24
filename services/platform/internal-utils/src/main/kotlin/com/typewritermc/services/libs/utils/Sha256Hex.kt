package com.typewritermc.services.libs.utils

import java.security.MessageDigest

/** Returns the SHA 256 digest of these bytes as 64 lowercase hexadecimal characters. */
fun ByteArray.sha256Hex(): String = MessageDigest.getInstance("SHA-256").digest(this).toHexString()

/** Returns the SHA 256 digest of this text's UTF 8 bytes as 64 lowercase hexadecimal characters. */
fun String.sha256Hex(): String = encodeToByteArray().sha256Hex()
