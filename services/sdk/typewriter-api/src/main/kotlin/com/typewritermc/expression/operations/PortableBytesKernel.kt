package com.typewritermc.expression.operations

import okio.ByteString
import okio.ByteString.Companion.toByteString

/** Realm's kernel of the bytes operations: bytes are unsigned integers from 0 to 255. */
internal object PortableBytesKernel : BytesKernel {
    override fun fromList(values: List<Int>): ByteString =
        ByteArray(values.size) { index ->
            val value = values[index]
            if (value !in 0..255) throw OperationFailure(KernelFailure.InvalidByte, "The byte value $value is outside 0 to 255.")
            value.toByte()
        }.toByteString()

    override fun toList(value: ByteString): List<Int> = List(value.size) { index -> value[index].toInt() and 0xFF }
}
