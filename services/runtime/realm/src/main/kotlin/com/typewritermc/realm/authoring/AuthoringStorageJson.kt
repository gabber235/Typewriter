package com.typewritermc.realm.authoring

import kotlinx.serialization.json.Json

internal val authoringStorageJson =
    Json {
        allowStructuredMapKeys = true
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "@type"
    }
