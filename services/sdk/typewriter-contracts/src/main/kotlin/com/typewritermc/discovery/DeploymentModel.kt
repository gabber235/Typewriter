package com.typewritermc.discovery

import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ContributionKey

@Serializable
data class DeploymentFacts(
    val values: Map<String, String> = emptyMap(),
)

data class DiscoveryDiagnostic(
    val code: String,
    val message: String,
    val contribution: ContributionKey? = null,
)
