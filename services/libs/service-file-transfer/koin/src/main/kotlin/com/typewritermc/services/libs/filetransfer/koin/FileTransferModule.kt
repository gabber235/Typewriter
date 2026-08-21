package com.typewritermc.services.libs.filetransfer.koin

import com.typewritermc.services.libs.filetransfer.FileTransferCoordinator
import org.koin.dsl.module

/** Provides one [FileTransferCoordinator] with the validated chunk size used by an application scope. */
fun fileTransferModule(chunkSize: Int = FileTransferCoordinator.DEFAULT_CHUNK_SIZE) =
    module {
        single { FileTransferCoordinator(chunkSize) }
    }
