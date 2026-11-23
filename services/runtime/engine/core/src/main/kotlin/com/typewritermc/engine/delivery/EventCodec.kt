package com.typewritermc.engine.delivery

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.actualType
import com.typewritermc.types.canonicalText
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.util.logging.Level
import java.util.logging.Logger
import kotlin.reflect.KClass

/** Turns events and reason details into the catalog values they cross engines as, and back. */
interface EventCodec {
    /** [value] as its catalog type encodes it, or null when its class has no catalog type here. */
    fun encode(value: Any): DataValue?

    /** What [value] decodes to, or why this engine cannot: it lacks the value's exact type, or the value does not fit it. */
    fun decode(value: DataValue): Decoded
}

/** The outcome of decoding a value that crossed engines. */
sealed interface Decoded {
    data class Value(
        val value: Any,
    ) : Decoded

    /** This engine has no type [type], in the exact revision the value names, or the value does not fit it. */
    data class Unknown(
        val type: String,
    ) : Decoded
}

/**
 * Encodes through the native bindings of the engine's catalog: a value's class finds its catalog type through the
 * binding generated for it, and a value's named type finds the binding that decodes it.
 */
class CatalogEventCodec(
    private val checked: CheckedCatalog,
    private val bindings: NativeBindingRegistry,
    natives: List<OwnedNativeBinding>,
) : EventCodec {
    private val types: Map<KClass<*>, TypeDefinitionId> =
        natives.mapNotNull { owned -> owned.factory.nativeClass?.let { it to owned.factory.definition } }.toMap()

    override fun encode(value: Any): DataValue? {
        val type = types[value::class] ?: return null
        val ready = (checked.resolve(type.use()) as? Resolution.Ready)?.value ?: return null
        @Suppress("UNCHECKED_CAST")
        return (bindings.bind(ready) as NativeBinding<Any>).encode(value)
    }

    override fun decode(value: DataValue): Decoded {
        val named = value as? DataValue.NamedWrapper ?: return Decoded.Unknown("an unnamed value")
        val type = named.actualType.use
        val ready = (checked.resolve(type) as? Resolution.Ready)?.value ?: return Decoded.Unknown(type.canonicalText)
        val complete = (ready.complete(value) as? CompletenessResult.Complete)?.value ?: return Decoded.Unknown(type.canonicalText)
        return try {
            Decoded.Value(checkNotNull(bindings.bind(ready).decode(complete)))
        } catch (
            @Suppress("TooGenericExceptionCaught") failure: Exception,
        ) {
            log.log(Level.FINE, "This engine cannot decode a value of ${type.canonicalText}.", failure)
            Decoded.Unknown(type.canonicalText)
        }
    }

    private companion object {
        val log: Logger = Logger.getLogger(CatalogEventCodec::class.java.name)
    }
}
