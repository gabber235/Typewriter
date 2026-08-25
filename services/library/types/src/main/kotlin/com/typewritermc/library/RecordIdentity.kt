package com.typewritermc.library

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
sealed interface RecordIdKey {
    @Serializable
    @SerialName("number")
    data class Number(
        val value: Long,
    ) : RecordIdKey

    @Serializable
    @SerialName("string")
    data class String(
        val value: kotlin.String,
    ) : RecordIdKey

    @Serializable
    @SerialName("uuid")
    data class Uuid(
        val value: kotlin.String,
    ) : RecordIdKey {
        init {
            require(UUID_PATTERN.matches(value)) { "Record id UUID keys must use canonical UUID syntax." }
        }
    }

    @Serializable
    @SerialName("array")
    data class Array(
        val values: List<RecordIdValue>,
    ) : RecordIdKey

    @Serializable
    @SerialName("object")
    data class Object(
        val values: Map<kotlin.String, RecordIdValue>,
    ) : RecordIdKey
}

@Serializable
sealed interface RecordIdValue {
    @Serializable
    @SerialName("null")
    data object Null : RecordIdValue

    @Serializable
    @SerialName("boolean")
    data class Boolean(
        val value: kotlin.Boolean,
    ) : RecordIdValue

    @Serializable
    @SerialName("number")
    data class Number(
        val value: Long,
    ) : RecordIdValue

    @Serializable
    @SerialName("float")
    data class Float(
        val value: Double,
    ) : RecordIdValue

    @Serializable
    @SerialName("string")
    data class String(
        val value: kotlin.String,
    ) : RecordIdValue

    @Serializable
    @SerialName("array")
    data class Array(
        val values: List<RecordIdValue>,
    ) : RecordIdValue

    @Serializable
    @SerialName("object")
    data class Object(
        val values: Map<kotlin.String, RecordIdValue>,
    ) : RecordIdValue
}

private val UUID_PATTERN =
    Regex("[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")
