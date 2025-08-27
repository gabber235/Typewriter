package com.typewritermc.example.entries.static

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.AssetManager
import com.typewritermc.engine.paper.entry.entries.ArtifactEntry
import com.typewritermc.engine.paper.entry.entries.hasData
import com.typewritermc.engine.paper.entry.entries.stringData
import com.typewritermc.engine.paper.entry.entries.binaryData
import org.koin.java.KoinJavaComponent

//<code-block:artifact_entry>
@Entry("example_artifact", "An example artifact entry.", Colors.BLUE, "material-symbols:home-storage-rounded")
class ExampleArtifactEntry(
    override val id: String = "",
    override val name: String = "",
    override val artifactId: String = "",
) : ArtifactEntry
//</code-block:artifact_entry>

//<code-block:artifact_access>
suspend fun accessArtifactData(ref: Ref<out ArtifactEntry>) {
    val assetManager = KoinJavaComponent.get<AssetManager>(AssetManager::class.java)
    val entry = ref.get() ?: return
    val stringContent: String? = assetManager.fetchStringAsset(entry)
    // Do something with the string content
}
//</code-block:artifact_access>

//<code-block:artifact_binary_access>
suspend fun accessBinaryArtifactData(ref: Ref<out ArtifactEntry>) {
    val assetManager = KoinJavaComponent.get<AssetManager>(AssetManager::class.java)
    val entry = ref.get() ?: return
    val binaryContent: ByteArray? = assetManager.fetchBinaryAsset(entry)
    // Do something with the binary content
}
//</code-block:artifact_binary_access>

//<code-block:artifact_helper_methods>
suspend fun accessArtifactDataUsingHelpers(ref: Ref<out ArtifactEntry>) {
    val entry = ref.get() ?: return
    
    // Check if artifact has data
    if (entry.hasData()) {
        // Access string data using helper method
        val stringContent: String? = entry.stringData()
        
        // Access binary data using helper method
        val binaryContent: ByteArray? = entry.binaryData()
        
        // Store string data
        entry.stringData("Updated artifact content")
        
        // Store binary data
        entry.binaryData(byteArrayOf(1, 2, 3, 4, 5))
    }
}
//</code-block:artifact_helper_methods>