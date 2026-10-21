package com.typewritermc.authoring

import com.typewritermc.types.NativeBinding
import skirout.editor.v1.catalog.PreparationOperation
import skirout.editor.v1.catalog.PrepareValueResult
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.ValuePreparationRequest
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
    suspend fun prepare(request: ValuePreparationRequest): PreparedValue = step(PreparationOperation.StartWrapper(request)).materialize()

    suspend fun step(operation: PreparationOperation): PrepareValueResult
}

suspend fun ValuePreparationRequest.prepareWith(runtime: InitializationRuntime): PreparedValue = runtime.prepare(this)
