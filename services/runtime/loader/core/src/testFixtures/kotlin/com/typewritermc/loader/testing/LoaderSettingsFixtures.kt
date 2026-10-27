package com.typewritermc.loader.testing

import java.nio.file.Files
import java.nio.file.Path

fun shippedProfiles(): List<Path> =
    Files.list(Path.of("..", "..", "config")).use { files ->
        files.filter { it.fileName.toString().endsWith(".properties") }.sorted().toList()
    }
