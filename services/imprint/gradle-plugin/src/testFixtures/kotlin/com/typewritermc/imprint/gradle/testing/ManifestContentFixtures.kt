package com.typewritermc.imprint.gradle.testing

import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.GeneratedContribution
import com.typewritermc.imprint.ProducerId

/** A main source part contribution named [name] from the realm artifact, whose payload is the name's bytes. */
fun contribution(name: String): GeneratedContribution =
    GeneratedContribution(
        source = ContributionSourceId("artifact:typewritermc:realm"),
        sourcePart = "main",
        producer = ProducerId("types"),
        name = ContributionName(name),
        payload = name.encodeToByteArray(),
    )
