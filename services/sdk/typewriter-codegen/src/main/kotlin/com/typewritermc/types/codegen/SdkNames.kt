package com.typewritermc.types.codegen

import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.ParameterizedTypeName
import com.squareup.kotlinpoet.ParameterizedTypeName.Companion.parameterizedBy
import com.squareup.kotlinpoet.TypeName
import com.squareup.kotlinpoet.ksp.toClassName

/**
 * ClassNames of everything generated for one source declaration.
 *
 * Nested sources flatten to `OuterInner` in the source package. Declarations and references both read their names
 * here, so a reference can never disagree with the declaration it names.
 */
internal class SdkNames private constructor(
    val source: ClassName,
    private val base: ClassName,
) {
    /** The flattened generated base name, for example `OuterInner`. */
    val baseName: String = base.simpleName

    val file: String = "${base.simpleName}TypewriterSdk"
    val fields = base.suffixed("Fields")
    val expressions = base.suffixed("Expressions")
    val expressionsImpl = base.suffixed("ExpressionsImpl")
    val expressionsFactory = base.suffixed("ExpressionsFactory")
    val configuration = base.suffixed("Configuration")
    val configurationScope = base.suffixed("ConfigurationScope")
    val configurationScopeImpl = base.suffixed("ConfigurationScopeImpl")
    val operations = base.suffixed("Operations")
    val operationsScope = base.suffixed("OperationsScope")
    val operationsScopeImpl = base.suffixed("OperationsScopeImpl")
    val presentation = base.suffixed("Presentation")
    val presentationScope = base.suffixed("PresentationScope")
    val presentationScopeImpl = base.suffixed("PresentationScopeImpl")
    val check = base.suffixed("Check")
    val draft = base.suffixed("Draft")
    val exactDraft = base.suffixed("ExactDraft")
    val draftType = base.suffixed("DraftType")
    val exactDraftType = base.suffixed("ExactDraftType")
    val draftProjection = base.suffixed("DraftProjection")
    val definition = base.suffixed("Definition")
    val nativeBindingFactory = base.suffixed("NativeBindingFactory")
    val endpointBindings = base.suffixed("EndpointBindings")

    companion object {
        fun of(declaration: KSClassDeclaration): SdkNames {
            val source = declaration.toClassName()
            return SdkNames(source, ClassName(source.packageName, source.simpleNames.joinToString("")))
        }

        private fun ClassName.suffixed(suffix: String) = ClassName(packageName, simpleName + suffix)
    }
}

/** This class applied to [arguments], or the class itself when there are none. */
internal fun ClassName.parameterizedOrSelf(arguments: List<TypeName>): TypeName =
    if (arguments.isEmpty()) this else parameterizedBy(arguments)

/** The raw class of a scope type, for KClass tokens of parameterized scopes. */
internal val TypeName.rawClass: ClassName
    get() = ((this as? ParameterizedTypeName)?.rawType ?: this as ClassName).copy(nullable = false) as ClassName
