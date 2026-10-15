package com.typewritermc.authoring

import com.typewritermc.types.NativeBinding
import com.typewritermc.types.TypeUse

data class AppliedNativeArguments(
    val portable: List<TypeUse>,
    val bindings: List<NativeBinding<*>>,
    val resolver: com.typewritermc.types.NativeBindingResolver,
)

fun AppliedNativeArguments.requireOpaqueCompatibility(allowed: Set<Int>) {
    bindings.forEachIndexed { index, binding ->
        if (binding.opaque && index !in allowed) {
            throw com.typewritermc.types.NativeBindingException(
                "opaque_native_argument_violates_bound",
                "Portable argument $index cannot satisfy the compiled Kotlin bound.",
            )
        }
    }
}

interface InitializationRuntime {
    suspend fun prepare(request: InitializationRequest): PreparedValue
}

suspend fun InitializationRequest.prepareWith(runtime: InitializationRuntime): PreparedValue = runtime.prepare(this)
