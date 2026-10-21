package com.typewritermc.authoring

import com.typewritermc.types.NativeBinding
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.type_catalog.TypeUse

data class AppliedNativeArguments(
    val portable: List<TypeUse>,
    val bindings: List<NativeBinding<*>>,
    val resolver: com.typewritermc.types.NativeBindingResolver,
)

@GeneratedSdkApi
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
    suspend fun prepare(request: InitializationRequest): PreparedValue = step(PreparationOperation.Start(request)).materialize()

    suspend fun step(operation: PreparationOperation): PreparationStep
}

suspend fun InitializationRequest.prepareWith(runtime: InitializationRuntime): PreparedValue = runtime.prepare(this)
