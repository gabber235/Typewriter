package com.typewritermc.codegen

import com.google.devtools.ksp.symbol.KSAnnotated

data class GeneratedProviderContribution(
    val kind: String,
    val providerClass: String,
)

data class ProviderProcessingResult(
    val providers: List<GeneratedProviderContribution> = emptyList(),
    val deferred: List<KSAnnotated> = emptyList(),
)
