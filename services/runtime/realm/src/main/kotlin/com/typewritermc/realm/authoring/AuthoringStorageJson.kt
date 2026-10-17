package com.typewritermc.realm.authoring

import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import kotlinx.serialization.json.Json

internal val authoringStorageJson =
    Json {
        allowStructuredMapKeys = true
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "@type"
    }

internal val authoredDatabaseValues = StructuredDatabaseCodec(authoringStorageJson)
