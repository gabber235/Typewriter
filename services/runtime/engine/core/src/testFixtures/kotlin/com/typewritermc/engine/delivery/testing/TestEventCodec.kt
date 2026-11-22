package com.typewritermc.engine.delivery.testing

import com.typewritermc.engine.delivery.Decoded
import com.typewritermc.engine.delivery.EventCodec
import skirout.editor.v1.type_catalog.DataValue
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

/**
 * A codec for engines of one test process, standing in for the catalog: a value crosses as its class name and a key
 * into a table every engine of the process shares. An engine decodes only the classes it [knows], as an engine
 * without an extension cannot decode its types; every class when [knows] is null.
 */
class TestEventCodec(
    private val knows: Set<KClass<*>>? = null,
) : EventCodec {
    override fun encode(value: Any): DataValue = DataValue.StringValueWrapper("${value::class.qualifiedName}#${keep(value)}")

    override fun decode(value: DataValue): Decoded {
        val text = (value as? DataValue.StringValueWrapper)?.value ?: return Decoded.Unknown("a value of another codec")
        val type = text.substringBefore('#')
        val kept = values[text.substringAfter('#')] ?: return Decoded.Unknown(type)
        if (knows != null && kept::class !in knows) return Decoded.Unknown(type)
        return Decoded.Value(kept)
    }

    private companion object {
        val values = ConcurrentHashMap<String, Any>()

        fun keep(value: Any): String = UUID.randomUUID().toString().also { values[it] = value }
    }
}
